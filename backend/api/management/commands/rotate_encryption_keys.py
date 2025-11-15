"""
Management command: rotate_encryption_keys

Rotate encryption keys for profiles or master key with support for:
- Scheduled rotation
- Emergency/compromise rotation
- Dry-run validation
- Rollback on failure
"""

from django.core.management.base import BaseCommand, CommandError
from django.db import transaction
from django.utils import timezone
from api.models import Profile, EncryptionKeyVersion, KeyRotationLog
from api.utils.key_rotation import KeyRotationManager
import logging

logger = logging.getLogger(__name__)


class Command(BaseCommand):
    help = 'Rotate encryption keys for profiles. Use --dry-run to validate before committing.'

    def add_arguments(self, parser):
        parser.add_argument(
            '--profile-id',
            type=str,
            help='Profile UUID to rotate key for. If not provided, rotates all active profiles.'
        )
        parser.add_argument(
            '--reason',
            type=str,
            default='SCHEDULED',
            choices=['SCHEDULED', 'EMERGENCY', 'COMPROMISE', 'POLICY'],
            help='Reason for rotation.'
        )
        parser.add_argument(
            '--dry-run',
            action='store_true',
            help='Validate rotation without committing changes.'
        )
        parser.add_argument(
            '--rollback',
            type=str,
            help='Rollback a failed rotation by KeyRotationLog UUID.'
        )
        parser.add_argument(
            '--verify-sample',
            type=int,
            default=10,
            help='Number of records to sample for post-rotation verification.'
        )

    def handle(self, *args, **options):
        if options['rollback']:
            self._handle_rollback(options['rollback'])
            return

        profile_ids = []
        if options['profile_id']:
            # Single profile rotation
            try:
                Profile.objects.get(id=options['profile_id'])
                profile_ids = [options['profile_id']]
            except Profile.DoesNotExist:
                raise CommandError(f"Profile {options['profile_id']} not found")
        else:
            # All active profiles
            profile_ids = list(Profile.objects.filter(is_active=True).values_list('id', flat=True))

        self.stdout.write(
            self.style.MIGRATE_HEADING(
                f"Starting key rotation for {len(profile_ids)} profile(s)"
            )
        )
        if options['dry_run']:
            self.stdout.write(self.style.WARNING("Running in DRY-RUN mode; no changes will be committed"))

        success_count = 0
        failed_count = 0

        for profile_id in profile_ids:
            try:
                self._rotate_profile_key(
                    profile_id,
                    options['reason'],
                    options['dry_run'],
                    options['verify_sample']
                )
                success_count += 1
            except Exception as e:
                self.stdout.write(self.style.ERROR(f"Failed to rotate key for {profile_id}: {e}"))
                failed_count += 1

        self.stdout.write(
            self.style.MIGRATE_LABEL(
                f"Rotation complete: {success_count} succeeded, {failed_count} failed"
            )
        )

    def _rotate_profile_key(self, profile_id, reason, dry_run, verify_sample):
        """Rotate key for a single profile."""
        try:
            rotation_log = KeyRotationManager.start_rotation(profile_id, reason, dry_run=dry_run)
            
            if dry_run:
                self.stdout.write(
                    self.style.SUCCESS(
                        f"[DRY-RUN] Would rotate key for {profile_id}: v{rotation_log.old_version} → v{rotation_log.new_version}"
                    )
                )
                return

            # Perform actual rotation
            KeyRotationManager.complete_rotation(rotation_log, verify_sample=True, sample_size=verify_sample)
            self.stdout.write(
                self.style.SUCCESS(
                    f"Rotated key for {profile_id}: v{rotation_log.old_version} → v{rotation_log.new_version}"
                )
            )

        except Exception as e:
            logger.exception(f"Error rotating key for {profile_id}")
            raise

    def _handle_rollback(self, rotation_log_id):
        """Rollback a failed rotation."""
        try:
            rotation_log = KeyRotationLog.objects.get(id=rotation_log_id)
        except KeyRotationLog.DoesNotExist:
            raise CommandError(f"KeyRotationLog {rotation_log_id} not found")

        try:
            KeyRotationManager.rollback_rotation(rotation_log)
            self.stdout.write(
                self.style.SUCCESS(
                    f"Rolled back rotation {rotation_log_id} to key v{rotation_log.old_version}"
                )
            )
        except Exception as e:
            raise CommandError(f"Rollback failed: {e}")
