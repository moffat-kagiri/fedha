# Phase 2 — Encryption & Key Management — Release Notes

Date: 2025-11-15

Summary
- Implemented field-level encryption for PII fields (AES-256-GCM, per-profile key derivation).
- Added key-version tracking and key rotation utilities.
- Provided operational tooling: management commands to encrypt existing PII, rotate keys, and monitor encryption health.
- Added KMS adapter with support for environment variable, AWS Secrets Manager, AWS KMS enablement, and HashiCorp Vault.
- Added migrations implementing the schema changes and a safe backfill for key rotation logs.
- Added unit tests covering rotation and monitoring flows.

Notable files
- `backend/api/utils/encryption.py` — encryption primitives, key derivation
- `backend/api/utils/kms_adapter.py` — KMS abstraction layer
- `backend/api/utils/key_rotation.py` — rotation orchestration
- `backend/api/management/commands/encrypt_existing_pii.py` — batch migration command
- `backend/api/management/commands/rotate_encryption_keys.py` — rotation CLI
- `backend/api/management/commands/monitor_encryption.py` — monitoring CLI
- `backend/api/migrations/0005`..`0009` — key-management & PII migrations + backfill
- `docs/ENCRYPTION_MIGRATION_CHECKLIST.md` — migration playbook
- `docs/KMS_INTEGRATION_GUIDE.md` — KMS integration guide

Upgrade notes
1. Backup database (mandatory).
2. Provision production KMS/Secrets Manager or Vault and set `MASTER_ENCRYPTION_KEY` via the recommended adapter.
3. Run migrations sequentially. If using a zero-downtime plan, follow `ENCRYPTION_MIGRATION_CHECKLIST.md`.

Operational notes
- Use `python manage.py rotate_encryption_keys --dry-run` to validate rotation logic.
- Monitor keys weekly with `python manage.py monitor_encryption`.
- Enforce IAM and audit logging in production KMS.

Known limitations & future work
- We created a `__system_key_rotation__` fallback profile for orphan logs; review and reconcile these rows in long-term cleanup.
- Add tests for a full rotation apply and rollback simulation.
- Consider async decryption paths for large payload endpoints to reduce per-request latency.
