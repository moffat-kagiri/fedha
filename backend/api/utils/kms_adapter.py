"""
KMS abstraction layer for switching key providers (env, AWS KMS, Vault, GCP).

Supports multiple key management backends:
- EnvVarAdapter: Local development (env variable)
- AWSSecretsManagerAdapter: AWS Secrets Manager (KMS-encrypted)
- AWSKMS_Adapter: AWS KMS (key-only operations)
- VaultAdapter: HashiCorp Vault
"""

import os
import json
import logging
from abc import ABC, abstractmethod
from typing import Optional

logger = logging.getLogger(__name__)


class KMSAdapter(ABC):
    """Abstract base class for key management services."""

    @abstractmethod
    def get_master_key(self) -> str:
        """Retrieve master encryption key as base64-encoded string."""
        pass

    @abstractmethod
    def rotate_key(self) -> str:
        """Rotate/generate new master key, return new key as base64-encoded string."""
        pass


class EnvVarAdapter(KMSAdapter):
    """Local development: retrieve key from environment variable."""

    def get_master_key(self) -> str:
        key = os.getenv('MASTER_ENCRYPTION_KEY')
        if not key:
            raise ValueError("MASTER_ENCRYPTION_KEY not set in environment")
        return key

    def rotate_key(self) -> str:
        import secrets
        return secrets.token_urlsafe(32)


class AWSSecretsManagerAdapter(KMSAdapter):
    """AWS Secrets Manager: retrieve key from AWS (KMS-encrypted at rest)."""

    def __init__(self, secret_name: str = "fedha/encryption/master-key", region: str = "us-east-1"):
        self.secret_name = secret_name
        self.region = region
        try:
            import boto3
            self.client = boto3.client('secretsmanager', region_name=region)
        except ImportError:
            raise ImportError("boto3 not installed. Install with: pip install boto3")
        self._cache = None

    def get_master_key(self) -> str:
        """Fetch master key from Secrets Manager (cached in memory)."""
        if self._cache:
            return self._cache

        try:
            response = self.client.get_secret_value(SecretId=self.secret_name)
            secret = json.loads(response['SecretString'])
            key = secret.get('key')
            if not key:
                raise ValueError("'key' field not found in secret")
            self._cache = key
            return key
        except self.client.exceptions.ResourceNotFoundException:
            raise ValueError(f"Secret '{self.secret_name}' not found in AWS Secrets Manager")
        except Exception as e:
            logger.error(f"Failed to retrieve key from Secrets Manager: {e}")
            raise

    def rotate_key(self) -> str:
        """Rotate secret in Secrets Manager."""
        import secrets
        new_key = secrets.token_urlsafe(32)
        try:
            self.client.put_secret_value(
                SecretId=self.secret_name,
                SecretString=json.dumps({"key": new_key})
            )
            self._cache = new_key  # Update cache
            logger.info(f"Key rotated in Secrets Manager: {self.secret_name}")
            return new_key
        except Exception as e:
            logger.error(f"Failed to rotate key: {e}")
            raise


class AWSKMS_Adapter(KMSAdapter):
    """AWS KMS: use AWS KMS for key operations (encryption at-rest)."""

    def __init__(self, key_id: str, region: str = "us-east-1"):
        """
        Args:
            key_id: ARN or alias of KMS key
            region: AWS region
        """
        self.key_id = key_id
        self.region = region
        try:
            import boto3
            self.client = boto3.client('kms', region_name=region)
        except ImportError:
            raise ImportError("boto3 not installed. Install with: pip install boto3")

    def get_master_key(self) -> str:
        """Note: Use AWSSecretsManagerAdapter for retrieving keys."""
        raise NotImplementedError(
            "Use AWSSecretsManagerAdapter for retrieving keys (it uses KMS encryption at rest)"
        )

    def rotate_key(self) -> str:
        """Request KMS key rotation."""
        try:
            self.client.enable_key_rotation(KeyId=self.key_id)
            logger.info(f"KMS key rotation enabled: {self.key_id}")
            return "Rotation scheduled by AWS KMS"
        except Exception as e:
            logger.error(f"Failed to enable KMS key rotation: {e}")
            raise


class VaultAdapter(KMSAdapter):
    """HashiCorp Vault: retrieve key from Vault server."""

    def __init__(self, vault_addr: str, vault_token: str, secret_path: str = "secret/fedha/encryption/master-key"):
        """
        Args:
            vault_addr: Vault server address (e.g., "https://vault.example.com:8200")
            vault_token: Vault authentication token
            secret_path: Path to secret in Vault
        """
        self.vault_addr = vault_addr
        self.vault_token = vault_token
        self.secret_path = secret_path
        try:
            import hvac
            self.client = hvac.Client(url=vault_addr, token=vault_token)
        except ImportError:
            raise ImportError("hvac not installed. Install with: pip install hvac")

    def get_master_key(self) -> str:
        """Fetch master key from Vault."""
        try:
            response = self.client.secrets.kv.read_secret_version(path=self.secret_path)
            key = response['data']['data'].get('key')
            if not key:
                raise ValueError(f"'key' field not found in Vault secret at {self.secret_path}")
            return key
        except Exception as e:
            logger.error(f"Failed to retrieve key from Vault: {e}")
            raise

    def rotate_key(self) -> str:
        """Rotate key in Vault."""
        import secrets
        new_key = secrets.token_urlsafe(32)
        try:
            self.client.secrets.kv.create_or_update_secret(
                path=self.secret_path,
                secret_dict={"key": new_key}
            )
            logger.info(f"Key rotated in Vault: {self.secret_path}")
            return new_key
        except Exception as e:
            logger.error(f"Failed to rotate key in Vault: {e}")
            raise


def get_kms_adapter() -> KMSAdapter:
    """
    Factory function: returns appropriate KMS adapter based on environment.
    
    Set KMS_PROVIDER environment variable to:
    - 'env': Environment variable (default for development)
    - 'aws-secrets-manager': AWS Secrets Manager
    - 'aws-kms': AWS KMS
    - 'vault': HashiCorp Vault
    """
    
    provider = os.getenv('KMS_PROVIDER', 'env').lower()
    
    if provider == 'env':
        return EnvVarAdapter()
    
    elif provider == 'aws-secrets-manager':
        secret_name = os.getenv('AWS_SECRET_NAME', 'fedha/encryption/master-key')
        region = os.getenv('AWS_REGION', 'us-east-1')
        return AWSSecretsManagerAdapter(secret_name=secret_name, region=region)
    
    elif provider == 'aws-kms':
        key_id = os.getenv('AWS_KMS_KEY_ID')
        if not key_id:
            raise ValueError("AWS_KMS_KEY_ID not set")
        region = os.getenv('AWS_REGION', 'us-east-1')
        return AWSKMS_Adapter(key_id=key_id, region=region)
    
    elif provider == 'vault':
        vault_addr = os.getenv('VAULT_ADDR')
        vault_token = os.getenv('VAULT_TOKEN')
        if not vault_addr or not vault_token:
            raise ValueError("VAULT_ADDR and VAULT_TOKEN not set")
        secret_path = os.getenv('VAULT_SECRET_PATH', 'secret/fedha/encryption/master-key')
        return VaultAdapter(vault_addr=vault_addr, vault_token=vault_token, secret_path=secret_path)
    
    else:
        raise ValueError(f"Unknown KMS_PROVIDER: {provider}. Use 'env', 'aws-secrets-manager', 'aws-kms', or 'vault'.")
