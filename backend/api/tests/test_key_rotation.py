from django.test import TestCase
from django.core.management import call_command
from api.models import Profile, EncryptionKeyVersion, KeyRotationLog
from api.utils.key_rotation import KeyRotationManager

class KeyRotationTests(TestCase):
    def setUp(self):
        self.profile = Profile.objects.create(name='KR Test', email='kr@example.com')

    def test_start_rotation_dry_run(self):
        # Dry-run should create a pending KeyRotationLog but not activate new key
        log = KeyRotationManager.start_rotation(profile_id=self.profile.id, reason='SCHEDULED', dry_run=True)
        self.assertIsInstance(log, KeyRotationLog)
        self.assertEqual(log.status, 'PENDING')
        # No new active key other than v1
        active = EncryptionKeyVersion.objects.filter(profile=self.profile, is_active=True)
        self.assertTrue(active.exists())
        self.assertEqual(active.count(), 1)

    def test_rotate_command_dry_run(self):
        # Management command dry-run
        call_command('rotate_encryption_keys', '--profile-id', str(self.profile.id), '--dry-run')
        # Expect a KeyRotationLog created
        logs = KeyRotationLog.objects.filter(profile=self.profile)
        self.assertTrue(logs.exists())

    def test_monitor_command_runs(self):
        # Should run without error and output to stdout
        call_command('monitor_encryption')

