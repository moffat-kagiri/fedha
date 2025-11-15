#!/usr/bin/env python
"""Quick Phase 2 validation test."""

import os
import django
from django.conf import settings

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'backend.settings')
os.environ['MASTER_ENCRYPTION_KEY'] = 'GFQz-_L8s4K9nPqRxYaB-cDeFgHiJkLmNoPqRs='

django.setup()

from api.models import Profile, EncryptionKeyVersion
from api.utils.key_rotation import KeyRotationManager

print("\n=== Phase 2 Validation Test ===\n")

# Test 1: Create encrypted profile
print("[Test 1] Create profile with encryption...")
profile = Profile.objects.create(name='Test User', email='test@example.com')
print(f"✓ Created profile: {profile.id}")
print(f"✓ Encryption version: {profile.encryption_version}")

# Test 2: Verify active key
print("\n[Test 2] Verify active encryption key...")
current_key = EncryptionKeyVersion.objects.filter(profile=profile, is_active=True).first()
if current_key:
    print(f"✓ Active key found: v{current_key.version}")
    print(f"✓ Algorithm: {current_key.algorithm}")
else:
    print("✗ No active key found - FAILED")
    exit(1)

# Test 3: Test key rotation workflow (dry-run)
print("\n[Test 3] Test key rotation (dry-run)...")
try:
    rotation_log = KeyRotationManager.start_rotation(
        profile_id=profile.id,
        reason='SCHEDULED',
        dry_run=True
    )
    print(f"✓ Dry-run rotation created: {rotation_log.id}")
    print(f"✓ Status: {rotation_log.status}")
    
    # Cleanup dry-run rotation
    rotation_log.delete()
    print("✓ Dry-run rotation cleaned up")
except Exception as e:
    print(f"✗ Key rotation failed: {e}")
    exit(1)

# Test 4: Verify encryption/decryption
print("\n[Test 4] Verify encrypt/decrypt round-trip...")
plain_name = profile.decrypt_field('name')
if plain_name == 'Test User':
    print(f"✓ Decrypted name matches: {plain_name}")
else:
    print(f"✗ Decrypted name mismatch. Expected 'Test User', got '{plain_name}'")
    exit(1)

# Cleanup
print("\n[Cleanup] Remove test profile...")
profile.delete()
print("✓ Test profile removed")

print("\n=== All Phase 2 tests passed! ===\n")
