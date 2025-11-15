from django.test import TestCase
from api.models import Profile, Client

class EncryptionRoundtripTests(TestCase):
    def test_profile_encrypt_decrypt(self):
        # Create a profile
        profile = Profile.objects.create(
            name='Alice Example',
            profile_type=Profile.ProfileType.PERSONAL,
            pin_hash=Profile.hash_pin('1234')
        )

        # Ensure plaintext accessible
        self.assertEqual(profile.name, 'Alice Example')

        # Encrypt and set
        profile.encrypt_and_set('name', 'Alice Example')
        profile.save()

        # Decrypted value should be available via decrypt_field
        decrypted = profile.decrypt_field('name')
        self.assertEqual(decrypted, 'Alice Example')

    def test_client_encrypt_decrypt(self):
        profile = Profile.objects.create(
            name='Bob',
            profile_type=Profile.ProfileType.PERSONAL,
            pin_hash=Profile.hash_pin('9999')
        )

        client = Client.objects.create(
            profile=profile,
            name='Client Inc',
            email='client@example.com',
            phone='+254700000000'
        )

        client.encrypt_and_set('name', 'Client Inc')
        client.encrypt_and_set('email', 'client@example.com')
        client.encrypt_and_set('phone', '+254700000000')
        client.save()

        self.assertEqual(client.decrypt_field('name'), 'Client Inc')
        self.assertEqual(client.decrypt_field('email'), 'client@example.com')
        self.assertEqual(client.decrypt_field('phone'), '+254700000000')
