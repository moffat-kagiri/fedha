"""
Django management command to clear all transactions for testing purposes.

Usage:
    python manage.py clear_transactions [--profile-id <uuid>] [--all]

Examples:
    # Clear transactions for a specific profile
    python manage.py clear_transactions --profile-id 550e8400-e29b-41d4-a716-446655440000
    
    # Clear all transactions in the database
    python manage.py clear_transactions --all
    
    # Interactive mode (will prompt for confirmation)
    python manage.py clear_transactions
"""

from django.core.management.base import BaseCommand
from transactions.models import Transaction
from accounts.models import Profile


class Command(BaseCommand):
    help = 'Clear transactions from the database for testing'

    def add_arguments(self, parser):
        parser.add_argument(
            '--profile-id',
            type=str,
            help='Clear transactions for a specific profile (UUID)'
        )
        parser.add_argument(
            '--all',
            action='store_true',
            help='Clear ALL transactions in the database'
        )
        parser.add_argument(
            '--force',
            action='store_true',
            help='Skip confirmation prompt'
        )

    def handle(self, *args, **options):
        profile_id = options.get('profile_id')
        clear_all = options.get('all')
        force = options.get('force')

        # Determine what to clear
        if clear_all:
            queryset = Transaction.objects.all()
            scope = 'ALL transactions in the database'
        elif profile_id:
            try:
                profile = Profile.objects.get(id=profile_id)
                queryset = Transaction.objects.filter(profile=profile)
                scope = f'transactions for profile {profile.id} ({profile.email})'
            except Profile.DoesNotExist:
                self.stdout.write(
                    self.style.ERROR(f'Profile {profile_id} not found')
                )
                return
        else:
            self.stdout.write(
                self.style.WARNING('No profile specified. Available profiles:')
            )
            profiles = Profile.objects.all()
            for p in profiles:
                count = Transaction.objects.filter(profile=p).count()
                self.stdout.write(f'  {p.id} ({p.email}): {count} transactions')
            
            self.stdout.write(
                self.style.WARNING(
                    '\nUsage: python manage.py clear_transactions --profile-id <uuid>'
                )
            )
            return

        count = queryset.count()

        # Confirmation
        if not force:
            response = input(
                f'\n⚠️  Are you sure you want to DELETE {count} {scope}? '
                'Type "yes" to confirm: '
            )
            if response.lower() != 'yes':
                self.stdout.write(self.style.WARNING('Operation cancelled'))
                return

        # Delete
        deleted_count, details = queryset.delete()
        
        self.stdout.write(
            self.style.SUCCESS(
                f'✅ Successfully deleted {count} transactions'
            )
        )
        
        if details:
            self.stdout.write('\nDeletion details:')
            for model, count in details.items():
                self.stdout.write(f'  - {model}: {count}')
