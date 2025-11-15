# Fedha Database Schema & Migration Review

**Date:** November 15, 2025  
**Purpose:** Comprehensive review of database schema, migrations, and recommendations for data privacy and analytics abstraction

---

## Table of Contents
1. [Current Schema Overview](#current-schema-overview)
2. [Data Privacy Assessment](#data-privacy-assessment)
3. [Analytics Abstraction Strategy](#analytics-abstraction-strategy)
4. [Migration Review](#migration-review)
5. [Recommended Schema Changes](#recommended-schema-changes)
6. [Implementation Roadmap](#implementation-roadmap)

---

## Current Schema Overview

### Core Tables (From 0001_initial.py)

#### Profile (User Accounts)
```
PK: id (CharField, 9 chars: X-XXXXXXX format - B/P prefix)
FK: -
Key Fields:
  - user_id (8-digit numeric, unique, for cross-device login)
  - name (display name, optional)
  - email (for notifications, optional)
  - profile_type (BIZ/PERS)
  - pin_hash (SHA-256 hashed PIN)
  - base_currency (KES default)
  - timezone (GMT+3 default)
  - is_active (soft delete flag)
  - created_at, last_login, last_modified
Indexes: profile_type, created_at, is_active, user_id, email
```

**Privacy Grade: B+**
- ✅ UUID-based PK prevents enumeration
- ✅ PIN-based auth (no passwords)
- ⚠️ Email stored in plaintext (should be encrypted)
- ⚠️ No field-level encryption for PII
- ✅ Soft delete flag prevents hard deletion issues

---

#### EnhancedTransaction (Financial Transactions)
```
PK: id (UUID)
FK: profile (CASCADE), category (SET_NULL), client (SET_NULL), invoice (SET_NULL)
    parent_transaction (self-referential, CASCADE)
    recurring_template (SET_NULL)
Key Fields:
  - amount, currency, exchange_rate
  - type (IN/EX/SAV/TR/ADJ)
  - payment_method (CASH/CARD/BANK/MOBILE/etc)
  - description, notes, reference_number
  - date (transaction date)
  - is_reconciled, is_tax_relevant, is_synced
  - receipt_url (plaintext URL)
  - client, invoice (links to business features)
  - parent_transaction (split transactions)
Indexes: (profile, date), (type, date), (category, date), (client, date), is_tax_relevant, is_reconciled
```

**Privacy Grade: C+**
- ✅ FK to profile (data is profile-scoped)
- ⚠️ Payment method details stored in plaintext (could identify payment patterns)
- ⚠️ Reference numbers could leak external system info
- ⚠️ Receipt URLs could be sensitive
- ⚠️ No encryption for sensitive transaction metadata

---

#### Category (Transaction Categories)
```
PK: id (UUID)
FK: profile (CASCADE, nullable - system defaults), parent (self-referential)
Key Fields:
  - name, type (INC/EXP/AST/LIA/EQT)
  - is_tax_deductible, tax_code
  - is_system_default
  - is_active, sort_order, description
Indexes: (profile, type), parent, is_system_default
Unique: (profile, name, parent)
```

**Privacy Grade: A**
- ✅ Minimal PII exposure
- ✅ Clear access control (profile-scoped)

---

#### Client (Business Contacts)
```
PK: id (UUID)
FK: profile (CASCADE)
Key Fields:
  - name, email, phone
  - address_line1/2, city, state_province, postal_code, country
  - credit_limit, payment_terms_days, discount_percentage
  - tax_id
  - currency, is_active
Indexes: (profile, is_active), name, email
Unique: (profile, email)
```

**Privacy Grade: C**
- ⚠️ PII stored in plaintext: emails, phone, addresses, names
- ⚠️ Tax ID exposed (sensitive for client privacy)
- ✅ Profile-scoped

---

#### Invoice (Business Invoicing)
```
PK: id (UUID)
FK: profile, client (SET_NULL), created_by (user, SET_NULL)
Key Fields:
  - invoice_number (unique), reference
  - issue_date, due_date, sent_date, payment_date
  - subtotal, tax_rate, tax_amount
  - discount_percentage, discount_amount, total_amount, paid_amount
  - notes, terms_and_conditions, footer_text
  - status (DRAFT/SENT/VIEWED/PARTIAL/PAID/OVERDUE/CANCELLED/REFUNDED)
  - currency, template_name
Indexes: (profile, issue_date), status
```

**Privacy Grade: B-**
- ⚠️ Client identification via FK
- ⚠️ Financial terms exposed in plaintext
- ✅ Dates help with analytics but could be obfuscated for privacy

---

#### Additional Tables (Key Models)

| Table | Privacy Grade | Concerns |
|-------|---------------|----------|
| **Asset** | B | Asset locations/details could be identifying |
| **Loan** | C | Account numbers, lender names expose external systems |
| **Goal** | B | Goal descriptions could be personal/sensitive |
| **Budget** | B | Budget amounts could reveal spending patterns |
| **Investment** | C | Investment types/amounts reveal financial behavior |
| **BankAccount** | C | Account numbers, bank routing info exposed |
| **Tax** | A | Tax records mostly codes/amounts (depends on fields) |
| **AuditLog** | B+ | Timestamps and action types are okay, but user_agent/IP could be PII |
| **FinancialRatio** | A | Calculated metrics, no PII |

---

## Data Privacy Assessment

### Current Privacy Issues (High Priority)

#### 1. **Plaintext PII Storage**
- **Issue:** Names, emails, phone numbers, addresses stored unencrypted
- **Risk:** Database breach exposes identifiable information
- **Severity:** 🔴 HIGH
- **Solution:** Field-level encryption for sensitive fields

#### 2. **Weak Access Control on Sensitive Data**
- **Issue:** No field-level permissions (Profile model)
- **Risk:** Admin users can view all profile data without audit
- **Severity:** 🔴 HIGH
- **Solution:** Implement row-level security, field-level audit logging

#### 3. **Payment Method & Reference Number Exposure**
- **Issue:** Transaction metadata (payment methods, reference numbers, receipt URLs) stored plaintext
- **Risk:** Can correlate transactions with external systems, identify payment patterns
- **Severity:** 🟠 MEDIUM
- **Solution:** Encrypt sensitive reference data, hash payment methods

#### 4. **Client Tax ID Exposure**
- **Issue:** Tax IDs stored unencrypted
- **Risk:** Tax IDs are highly sensitive (like SSN in some jurisdictions)
- **Severity:** 🟠 MEDIUM
- **Solution:** Encrypt or hash tax IDs, store only hash for lookups

#### 5. **Bank & Loan Account Details**
- **Issue:** Bank account numbers, routing numbers stored plaintext
- **Risk:** Direct access to account identifiers
- **Severity:** 🔴 HIGH
- **Solution:** Encrypt account numbers, use tokenization for lookups

#### 6. **Audit Log IP/User Agent**
- **Issue:** IP addresses and user agents stored without anonymization
- **Risk:** Can identify users across sessions
- **Severity:** 🟠 MEDIUM
- **Solution:** Hash IPs, anonymize user agents after 90 days

#### 7. **No Encryption Key Management**
- **Issue:** No mention of key rotation, key storage strategy
- **Risk:** Single master key compromise = total breach
- **Severity:** 🔴 HIGH
- **Solution:** Implement per-profile keys, key versioning, rotation policy

---

### Current Privacy Strengths

- ✅ **UUID-based primary keys** prevent direct enumeration
- ✅ **PIN-based authentication** (no password hashes to breach)
- ✅ **Soft deletes** (is_active flag) prevent data resurrection issues
- ✅ **Foreign key structure** naturally partitions data by profile
- ✅ **8-digit user IDs** + UUID dual approach adds privacy layer
- ✅ **Tax-specific fields** separated from transaction core

---

## Analytics Abstraction Strategy

### Goal: Enable Analytics Without Exposing Personal Data

### Approach 1: **Materialized Views** (Recommended)
Create summary tables that aggregate data before analytics access.

```sql
-- Example: Monthly spending by category (no transaction details)
CREATE TABLE analytic_monthly_category_summary (
    id: UUID
    profile_id: VARCHAR(9)              -- Anonymizable
    year: INTEGER
    month: INTEGER
    category_id: UUID
    category_name: VARCHAR(100)         -- Generic name only
    transaction_count: INTEGER
    total_amount: DECIMAL(15,2)
    base_currency: VARCHAR(3)
    created_at: TIMESTAMP
)
```

**Pros:**
- No raw transaction data exposed
- Pre-computed for performance
- Easy to exclude sensitive fields
- Data governance layer

**Cons:**
- Requires refresh logic
- Storage overhead
- Limited ad-hoc queries

---

### Approach 2: **Analytics Database Separation**
Separate read-only analytics database with anonymized data.

```
Production DB (Encrypted)           Analytics DB (Anonymized)
└─ Profile                          └─ profile_id_1000 (hashed)
└─ EnhancedTransaction              └─ trans_001, trans_002...
└─ Client                           └─ category summaries
└─ Invoice                          └─ aggregated reports
```

**Pros:**
- Complete separation of concerns
- Safe for data science teams
- Easier compliance (GDPR/CCPA)
- Can implement differential privacy

**Cons:**
- Increased infrastructure
- Sync complexity
- Potential data staleness

---

### Approach 3: **Differential Privacy** (Advanced)
Add statistical noise to aggregated results to prevent individual identification.

```
Real: Profile X spent KES 50,000 on Transport
  ↓ (add Laplace noise: noise ~ Laplace(0, scale=5000))
Report: Profile X spent KES 47,234 ± 5,000 on Transport
```

**Pros:**
- Mathematically proven privacy
- Useful for public reports
- Enables "safe" data sharing

**Cons:**
- Reduces query accuracy
- Complex to implement
- Hard to explain to users

---

### Recommended Analytics Tables

```python
# 1. Profile Aggregate Stats (No PII)
ProfileAnalyticsSnapshot:
  - profile_id_hash
  - account_type (BIZ/PERS, not name)
  - currency
  - total_transaction_count
  - date_range
  - cohort (signup month)
  - is_active
  - last_activity_date

# 2. Category Spending Patterns (Anonymous)
CategoryAnalyticsMonthly:
  - profile_id_hash (hashed, not actual ID)
  - year, month
  - category_name
  - transaction_count
  - total_amount
  - average_transaction
  - trend (vs prev month)

# 3. Payment Method Distribution
PaymentMethodAnalytics:
  - profile_id_hash
  - payment_method (hashed)
  - count
  - total_amount
  - percentage_of_total

# 4. Cohort Analysis
CohortRetention:
  - signup_month
  - signup_year
  - months_since_signup
  - active_users
  - transaction_volume
  - average_transaction_size

# 5. User Behavior (Non-PII)
BehaviorMetrics:
  - profile_id_hash
  - feature_usage (categories enabled, invoice count, etc.)
  - session_duration_avg
  - transactions_per_week
  - reconciliation_rate
  - data_quality_score
```

---

## Migration Review

### Completed Migrations

#### Migration 0001_initial.py ✅
- **Status:** Created comprehensive schema
- **Coverage:** ~25 tables including Profile, Transaction, Invoice, Category, etc.
- **Issues Identified:**
  - No encryption specified
  - No field-level access control
  - PII stored in plaintext

#### Migration 0002_enhance_profile_with_user_id.py ✅
- **Status:** Added user_id field and email field
- **Changes:**
  - `user_id` CharField(8) unique - for cross-device login
  - `email` EmailField - for notifications
  - Updated Profile.id from UUID to CharField(9) - B/P-XXXXXXX format
  - Added indexes on user_id and email
- **Issues:**
  - No encryption for email
  - user_id is sequential-ish (could be enumerable)

#### Migration 0003_rename_api_profile_user_id_idx.py
- **Status:** Index rename/optimization
- **Purpose:** Likely normalized index names

#### Migration 0004_alter_enhancedtransaction_type_and_more.py
- **Status:** Transaction type changes
- **Likely:** Type field enum updates

---

### Recommended Additional Migrations

#### Migration 0005_add_encryption_fields.py (PRIORITY)
```python
# Add encrypted field versions
migrations.AddField(
    model_name='profile',
    name='email_encrypted',
    field=models.BinaryField(null=True, blank=True),
)
migrations.AddField(
    model_name='profile',
    name='email_encryption_version',
    field=models.PositiveIntegerField(default=1),
)

# Add for Client model
migrations.AddField(
    model_name='client',
    name='phone_encrypted',
    field=models.BinaryField(null=True, blank=True),
)
migrations.AddField(
    model_name='client',
    name='tax_id_encrypted',
    field=models.BinaryField(null=True, blank=True),
)

# Add for Transaction model
migrations.AddField(
    model_name='enhancedtransaction',
    name='reference_number_encrypted',
    field=models.BinaryField(null=True, blank=True),
)
```

#### Migration 0006_create_analytics_tables.py (PHASE 2)
```python
# Create materialized analytics tables
migrations.CreateModel(
    name='ProfileAnalyticsSnapshot',
    fields=[
        ('id', models.UUIDField(primary_key=True, ...)),
        ('profile_id_hash', models.CharField(max_length=64, db_index=True)),
        ('account_type', models.CharField(max_length=4)),
        ('total_transaction_count', models.PositiveIntegerField()),
        ('created_at', models.DateTimeField(auto_now_add=True)),
    ],
)

# Similar for CategoryAnalyticsMonthly, etc.
```

#### Migration 0007_add_encryption_at_rest.py (PHASE 2)
```python
# Add hash fields for audit trail comparison
migrations.AddField(
    model_name='auditlog',
    name='field_changes_hash',
    field=models.CharField(max_length=64, blank=True),
)
# Add encryption key tracking
migrations.CreateModel(
    name='EncryptionKeyVersion',
    fields=[
        ('id', models.UUIDField(primary_key=True, ...)),
        ('version', models.PositiveIntegerField()),
        ('algorithm', models.CharField(max_length=20)),
        ('key_fingerprint', models.CharField(max_length=64)),
        ('created_at', models.DateTimeField(auto_now_add=True)),
        ('is_active', models.BooleanField(default=True)),
    ],
)
```

#### Migration 0008_add_audit_extensions.py (PHASE 3)
```python
# Enhance AuditLog for compliance
migrations.AddField(
    model_name='auditlog',
    name='data_classification',
    field=models.CharField(
        max_length=10,
        choices=[('PUBLIC', 'Public'), ('INTERNAL', 'Internal'), ('CONFIDENTIAL', 'Confidential'), ('RESTRICTED', 'Restricted')],
        default='INTERNAL'
    ),
)
migrations.AddField(
    model_name='auditlog',
    name='consent_required',
    field=models.BooleanField(default=False),
)
migrations.AddField(
    model_name='auditlog',
    name='right_to_access_claim',
    field=models.BooleanField(default=False),
)
```

---

## Recommended Schema Changes

### 1. **Add Encryption Metadata**

```python
# In models.py - new EncryptionKey model
class EncryptionKeyVersion(models.Model):
    """Track encryption key versions for re-encryption."""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4)
    profile = models.ForeignKey(Profile, on_delete=models.CASCADE, null=True, blank=True)
    version = models.PositiveIntegerField()
    algorithm = models.CharField(max_length=20)  # e.g., 'AES-256-GCM'
    key_fingerprint = models.CharField(max_length=64)  # SHA256 of public key
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField(null=True, blank=True)
    is_active = models.BooleanField(default=True)
    is_master_key = models.BooleanField(default=False)
    
    class Meta:
        unique_together = [['profile', 'version']]
        ordering = ['-version']
```

### 2. **Add Data Classification**

```python
class DataClassification(models.Model):
    """Mark data sensitivity level for compliance."""
    MODEL_CHOICES = [
        ('profile', 'Profile'),
        ('transaction', 'Transaction'),
        ('client', 'Client'),
        ('invoice', 'Invoice'),
    ]
    SENSITIVITY_CHOICES = [
        ('PUBLIC', 'Public'),
        ('INTERNAL', 'Internal'),
        ('CONFIDENTIAL', 'Confidential'),
        ('RESTRICTED', 'Restricted'),
    ]
    
    model_name = models.CharField(max_length=50, choices=MODEL_CHOICES)
    field_name = models.CharField(max_length=100)
    sensitivity = models.CharField(max_length=12, choices=SENSITIVITY_CHOICES)
    requires_encryption = models.BooleanField(default=False)
    requires_anonymization = models.BooleanField(default=False)
    pii_category = models.CharField(max_length=50, blank=True)  # e.g., 'email', 'phone', 'tax_id'
```

### 3. **Add Consent Tracking**

```python
class ConsentRecord(models.Model):
    """Track user consent for data processing."""
    CONSENT_CHOICES = [
        ('MARKETING', 'Marketing Communications'),
        ('ANALYTICS', 'Analytics & Usage'),
        ('THIRD_PARTY', 'Third-party Sharing'),
        ('PROFILING', 'Profiling & Recommendations'),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4)
    profile = models.ForeignKey(Profile, on_delete=models.CASCADE)
    consent_type = models.CharField(max_length=20, choices=CONSENT_CHOICES)
    given = models.BooleanField()
    given_at = models.DateTimeField()
    ip_address = models.GenericIPAddressField(null=True)  # Will hash later
    user_agent_hash = models.CharField(max_length=64, blank=True)
    
    class Meta:
        unique_together = [['profile', 'consent_type']]
        ordering = ['-given_at']
```

### 4. **Add Data Retention Policy**

```python
class DataRetentionPolicy(models.Model):
    """Define how long different data types are retained."""
    DATA_TYPE_CHOICES = [
        ('TRANSACTION', 'Transaction Records'),
        ('AUDIT_LOG', 'Audit Logs'),
        ('SESSION', 'Session Data'),
        ('BACKUP', 'Backups'),
        ('ANALYTICS', 'Analytics Summaries'),
    ]
    
    data_type = models.CharField(max_length=20, choices=DATA_TYPE_CHOICES, unique=True)
    retention_days = models.PositiveIntegerField()
    allow_archive = models.BooleanField(default=True)
    allow_anonymization = models.BooleanField(default=True)
    notes = models.TextField(blank=True)
```

### 5. **Enhance AuditLog for GDPR/CCPA**

```python
# Add to AuditLog model
class AuditLog(models.Model):
    # ... existing fields ...
    
    # Data processing metadata
    legal_basis = models.CharField(
        max_length=20,
        choices=[
            ('CONSENT', 'User Consent'),
            ('CONTRACT', 'Contractual Necessity'),
            ('LEGAL_OBLIGATION', 'Legal Obligation'),
            ('VITAL_INTEREST', 'Vital Interest'),
            ('PUBLIC_TASK', 'Public Task'),
            ('LEGITIMATE_INTEREST', 'Legitimate Interest'),
        ],
        null=True, blank=True
    )
    right_to_access_claim = models.BooleanField(default=False)
    right_to_erasure_claim = models.BooleanField(default=False)
    right_to_rectification_claim = models.BooleanField(default=False)
    consent_withdrawn = models.BooleanField(default=False)
    
    # Encryption tracking
    encryption_version = models.ForeignKey(
        'EncryptionKeyVersion',
        on_delete=models.SET_NULL,
        null=True, blank=True
    )
    is_encrypted = models.BooleanField(default=False)
```

---

## Implementation Roadmap

### Phase 1: **Privacy Foundation** (Weeks 1-4)
**Goal:** Secure sensitive data at rest

- [ ] Implement field-level encryption utilities
- [ ] Create migration 0005_add_encryption_fields.py
- [ ] Add encryption middleware/context processor
- [ ] Create EncryptionKeyVersion model & migration
- [ ] Implement key rotation strategy
- [ ] Add encrypted field descriptors to Profile, Client, EnhancedTransaction
- [ ] **Testing:** Verify encrypted data cannot be read without key

### Phase 2: **Analytics Abstraction** (Weeks 5-8)
**Goal:** Enable analytics without exposing PII

- [ ] Create analytics models (ProfileAnalyticsSnapshot, etc.)
- [ ] Implement materialized view refresh logic
- [ ] Add ProfileAnalyticsSnapshot generation (daily cronjob)
- [ ] Create analytics query service (read-only)
- [ ] Build dashboard with aggregated metrics only
- [ ] **Testing:** Verify no PII in analytics queries

### Phase 3: **Audit & Compliance** (Weeks 9-12)
**Goal:** Meet regulatory requirements

- [ ] Enhance AuditLog with legal basis tracking
- [ ] Implement right-to-access data export (JSON/CSV)
- [ ] Implement right-to-erasure cascade logic
- [ ] Add ConsentRecord model & migration
- [ ] Create consent management API
- [ ] Implement audit trail encryption
- [ ] **Testing:** Verify GDPR/CCPA compliance

### Phase 4: **Access Control** (Weeks 13-16)
**Goal:** Implement row-level security

- [ ] Add row-level security decorator/middleware
- [ ] Implement field-level permissions
- [ ] Create admin audit dashboard
- [ ] Add API permission checks
- [ ] Implement rate limiting for sensitive endpoints
- [ ] **Testing:** Verify users cannot access other users' data

---

## Quick Reference: Privacy Implementation Checklist

### Database Level
- [ ] Field-level encryption for: email, phone, address, tax_id, account_numbers
- [ ] Encryption key versioning
- [ ] Key rotation policy (quarterly minimum)
- [ ] Separate encryption keys per profile
- [ ] Master key in secure vault (AWS KMS, HashiCorp Vault)

### Application Level
- [ ] Encryption middleware for inbound/outbound data
- [ ] Field-level access control (only owner + admins can view)
- [ ] Audit logging for all data access
- [ ] Right-to-access export functionality
- [ ] Right-to-erasure with cascade cleanup
- [ ] Consent tracking before data collection

### Analytics Level
- [ ] Materialized analytics tables (no raw data)
- [ ] Profile ID hashing in analytics
- [ ] Anonymization for reports
- [ ] Differential privacy for public reports
- [ ] Separate analytics database (read-only copy)

### Compliance Level
- [ ] Data retention policy enforcement
- [ ] Automated data purging after retention expires
- [ ] GDPR/CCPA compliance audit trail
- [ ] Terms of service updated with privacy policies
- [ ] Data processing agreements signed

### Testing Level
- [ ] Encryption/decryption tests
- [ ] Access control tests
- [ ] Data export tests
- [ ] Audit logging tests
- [ ] Retention policy tests

---

## Conclusion

**Current State:** The database schema has a solid foundation with profile-scoped data architecture and UUID-based privacy. However, PII is stored in plaintext and analytics capabilities are limited.

**Recommended Path:** 
1. **Immediate (Phase 1):** Add field-level encryption for sensitive PII
2. **Short-term (Phase 2):** Implement analytics abstraction layer
3. **Medium-term (Phase 3):** Full GDPR/CCPA compliance
4. **Long-term (Phase 4):** Advanced access control and differential privacy

**Key Success Metrics:**
- ✅ Zero plaintext PII in database
- ✅ All analytics queries anonymized
- ✅ 100% audit trail coverage
- ✅ Automated compliance reporting
- ✅ <1s encryption/decryption overhead

---

## Next Steps

1. **Review & Approve:** Stakeholder review of privacy strategy
2. **Implementation Sprint:** Begin Phase 1 migrations
3. **Security Audit:** External security review of encryption implementation
4. **Compliance Review:** Legal review of GDPR/CCPA measures
5. **User Communication:** Notify users of privacy enhancements
