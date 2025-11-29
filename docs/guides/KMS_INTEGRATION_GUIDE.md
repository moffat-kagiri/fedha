# KMS Integration Guide

Production encryption key management using cloud HSMs (Hardware Security Modules) or vault services.

## Overview

The default Fedha encryption uses a `MASTER_ENCRYPTION_KEY` stored in environment variables. This guide covers integration with external key management services for production deployments:

- **AWS KMS** (AWS Key Management Service)
- **AWS Secrets Manager** (for key storage + rotation)
- **HashiCorp Vault** (self-hosted or cloud-managed)
- **Google Cloud KMS** (Google Cloud Platform)

## Architecture

```
Application
    ↓
[Fedha Encryption Layer]
    ↓
[KMS Adapter] ← abstraction layer
    ↓
├─ AWS KMS (prod)
├─ Vault (prod)
├─ Env var (dev/test)
```

The KMS adapter (`backend/api/utils/kms_adapter.py`) abstracts key management, allowing switching providers without code changes.

---

## Setup: AWS KMS + Secrets Manager (Recommended for AWS)

### Prerequisites
- AWS Account with appropriate permissions
- `boto3` Python library installed: `pip install boto3`
- IAM user/role with KMS and Secrets Manager permissions

### Step 1: Create Master Key in AWS KMS

```bash
# via AWS CLI
aws kms create-key --description "Fedha Encryption Master Key" --region us-east-1
# Output: KeyId=arn:aws:kms:us-east-1:123456789:key/12345678-abcd-1234...

# Create alias for easy reference
aws kms create-alias --alias-name alias/fedha-master-key --target-key-id <KeyId>
```

### Step 2: Store Master Key in AWS Secrets Manager

```bash
# Generate encryption key (if not already done)
MASTER_KEY=$(python -c "import secrets; print(secrets.token_urlsafe(32))")

# Store in Secrets Manager
aws secretsmanager create-secret \
  --name fedha/encryption/master-key \
  --secret-string "{\"key\": \"$MASTER_KEY\"}" \
  --region us-east-1
# Output: ARN=arn:aws:secretsmanager:us-east-1:123456789:secret:fedha/encryption/master-key...
```

### Step 3: Create KMS Adapter

Create `backend/api/utils/kms_adapter.py`:

```python
"""
KMS abstraction layer for switching key providers (env, AWS KMS, Vault, GCP).
"""

import os
import json
import boto3
from abc import ABC, abstractmethod
from typing import Optional
import logging

logger = logging.getLogger(__name__)


class KMSAdapter(ABC):
    """Abstract base class for key management services."""

    @abstractmethod
    def get_master_key(self) -> str:
        """Retrieve master encryption key."""
        pass

    @abstractmethod
    def rotate_key(self) -> str:
        """Rotate/generate new master key."""
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
    """AWS Secrets Manager: retrieve key from AWS."""

    def __init__(self, secret_name: str = "fedha/encryption/master-key", region: str = "us-east-1"):
        self.secret_name = secret_name
        self.region = region
        self.client = boto3.client('secretsmanager', region_name=region)
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
            key_id: ARN or alias of KMS key (e.g., "arn:aws:kms:us-east-1:123456789:key/...")
            region: AWS region
        """
        self.key_id = key_id
        self.region = region
        self.client = boto3.client('kms', region_name=region)

    def get_master_key(self) -> str:
        """Retrieve master key from Secrets Manager, but it's encrypted by KMS."""
        # In practice, use AWSSecretsManagerAdapter (which internally uses KMS encryption)
        # This adapter mainly handles KMS-level operations
        raise NotImplementedError("Use AWSSecretsManagerAdapter for retrieving keys (it uses KMS encryption)")

    def rotate_key(self) -> str:
        """Request KMS key rotation (KMS handles automatic rotation)."""
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
    """Factory function: returns appropriate KMS adapter based on environment."""
    
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
        raise ValueError(f"Unknown KMS_PROVIDER: {provider}")
```

### Step 4: Update Encryption Utility to Use KMS Adapter

Edit `backend/api/utils/encryption.py` to use the KMS adapter:

```python
# In encryption.py KeyManager class

from .kms_adapter import get_kms_adapter

class KeyManager:
    """Manages encryption keys with KMS support."""
    
    _master_key_cache = None
    _kms_adapter = None

    @classmethod
    def _get_kms_adapter(cls):
        if cls._kms_adapter is None:
            cls._kms_adapter = get_kms_adapter()
        return cls._kms_adapter

    @classmethod
    def _get_master_key(cls) -> bytes:
        """Get master key from KMS provider."""
        if cls._master_key_cache is not None:
            return cls._master_key_cache

        adapter = cls._get_kms_adapter()
        key_b64 = adapter.get_master_key()
        
        # Convert base64 to bytes
        import base64
        key_bytes = base64.b64decode(key_b64)
        cls._master_key_cache = key_bytes
        return key_bytes

    # Rest of KeyManager remains unchanged
```

### Step 5: Set Environment Variables (Production)

```bash
# In production (ECS, Lambda, EC2):
export KMS_PROVIDER=aws-secrets-manager
export AWS_SECRET_NAME=fedha/encryption/master-key
export AWS_REGION=us-east-1

# Or for KMS-only:
export KMS_PROVIDER=aws-kms
export AWS_KMS_KEY_ID=arn:aws:kms:us-east-1:123456789:key/12345678-abcd-1234...
export AWS_REGION=us-east-1
```

### Step 6: Test KMS Adapter

```bash
python manage.py shell
>>> from api.utils.kms_adapter import get_kms_adapter
>>> adapter = get_kms_adapter()
>>> key = adapter.get_master_key()
>>> print(f"Key retrieved: {key[:20]}...")  # First 20 chars
```

