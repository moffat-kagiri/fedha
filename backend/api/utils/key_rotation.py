"""
Key rotation utilities for field-level encryption.

Provides KeyRotationManager for scheduled and emergency key rotations,
with comprehensive auditing and rollback support.
"""

import logging
from datetime import timedelta
from django.utils import timezone
from django.db import transaction
from api.models import EncryptionKeyVersion, KeyRotationLog, Profile
from api.utils.encryption import FieldEncryption, KeyManager

logger = logging.getLogger(__name__)


class KeyRotationManager:
    """
    Manage encryption key rotation with auditing, versioning, and rollback.
    
    Supports:
    - Scheduled rotation (rotate keys on expiration).
    - Emergency rotation (immediate rotation on compromise).
    - Dry-run validation (verify rotation before commit).
    - Rollback (revert to previous key version if rotation fails).
    """

    @staticmethod
    def create_new_key_version(profile_id=None, reason='SCHEDULED'):
        """
        Create a new encryption key version for a profile (or master key if profile_id is None).
        
        Args:
            profile_id: Profile UUID or None for master key.
            reason: Reason for rotation (SCHEDULED, EMERGENCY, COMPROMISE, POLICY).
        
        Returns:
            New EncryptionKeyVersion instance.
        """
        try:
            profile_obj = Profile.objects.get(id=profile_id) if profile_id else None
        except Profile.DoesNotExist:
            raise ValueError(f"Profile {profile_id} not found")

        # Find next version number
        if profile_obj:
            latest_version = EncryptionKeyVersion.objects.filter(profile=profile_obj).order_by('-version').first()
        else:
            latest_version = EncryptionKeyVersion.objects.filter(profile__isnull=True).order_by('-version').first()
        
        next_version = (latest_version.version if latest_version else 0) + 1

        # Create new key version record
        key_version = EncryptionKeyVersion.objects.create(
            profile=profile_obj,
            version=next_version,
            algorithm='AES-256-GCM',
            key_fingerprint=KeyRotationManager._compute_fingerprint(profile_id, next_version),
            is_active=False,  # Inactive until migration completes
            is_master_key=(profile_id is None),
        )

        logger.info(f"Created new key version {next_version} for profile {profile_id or 'master'}")
        return key_version

    @staticmethod
    def _compute_fingerprint(profile_id, version):
        """Generate a deterministic fingerprint for a key version."""
        import hashlib
        data = f"{profile_id or 'master'}:{version}".encode()
        return hashlib.sha256(data).hexdigest()[:16]

    @staticmethod
    def start_rotation(profile_id=None, reason='SCHEDULED', dry_run=False):
        """
        Initiate key rotation for a profile or master key.
        
        Args:
            profile_id: Profile UUID or None for master key.
            reason: Rotation reason code.
            dry_run: If True, validate without committing.
        
        Returns:
            KeyRotationLog instance (status=IN_PROGRESS or PENDING).
        """
        if not profile_id:
            raise ValueError("Profile ID required for rotation")

        # Find current active key
        current_key = EncryptionKeyVersion.objects.filter(
            profile_id=profile_id,
            is_active=True
        ).order_by('-version').first()
        
        if not current_key:
            raise ValueError(f"No active key found for profile {profile_id}")

        # Create new key version
        new_key = KeyRotationManager.create_new_key_version(profile_id, reason)

        # Create rotation log
        rotation_log = KeyRotationLog.objects.create(
            profile_id=profile_id,
            old_version=current_key.version,
            new_version=new_key.version,
            reason=reason,
            status='PENDING' if dry_run else 'IN_PROGRESS',
            fields_reencrypted=[]
        )

        if dry_run:
            logger.info(f"Dry-run rotation log created: {rotation_log.id}")
        else:
            logger.info(f"Starting key rotation for profile {profile_id}: {current_key.version} → {new_key.version}")

        return rotation_log

    @staticmethod
    @transaction.atomic
    def complete_rotation(rotation_log, verify_sample=True, sample_size=10):
        """
        Mark rotation as complete and activate new key version.
        
        Args:
            rotation_log: KeyRotationLog instance to complete.
            verify_sample: If True, verify decryption on sample of re-encrypted records.
            sample_size: Number of records to sample for verification.
        
        Returns:
            Updated KeyRotationLog with status=COMPLETED.
        """
        if rotation_log.status != 'IN_PROGRESS':
            raise ValueError(f"Cannot complete rotation with status {rotation_log.status}")

        try:
            # Activate new key
            new_key = EncryptionKeyVersion.objects.get(
                profile_id=rotation_log.profile_id,
                version=rotation_log.new_version
            )
            new_key.is_active = True
            new_key.save()

            # Deactivate old key (keep for decrypt fallback)
            old_key = EncryptionKeyVersion.objects.get(
                profile_id=rotation_log.profile_id,
                version=rotation_log.old_version
            )
            old_key.is_active = False
            old_key.save()

            # Perform sample verification if requested
            if verify_sample:
                KeyRotationManager._verify_sample(
                    rotation_log.profile_id, rotation_log.new_version, sample_size
                )

            # Mark rotation complete
            rotation_log.status = 'COMPLETED'
            rotation_log.completed_at = timezone.now()
            rotation_log.save()

            logger.info(f"Rotation {rotation_log.id} completed and new key activated")
            return rotation_log

        except Exception as e:
            rotation_log.status = 'FAILED'
            rotation_log.error_message = str(e)
            rotation_log.save()
            logger.error(f"Rotation {rotation_log.id} failed: {e}")
            raise

    @staticmethod
    def rollback_rotation(rotation_log):
        """
        Rollback a failed rotation to restore the previous active key.
        
        Args:
            rotation_log: KeyRotationLog to rollback.
        
        Returns:
            Updated KeyRotationLog with status=FAILED and old key re-activated.
        """
        try:
            # Reactivate old key
            old_key = EncryptionKeyVersion.objects.get(
                profile_id=rotation_log.profile_id,
                version=rotation_log.old_version
            )
            old_key.is_active = True
            old_key.save()

            # Deactivate new key
            new_key = EncryptionKeyVersion.objects.get(
                profile_id=rotation_log.profile_id,
                version=rotation_log.new_version
            )
            new_key.is_active = False
            new_key.save()

            rotation_log.status = 'FAILED'
            rotation_log.save()

            logger.warning(f"Rolled back rotation {rotation_log.id} to key v{rotation_log.old_version}")
            return rotation_log

        except Exception as e:
            logger.error(f"Rollback of rotation {rotation_log.id} failed: {e}")
            raise

    @staticmethod
    def _verify_sample(profile_id, new_version, sample_size=10):
        """
        Verify that a sample of records encrypted with new key can be decrypted.
        
        Args:
            profile_id: Profile UUID.
            new_version: New key version to verify.
            sample_size: Number of records to sample.
        
        Raises:
            ValueError: If verification fails.
        """
        from api.models import Client
        
        # Sample encrypted records
        records = Client.objects.filter(profile_id=profile_id, name_encrypted__isnull=False)[:sample_size]
        
        if not records.exists():
            logger.warning(f"No encrypted records found for verification in profile {profile_id}")
            return

        failed_count = 0
        for record in records:
            try:
                # Try to decrypt with new version key
                plaintext = FieldEncryption.decrypt(
                    record.name_encrypted,
                    profile_id=profile_id,
                    version=new_version
                )
                if not plaintext:
                    failed_count += 1
            except Exception as e:
                logger.warning(f"Failed to verify decryption for {record.id}: {e}")
                failed_count += 1

        if failed_count > 0:
            raise ValueError(f"Verification failed: {failed_count}/{sample_size} records could not be decrypted")
        
        logger.info(f"Verification passed: {len(records)} records successfully decrypted with new key")

    @staticmethod
    def get_rotation_status(profile_id):
        """
        Get current rotation status and key versions for a profile.
        
        Returns:
            Dict with current_version, pending_rotation, and key expiration info.
        """
        active_key = EncryptionKeyVersion.objects.filter(
            profile_id=profile_id,
            is_active=True
        ).first()
        
        pending_rotation = KeyRotationLog.objects.filter(
            profile_id=profile_id,
            status='IN_PROGRESS'
        ).order_by('-started_at').first()

        return {
            'current_version': active_key.version if active_key else None,
            'current_key_age_days': (timezone.now() - active_key.created_at).days if active_key else None,
            'expires_at': active_key.expires_at if active_key else None,
            'pending_rotation': {
                'id': str(pending_rotation.id),
                'old_version': pending_rotation.old_version,
                'new_version': pending_rotation.new_version,
                'reason': pending_rotation.reason,
            } if pending_rotation else None,
        }
