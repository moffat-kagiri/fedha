from django.core.management.base import BaseCommand
from api.utils.encryption import KeyBootstrap


class Command(BaseCommand):
    help = 'Ensure a master encryption key is available in the configured KMS/Secrets backend. Use --create to create one if missing.'

    def add_arguments(self, parser):
        parser.add_argument('--create', action='store_true', help='Create a new master key in the adapter if missing')

    def handle(self, *args, **options):
        create = options.get('create', False)
        # Safety guard: require ALLOW_AUTO_CREATE_MASTER='yes' to perform create
        allow_create = os.environ.get('ALLOW_AUTO_CREATE_MASTER', '').lower() in ('1', 'true', 'yes')
        if create and not allow_create:
            self.stdout.write(self.style.ERROR(
                "Refusing to create master key: set ALLOW_AUTO_CREATE_MASTER=yes in environment to allow auto-creation."
            ))
            return
        try:
            key = KeyBootstrap.ensure_master_key(create_if_missing=create)
            self.stdout.write(self.style.SUCCESS('Master key available.'))
            self.stdout.write(f'Key bytes length: {len(key)}')
        except Exception as e:
            self.stdout.write(self.style.ERROR(f'Failed to ensure master key: {e}'))