---

## Setup: HashiCorp Vault (Self-Hosted or Cloud)

### Prerequisites
- Vault instance running (self-hosted or Vault Cloud)
- `hvac` Python library: `pip install hvac`
- Vault CLI configured with appropriate permissions

### Step 1: Create Secret in Vault

```bash
# Authenticate to Vault
vault login -method=userpass username=$USER

# Generate master key
MASTER_KEY=$(python -c "import secrets; print(secrets.token_urlsafe(32))")

# Store in Vault
vault kv put secret/fedha/encryption/master-key key=$MASTER_KEY

# Verify
vault kv get secret/fedha/encryption/master-key
```

### Step 2: Set Environment Variables (Development)

```bash
export KMS_PROVIDER=vault
export VAULT_ADDR=http://localhost:8200
export VAULT_TOKEN=hvs.0abcd123...  # Or use auth method
export VAULT_SECRET_PATH=secret/fedha/encryption/master-key
```

### Step 3: Enable Vault Key Rotation Policy (Optional)

Create a Vault policy for automatic key rotation:

```hcl
# kms-policy.hcl
path "secret/fedha/encryption/master-key" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
```

Apply policy:

```bash
vault policy write fedha-encryption kms-policy.hcl
```

---

## Testing KMS Providers

### Test AWS Secrets Manager

```bash
export KMS_PROVIDER=aws-secrets-manager
export AWS_SECRET_NAME=fedha/encryption/master-key
export AWS_REGION=us-east-1

python manage.py shell
>>> from api.utils.encryption import KeyManager
>>> key = KeyManager._get_master_key()
>>> print(f"Successfully retrieved {len(key)} byte key from AWS Secrets Manager")
```

### Test Vault

```bash
export KMS_PROVIDER=vault
export VAULT_ADDR=http://localhost:8200
export VAULT_TOKEN=mytoken

python manage.py shell
>>> from api.utils.encryption import KeyManager
>>> key = KeyManager._get_master_key()
>>> print(f"Successfully retrieved {len(key)} byte key from Vault")
```

### Fallback to Environment Variable (Development)

```bash
export KMS_PROVIDER=env
export MASTER_ENCRYPTION_KEY=$(python -c "import secrets; print(secrets.token_urlsafe(32))")

python manage.py shell
>>> from api.utils.encryption import KeyManager
>>> key = KeyManager._get_master_key()
>>> print(f"Successfully retrieved key from environment")
```

## Environment variables reference & bootstrap

Set one of these `KMS_PROVIDER` values and the corresponding env vars before starting the backend. Use the `bootstrap_master_key` management command to verify or create a master key (only use `--create` in controlled environments).

AWS Secrets Manager (recommended):

```bash
export KMS_PROVIDER=aws-secrets-manager
export AWS_SECRET_NAME=fedha/encryption/master-key
export AWS_REGION=us-east-1
```

HashiCorp Vault:

```bash
export KMS_PROVIDER=vault
export VAULT_ADDR=https://vault.example.com:8200
export VAULT_TOKEN=<vault-token>
export VAULT_SECRET_PATH=secret/fedha/encryption/master-key
```

Env var (development):

```bash
export KMS_PROVIDER=env
export MASTER_ENCRYPTION_KEY=<base64-or-url-safe-key>
```

Bootstrap the master key (management command):

PowerShell (Windows):
```powershell
cd c:\GitHub\fedha\backend
$env:KMS_PROVIDER='aws-secrets-manager'
python manage.py bootstrap_master_key --create
```

Bash (Linux/macOS):
```bash
cd /path/to/fedha/backend
KMS_PROVIDER=aws-secrets-manager python manage.py bootstrap_master_key --create
```

Important:
- In production, prefer pre-provisioning the master key in your Secrets Manager or Vault and avoid `--create`.
- Ensure the service role/credentials used by the application have minimal required permissions (read/get, put for rotations if needed).

---

## Production Deployment Checklist

- [ ] KMS provider configured (AWS/Vault/GCP)
- [ ] Master key stored securely (not in code/env files)
- [ ] IAM roles/policies restrict key access to app service
- [ ] Key rotation scheduled (AWS: automatic; Vault: configured policy)
- [ ] Encryption adapter tested with production KMS
- [ ] Key retrieval latency acceptable (<100ms)
- [ ] Fallback strategy documented (what if KMS is unavailable?)
- [ ] Key rotation tested with `rotate_encryption_keys` command
- [ ] Audit logs enabled (AWS CloudTrail, Vault audit logs)

---

## Troubleshooting

| Error | Solution |
|-------|----------|
| `KMS_PROVIDER not set` | Default is 'env'. Set explicitly for AWS/Vault. |
| `botocore.exceptions.ClientError: Access Denied` | Check IAM permissions for SecretsManager/KMS actions. |
| `hvac.exceptions.InvalidPath` | Verify VAULT_SECRET_PATH exists in Vault. |
| `ConnectionRefusedError to Vault` | Check VAULT_ADDR is reachable (e.g., http://localhost:8200). |
| `Key rotation failing` | Check service has write permission to secret/key store. |

---

## References

- [AWS KMS Documentation](https://docs.aws.amazon.com/kms/)
- [AWS Secrets Manager Documentation](https://docs.aws.amazon.com/secretsmanager/)
- [HashiCorp Vault Documentation](https://www.vaultproject.io/docs)
- [hvac Python Client](https://hvac.readthedocs.io/)
- [Google Cloud KMS Documentation](https://cloud.google.com/kms/docs)
