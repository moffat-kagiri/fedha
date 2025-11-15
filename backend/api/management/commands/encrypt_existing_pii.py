from django.core.management.base import BaseCommand, CommandError
from django.db import transaction
from django.apps import apps
from api.utils.encryption import FieldEncryption
import logging

logger = logging.getLogger(__name__)

# Map models to (plaintext_field, encrypted_field) pairs for migration
MODEL_FIELD_MAP = {
    'api.Profile': [
        ('name', 'name_encrypted'),
        ('email', 'email_encrypted'),
    ],
    'api.Client': [
        ('name', 'name_encrypted'),
        ('email', 'email_encrypted'),
        ('phone', 'phone_encrypted'),
        ("address_line1", 'address_encrypted'),
    ],
    'api.EnhancedTransaction': [
        ('reference_number', 'reference_number_encrypted'),
        ('receipt_url', 'receipt_url_encrypted'),
    ],
    'api.Loan': [
        ('account_number', 'account_number_encrypted'),
        ('lender', 'lender_encrypted'),
    ],
    'api.AuditLog': [
        ('field_changes', 'field_changes_encrypted'),
    ],
}

class Command(BaseCommand):
    help = 'Encrypt existing plaintext PII fields into the new encrypted binary fields. Use --dry-run to only report changes.'

    def add_arguments(self, parser):
        parser.add_argument('--dry-run', action='store_true', help='Do not write changes, only report what would be done')
        parser.add_argument('--limit', type=int, default=10, help='Max number of records to process per model (for quick dry-run)')
        parser.add_argument('--batch-size', type=int, default=100, help='Number of records to process per transaction batch')

    def handle(self, *args, **options):
        dry_run = options['dry_run']
        limit = options['limit']
        batch_size = options['batch_size']

        self.stdout.write(self.style.MIGRATE_HEADING('Starting PII encryption utility'))
        if dry_run:
            self.stdout.write(self.style.WARNING('Running in dry-run mode; no database changes will be written'))

        for model_path, fields in MODEL_FIELD_MAP.items():
            app_label, model_name = model_path.split('.')
            Model = apps.get_model(app_label, model_name)
            qs = Model.objects.all()
            count = qs.count()
            self.stdout.write(self.style.NOTICE(f'Processing model {model_path}: {count} rows (limit {limit})'))

            processed = 0
            # Iterate safely, small batches
            for obj in qs.iterator():
                if processed >= limit:
                    break
                updates = {}
                for plain_field, enc_field in fields:
                    # Skip if encrypted field already populated
                    try:
                        enc_val = getattr(obj, enc_field, None)
                    except Exception:
                        enc_val = None
                    if enc_val:
                        continue
                    # get plaintext
                    try:
                        plain_val = getattr(obj, plain_field)
                    except Exception:
                        plain_val = None
                    # Special-case JSONField for AuditLog.field_changes
                    if plain_val is None or plain_val == '':
                        continue
                    # Convert JSON serializable objects to string before encrypt
                    if not isinstance(plain_val, str):
                        try:
                            import json as _json
                            plain_text = _json.dumps(plain_val)
                        except Exception:
                            plain_text = str(plain_val)
                    else:
                        plain_text = plain_val

                    # Derive profile id where possible; fallback to 'global'
                    profile_id = getattr(obj, 'profile_id', None) or getattr(obj, 'profile', None)
                    if hasattr(profile_id, 'id'):
                        profile_key_id = profile_id.id
                    elif isinstance(profile_id, str):
                        profile_key_id = profile_id
                    else:
                        # fallback
                        profile_key_id = 'global'

                    encrypted = FieldEncryption.encrypt(plain_text, profile_key_id, version=getattr(obj, 'encryption_version', 1))
                    if encrypted is None:
                        self.stdout.write(self.style.ERROR(f'Failed to encrypt {model_path}.{plain_field} for id={obj.pk}'))
                        continue
                    # store bytes since model field is BinaryField
                    updates[enc_field] = encrypted.encode('utf-8')

                if updates:
                    processed += 1
                    if dry_run:
                        self.stdout.write(self.style.SUCCESS(f'[DRY] Would encrypt {model_path} id={obj.pk} fields={list(updates.keys())}'))
                        continue

                    # perform DB write in small transaction
                    try:
                        with transaction.atomic():
                            for k, v in updates.items():
                                setattr(obj, k, v)
                            # set encryption_version if field exists
                            if hasattr(obj, 'encryption_version'):
                                setattr(obj, 'encryption_version', getattr(obj, 'encryption_version', 1))
                            obj.save()
                        self.stdout.write(self.style.SUCCESS(f'Encrypted {model_path} id={obj.pk} fields={list(updates.keys())}'))
                    except Exception as e:
                        logger.exception('Error encrypting fields')
                        self.stdout.write(self.style.ERROR(f'Error writing encrypted fields for {model_path} id={obj.pk}: {e}'))

            self.stdout.write(self.style.NOTICE(f'Completed model {model_path}; processed {processed} objects'))

        self.stdout.write(self.style.MIGRATE_LABEL('PII encryption utility finished'))
