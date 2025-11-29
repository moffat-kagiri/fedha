# Encryption Migration Checklist

Production-ready workflow for migrating existing plaintext PII to encrypted fields with zero downtime.

## Pre-Migration (Day -1)

- [ ] **Backup Database**
  ```bash
  # Linux/Mac
  sqlite3 db.sqlite3 ".backup db.sqlite3.backup.$(date +%s)"
  
  # Windows PowerShell
  Copy-Item db.sqlite3 "db.sqlite3.backup.$(Get-Date -f yyyyMMdd_HHmmss)"
  ```

- [ ] **Generate & Secure Master Key**
  ```bash
  # Generate 32-byte (256-bit) random key, encode as base64
  openssl rand -base64 32
  
  # Or Python:
  python -c "import secrets; print(secrets.token_urlsafe(32))"
  ```
  Store securely in:
  - `.env` file (dev): `MASTER_ENCRYPTION_KEY=<key>`
  - Secret manager (prod): AWS Secrets Manager / HashiCorp Vault / GCP Secret Manager
  - DO NOT commit to version control

- [ ] **Test Key in Staging Environment**
  - Deploy to staging with `MASTER_ENCRYPTION_KEY` set
  - Run `python manage.py check` to verify system startup
  - Proceed only if system checks pass

## Day 0: Migration Execution

### Step 1: Run Dry-Run (Low Risk)
```bash
python manage.py migrate api 0006  # Apply encrypted field schema
python manage.py encrypt_existing_pii --dry-run --limit 100
```
**Expected Output**:
```
Starting encryption of existing PII (DRY RUN)...
Batch 1: Processing 100 Profile objects...
[DRY RUN] Would encrypt 87 profiles (13 already encrypted)
```
**Verify**:
- No errors in output
- Plaintext fields still readable via Django shell

### Step 2: Small Batch Migration (Sample Verification)
```bash
python manage.py encrypt_existing_pii --limit 100 --batch-size 10
```
**Expected Output**:
```
Batch 1: Processing 10 Profile objects... OK
Batch 2: Processing 10 Profile objects... OK
...
Completed: Encrypted 100 Profile objects
```
**Verify in Django shell**:
```python
python manage.py shell
>>> from api.models import Profile
>>> p = Profile.objects.first()
>>> print(p.name)  # Should output plaintext (decrypted from encrypted field)
>>> print(p.name_encrypted)  # Should contain base64 ciphertext
```

### Step 3: Verify Decryption
```bash
python manage.py encrypt_existing_pii --verify --sample-size 20
```
**Expected Output**:
```
Verifying decryption on 20 profiles...
✓ All 20 profiles decrypted successfully
```

### Step 4: Full Production Migration
```bash
python manage.py encrypt_existing_pii --batch-size 100
```
Monitor output for errors. If issues arise:
- **Stop immediately** (`Ctrl+C`)
- **Rollback** (restore from backup, or manually reset encrypted fields)
- **Debug** (check error logs, verify MASTER_ENCRYPTION_KEY)

**Expected Progress**:
```
Batch 1: Processing 100 Profile objects... OK
Batch 2: Processing 100 Profile objects... OK
...
Total: 1250 profiles encrypted in 12.5s
```

## Day 1: Post-Migration Validation

### Step 1: Verify Encryption Coverage
```bash
python manage.py monitor_encryption
```
**Expected Output**:
```
Encryption Health Monitor

Key Expiration Status:
  ✓ No keys expiring soon

Encryption Coverage:
  Profile.name: 1250/1250 (100.0%)
  Client.name: 487/487 (100.0%)
  EnhancedTransaction.reference: 892/892 (100.0%)
  Loan.account_number: 45/45 (100.0%)

Key Rotation Status:
  ✓ No pending rotations
```

### Step 2: API Read Verification
Test API endpoints return **plaintext** (decrypted) values:
```bash
curl -H "Authorization: Bearer $TOKEN" http://localhost:8000/api/profiles/
# Response should show: {"name": "John Doe", "email": "john@example.com", ...}
# NOT encrypted values
```

### Step 3: API Write Verification
Test API create/update auto-encrypts on write:
```bash
curl -X POST http://localhost:8000/api/profiles/ \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name": "Jane Doe", "email": "jane@example.com"}'

# Verify in Django shell:
>>> from api.models import Profile
>>> p = Profile.objects.filter(name="Jane Doe").first()
>>> print(p.name)  # Plaintext: "Jane Doe"
>>> print(p.name_encrypted[:20])  # Ciphertext: "eyJ...AAA="
```

### Step 4: Smoke Test with Real Workload
- Run 30 minutes of normal application usage
- Monitor for any decryption errors in logs
- Check response times (encryption/decryption adds ~5-10ms overhead per field)

## Rollback Plan (If Issues Arise)

### Option A: Restore from Backup (Complete Rollback)
```bash
# Stop server
# Restore DB
cp db.sqlite3.backup.* db.sqlite3
# Clear any MASTER_ENCRYPTION_KEY env var
unset MASTER_ENCRYPTION_KEY  # Linux/Mac
# Restart server
python start_server.py
```

### Option B: Partial Rollback (Specific Profile)
```bash
# Decrypt a single profile's data back to plaintext:
python manage.py shell
>>> from api.models import Profile
>>> p = Profile.objects.get(id=123)
>>> p.name = p.decrypt_field('name')
>>> p.name_encrypted = None
>>> p.save()
```

## Key Rotation Schedule (After Migration)

Once encryption is live, establish key rotation schedule:

### Every 90 Days: Scheduled Rotation
```bash
python manage.py rotate_encryption_keys --reason SCHEDULED --verify-sample 50
```

### On Security Incident: Emergency Rotation
```bash
python manage.py rotate_encryption_keys --reason COMPROMISE --verify-sample 100
```

### Monitor Key Health (Weekly)
```bash
python manage.py monitor_encryption --warn-days 30
```

## Production Environment Configuration

### AWS Secrets Manager Integration (KMS-backed master key)
See `KMS_INTEGRATION_GUIDE.md` for setup.

### HashiCorp Vault Integration
See `KMS_INTEGRATION_GUIDE.md` for setup.

## Troubleshooting

| Error | Cause | Solution |
|-------|-------|----------|
| `MASTER_ENCRYPTION_KEY not set` | Missing env var | Set `export MASTER_ENCRYPTION_KEY=...` |
| `Decryption failed: Authentication tag invalid` | Wrong master key or corrupted ciphertext | Restore backup, use original key |
| `serializers.ValidationError: Invalid JSON` | Corrupted encrypted field | Restore backup, rerun migration |
| `Slow API responses (>500ms)` | Encryption overhead on large batches | Profile encryption perf; consider async decryption for large payloads |

## Post-Migration Maintenance

### Monthly Audit
```bash
python manage.py shell
>>> from api.models import Profile, EncryptionKeyVersion
>>> print(f"Total profiles: {Profile.objects.count()}")
>>> print(f"Active keys: {EncryptionKeyVersion.objects.filter(is_active=True).count()}")
>>> print(f"Encryption version: {Profile.objects.first().encryption_version}")
```

### Quarterly Key Expiration Review
```bash
python manage.py monitor_encryption --warn-days 90
```

---

**Success Criteria**:
- ✓ All PII fields encrypted (100% coverage)
- ✓ API returns plaintext values (transparent decryption)
- ✓ No decryption errors in logs
- ✓ API response time <200ms (no encryption slowdown)
- ✓ Master key stored securely (not in repo, .env, or logs)
