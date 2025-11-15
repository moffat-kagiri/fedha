"""
Encryption utilities for field-level encryption.

This module provides a minimal FieldEncryption and KeyManager implementation
suitable for initial development. It uses AES-GCM for authenticated encryption.

Note: In production, store master keys in a secure vault (AWS KMS, Vault).
"""
import base64
import os
import json
from typing import Optional
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.hkdf import HKDF

from django.conf import settings
import logging

logger = logging.getLogger(__name__)

# Lazy-loaded KMS adapter to support runtime selection (env/aws/vault)
try:
    from .kms_adapter import get_kms_adapter
except Exception:
    # If kms_adapter is missing, we'll fallback to env/settings master key
    get_kms_adapter = None


def _master_key_from_raw(raw: str) -> bytes:
    """Convert a returned master key string to 32-byte key material.

    Accepts base64-encoded, URL-safe, or raw string; returns 32 bytes.
    """
    if raw is None:
        return None
    try:
        # Try base64 first
        return base64.b64decode(raw)
    except Exception:
        # Fallback: treat as raw bytes (URL-safe token)
        b = raw.encode('utf-8')
        if len(b) >= 32:
            return b[:32]
        # pad to 32
        return (b * (32 // len(b) + 1))[:32]


def _get_master_key() -> bytes:
    """Get master key from configured KMS adapter, environment, or settings.

    Order:
      1. KMS adapter (if available)
      2. ENV var `MASTER_ENCRYPTION_KEY`
      3. Django `SECRET_KEY` fallback (dev only)
    """
    # 1) KMS adapter
    if get_kms_adapter is not None:
        try:
            adapter = get_kms_adapter()
            raw = adapter.get_master_key()
            if raw:
                return _master_key_from_raw(raw)
        except Exception as e:
            logger.debug("KMS adapter get_master_key failed: %s", e)

    # 2) ENV var
    MASTER_KEY_ENV = os.environ.get('MASTER_ENCRYPTION_KEY')
    if MASTER_KEY_ENV:
        try:
            return base64.b64decode(MASTER_KEY_ENV)
        except Exception:
            return MASTER_KEY_ENV.encode()[:32]

    # 3) Fallback to settings SECRET_KEY-derived key (development only)
    key = getattr(settings, 'SECRET_KEY', None)
    if key:
        key = key.encode()
        if len(key) >= 32:
            return key[:32]
        return (key * 4)[:32]

    raise RuntimeError('No master encryption key available; configure KMS provider or MASTER_ENCRYPTION_KEY')


class KeyManager:
    """Simple key manager that derives per-profile keys from a master key.

    This is a pragmatic approach for local development. For production, use a
    dedicated key management system (AWS KMS / HashiCorp Vault) and store keys
    separately per profile.
    """

    _master_key_cache = None
    _kms_adapter = None

    @classmethod
    def _get_kms_adapter(cls):
        if cls._kms_adapter is None and get_kms_adapter is not None:
            try:
                cls._kms_adapter = get_kms_adapter()
            except Exception:
                cls._kms_adapter = None
        return cls._kms_adapter

    @classmethod
    def _get_master_key(cls) -> bytes:
        if cls._master_key_cache is not None:
            return cls._master_key_cache
        key = _get_master_key()
        cls._master_key_cache = key
        return key

    @staticmethod
    def derive_profile_key(profile_id: str, version: int = 1) -> bytes:
        master = KeyManager._get_master_key()
        hkdf = HKDF(
            algorithm=hashes.SHA256(),
            length=32,
            salt=str(version).encode(),
            info=(profile_id or 'global').encode(),
        )
        return hkdf.derive(master)


class KeyBootstrap:
    """Helpers to ensure a master key exists in the configured KMS/Secrets backend.

    Usage:
      KeyBootstrap.ensure_master_key(create_if_missing=True)
    """

    @staticmethod
    def ensure_master_key(create_if_missing: bool = True) -> bytes:
        """Ensure a master key exists. If missing and `create_if_missing` is True,
        attempt to create one via the adapter's `rotate_key()`.
        Returns key bytes.
        """
        if get_kms_adapter is None:
            # Nothing to do; rely on env/settings
            return _get_master_key()

        adapter = get_kms_adapter()
        try:
            raw = adapter.get_master_key()
            if raw:
                return _master_key_from_raw(raw)
        except Exception as e:
            logger.debug("Master key not found via adapter: %s", e)

        if not create_if_missing:
            raise RuntimeError('Master key missing from KMS provider')

        # Try to generate/rotate a new key in the adapter (many adapters implement rotate_key)
        try:
            new_raw = adapter.rotate_key()
            return _master_key_from_raw(new_raw)
        except Exception as e:
            logger.error("Failed to create master key in KMS provider: %s", e)
            # Fallback to env/settings
            return _get_master_key()


class FieldEncryption:
    """Encrypt/decrypt helper using AES-GCM.

    Stored ciphertext schema (base64-encoded JSON):
    {
        "v": 1,
        "ver": <key_version>,
        "nonce": base64(nonce),
        "ct": base64(ciphertext),
        "tag": base64(tag)  # AESGCM includes tag in ct in cryptography
    }
    """

    @staticmethod
    def encrypt(plaintext: str, profile_id: str, version: int = 1) -> str:
        if plaintext is None:
            return None
        key = KeyManager.derive_profile_key(profile_id, version)
        aesgcm = AESGCM(key)
        nonce = os.urandom(12)
        data = plaintext.encode('utf-8')
        ct = aesgcm.encrypt(nonce, data, None)
        payload = {
            'v': 1,
            'ver': version,
            'nonce': base64.b64encode(nonce).decode('utf-8'),
            'ct': base64.b64encode(ct).decode('utf-8'),
        }
        return base64.b64encode(json.dumps(payload).encode('utf-8')).decode('utf-8')

    @staticmethod
    def decrypt(ciphertext_b64: str, profile_id: str, version: Optional[int] = None) -> Optional[str]:
        if not ciphertext_b64:
            return None
        try:
            payload_json = base64.b64decode(ciphertext_b64.encode('utf-8'))
            payload = json.loads(payload_json)
            nonce = base64.b64decode(payload['nonce'])
            ct = base64.b64decode(payload['ct'])
            ver = payload.get('ver', 1)
            if version is None:
                version = ver
            key = KeyManager.derive_profile_key(profile_id, version)
            aesgcm = AESGCM(key)
            pt = aesgcm.decrypt(nonce, ct, None)
            return pt.decode('utf-8')
        except Exception:
            return None

    @staticmethod
    def hash_for_lookup(value: str) -> str:
        """Create a deterministic hash for searching without storing plaintext."""
        if value is None:
            return None
        digest = hashes.Hash(hashes.SHA256())
        digest.update(value.encode('utf-8'))
        return base64.b64encode(digest.finalize()).decode('utf-8')
