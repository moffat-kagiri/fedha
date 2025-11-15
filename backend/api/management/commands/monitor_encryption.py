"""
Management command: monitor_encryption

Monitor encryption health, key expiration, and coverage statistics.
"""

from django.core.management.base import BaseCommand
from django.utils import timezone
from django.db.models import Count, Q
from api.models import (
    Profile, Client, EnhancedTransaction, Loan, 
    EncryptionKeyVersion, KeyRotationLog
)
from datetime import timedelta
import logging

logger = logging.getLogger(__name__)


class Command(BaseCommand):
    help = 'Monitor encryption health and key status. Shows expiration alerts, coverage metrics, and pending rotations.'

    def add_arguments(self, parser):
        parser.add_argument(
            '--warn-days',
            type=int,
            default=30,
            help='Warn if key expires within N days (default: 30).'
        )
        parser.add_argument(
            '--profile-id',
            type=str,
            help='Show detailed stats for a specific profile.'
        )

    def handle(self, *args, **options):
        warn_days = options['warn_days']
        profile_id = options['profile_id']

        self.stdout.write(self.style.MIGRATE_HEADING('Encryption Health Monitor'))
        self.stdout.write('')

        # Check for expiring keys
        self._check_key_expiration(warn_days)
        self.stdout.write('')

        # Check encryption coverage
        self._check_encryption_coverage()
        self.stdout.write('')

        # Check pending rotations
        self._check_pending_rotations()
        self.stdout.write('')

        # Per-profile details if requested
        if profile_id:
            self._profile_details(profile_id)

    def _check_key_expiration(self, warn_days):
        """Check for keys expiring soon."""
        self.stdout.write(self.style.MIGRATE_LABEL('Key Expiration Status:'))
        
        now = timezone.now()
        warn_threshold = now + timedelta(days=warn_days)

        # Check active keys
        active_keys = EncryptionKeyVersion.objects.filter(is_active=True)
        
        expiring = active_keys.filter(expires_at__lte=warn_threshold, expires_at__isnull=False)
        if expiring.exists():
            self.stdout.write(self.style.WARNING(f"  ⚠️  {expiring.count()} key(s) expiring soon:"))
            for key in expiring:
                days_left = (key.expires_at - now).days
                profile_label = f"Profile {key.profile_id}" if key.profile_id else "Master Key"
                self.stdout.write(f"    - {profile_label} (v{key.version}): {days_left} days left")
        else:
            self.stdout.write(self.style.SUCCESS("  ✓ No keys expiring soon"))

        # Check for keys without expiration date
        no_expiry = active_keys.filter(expires_at__isnull=True)
        if no_expiry.count() > 0:
            self.stdout.write(self.style.WARNING(f"  ⚠️  {no_expiry.count()} key(s) have no expiration date (set one for rotation scheduling)"))

    def _check_encryption_coverage(self):
        """Check encryption coverage for PII fields."""
        self.stdout.write(self.style.MIGRATE_LABEL('Encryption Coverage:'))

        # Profile PII coverage
        total_profiles = Profile.objects.count()
        encrypted_profiles = Profile.objects.filter(name_encrypted__isnull=False).count()
        if total_profiles > 0:
            coverage_pct = (encrypted_profiles / total_profiles) * 100
            self.stdout.write(f"  Profile.name: {encrypted_profiles}/{total_profiles} ({coverage_pct:.1f}%)")

        # Client PII coverage
        total_clients = Client.objects.count()
        encrypted_clients = Client.objects.filter(name_encrypted__isnull=False).count()
        if total_clients > 0:
            coverage_pct = (encrypted_clients / total_clients) * 100
            self.stdout.write(f"  Client.name: {encrypted_clients}/{total_clients} ({coverage_pct:.1f}%)")
        else:
            self.stdout.write("  Client.name: No clients found")

        # Transaction PII coverage
        total_txns = EnhancedTransaction.objects.count()
        encrypted_txns = EnhancedTransaction.objects.filter(reference_number_encrypted__isnull=False).count()
        if total_txns > 0:
            coverage_pct = (encrypted_txns / total_txns) * 100
            self.stdout.write(f"  EnhancedTransaction.reference: {encrypted_txns}/{total_txns} ({coverage_pct:.1f}%)")
        else:
            self.stdout.write("  EnhancedTransaction.reference: No transactions found")

        # Loan PII coverage
        total_loans = Loan.objects.count()
        encrypted_loans = Loan.objects.filter(account_number_encrypted__isnull=False).count()
        if total_loans > 0:
            coverage_pct = (encrypted_loans / total_loans) * 100
            self.stdout.write(f"  Loan.account_number: {encrypted_loans}/{total_loans} ({coverage_pct:.1f}%)")
        else:
            self.stdout.write("  Loan.account_number: No loans found")

    def _check_pending_rotations(self):
        """Check for pending or in-progress rotations."""
        self.stdout.write(self.style.MIGRATE_LABEL('Key Rotation Status:'))

        pending = KeyRotationLog.objects.filter(status__in=['PENDING', 'IN_PROGRESS'])
        if pending.exists():
            self.stdout.write(self.style.WARNING(f"  ⚠️  {pending.count()} rotation(s) in progress:"))
            for rotation in pending:
                self.stdout.write(
                    f"    - Profile {rotation.profile_id}: v{rotation.old_version} → v{rotation.new_version} "
                    f"({rotation.reason}) - Status: {rotation.status}"
                )
        else:
            self.stdout.write(self.style.SUCCESS("  ✓ No pending rotations"))

        failed = KeyRotationLog.objects.filter(status='FAILED').order_by('-started_at')[:5]
        if failed.exists():
            self.stdout.write(self.style.ERROR(f"  ✗ {failed.count()} recent failed rotation(s):"))
            for rotation in failed:
                self.stdout.write(f"    - {rotation.id}: {rotation.error_message or 'Unknown error'}")

    def _profile_details(self, profile_id):
        """Show detailed encryption stats for a profile."""
        self.stdout.write(self.style.MIGRATE_LABEL(f'Details for Profile {profile_id}:'))

        try:
            profile = Profile.objects.get(id=profile_id)
        except Profile.DoesNotExist:
            self.stdout.write(self.style.ERROR(f"Profile {profile_id} not found"))
            return

        # Key versions
        key_versions = EncryptionKeyVersion.objects.filter(profile=profile).order_by('-version')
        self.stdout.write(f"  Active Keys: {profile.encryption_version}")
        for key in key_versions[:5]:
            status = "ACTIVE" if key.is_active else "inactive"
            expiry = f"expires {(key.expires_at - timezone.now()).days}d" if key.expires_at else "no expiry"
            self.stdout.write(f"    - v{key.version}: {status} ({expiry})")

        # Recent rotations
        recent_rotations = KeyRotationLog.objects.filter(profile=profile).order_by('-started_at')[:3]
        if recent_rotations.exists():
            self.stdout.write(f"  Recent Rotations:")
            for rotation in recent_rotations:
                self.stdout.write(f"    - {rotation.started_at}: v{rotation.old_version}→v{rotation.new_version} [{rotation.status}]")
