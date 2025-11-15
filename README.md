# Fedha – Personal Finance Tracker

Fedha is a cross-platform (iOS, Android, Web, Desktop) personal finance app with:
- Offline-first storage (Hive)
- Secure authentication (password + biometric)
- SMS transaction ingestion (Android native + iOS fallback)
- Advanced loan & APR calculators
- Budget, goal, and multi-currency support

## 🚀 Quick Start

Prerequisites:
- Flutter SDK ≥3.7
- Dart SDK (bundled with Flutter)
- Python ≥3.8 for backend
- Node.js ≥16 for web (optional)
- Git

### 1. Clone & Setup
```bash
git clone https://github.com/moffat-kagiri/fedha.git
cd fedha/app
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### 2. Android/iOS 
```bash
flutter run -d android   # or -d ios on macOS
```

### 3. Web (optional)
```bash
cd ../web && npm install && npm start
```

### 4. Backend (Django)
```bash
cd ../backend
python -m venv .venv && .venv/Scripts/activate
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver
```

#### Production KMS / Master Key (backend)

For production deployments you should use a KMS or secrets service instead of embedding the master key in the environment or code. Example environment variables (set in your host/CI/containers):

PowerShell example (Windows):
```powershell
$env:KMS_PROVIDER = 'aws-secrets-manager'
$env:AWS_SECRET_NAME = 'fedha/encryption/master-key'
$env:AWS_REGION = 'us-east-1'
```

Bash example (Linux/macOS):
```bash
export KMS_PROVIDER=aws-secrets-manager
export AWS_SECRET_NAME=fedha/encryption/master-key
export AWS_REGION=us-east-1
```

If you are using HashiCorp Vault:
```bash
export KMS_PROVIDER=vault
export VAULT_ADDR=https://vault.example.com:8200
export VAULT_TOKEN=<vault-token>
export VAULT_SECRET_PATH=secret/fedha/encryption/master-key
```

Bootstrap master key (optional):
After configuring the adapter and before serving traffic, you can ensure a master key exists by running:

```powershell
# Windows PowerShell
cd c:\GitHub\fedha\backend
$env:KMS_PROVIDER='aws-secrets-manager'  # or 'vault' or 'env'
python manage.py bootstrap_master_key --create
```

Notes:
- In production prefer manually provisioning the key in Secrets Manager or Vault and pointing the app to it.
- `--create` will attempt to store a generated key in the configured adapter — use with care in production.

## Android Permissions

Be sure your AndroidManifest.xml includes:

```bash
<uses-permission android:name="android.permission.READ_SMS" />
<uses-permission android:name="android.permission.RECEIVE_SMS" />
```

## 🗂️ Project Structure

```txt
fedha/
├─ app/           Flutter mobile & desktop
├─ backend/       Django REST API
├─ web/           React web frontend
└─ docs/          Guides, [ROADMAP.md](http://_vscodecontentref_/3)
```

## ✔️ Current Status (backend highlights)

- Core features (auth, CRUD, sync, loan calculator) – ✅ Done
- SMS ingestion (Android) – ✅ Done
- SMS ingestion (iOS fallback UI) – ⚠️ Incomplete, needs wiring
- Biometric auth flow – ✅ Done

Recent backend & security work (Nov 2025):

- Field-level encryption added for PII (AES-256-GCM) with per-profile key derivation.
- Key management models and migrations (key versions, rotation logs) applied.
- Key rotation orchestration and management command: `rotate_encryption_keys`.
- Monitoring command: `monitor_encryption` to report key health and coverage.
- KMS adapter implemented (`backend/api/utils/kms_adapter.py`) with support for:
	- `env` (development), `aws-secrets-manager`, `aws-kms`, and `vault` providers.
- Runtime wiring: `KeyManager` now retrieves master key via the adapter; `KeyBootstrap` helper + `bootstrap_master_key` command added.
- A safe bootstrap guard was added: auto-creation of master keys is blocked unless `ALLOW_AUTO_CREATE_MASTER=yes` is set in environment.
- `encrypt_existing_pii` management command for zero-downtime plaintext→encrypted migration (dry-run supported).
- Migrations were corrected and a backfill migration added to make `KeyRotationLog.profile` non-nullable safely.
- Unit tests added for rotation/monitoring; CI workflow added at `.github/workflows/ci.yml` to run checks and tests on PRs.

Start server helpers

- `start_server.py` supports automated steps (migrations, checks), and new flags to bootstrap keys and run encryption migration:
	- `--ensure-master-key` and `--create-master-key` (requires `ALLOW_AUTO_CREATE_MASTER=yes` to create)
	- `--encrypt-existing`, `--encrypt-dry-run`, `--encrypt-limit`, `--encrypt-batch-size`

Local quick commands (PowerShell):

```powershell
# Run system checks
cd c:\GitHub\fedha\backend
python manage.py check

# Ensure master key (safe: will NOT create unless ALLOW_AUTO_CREATE_MASTER is set)
python manage.py bootstrap_master_key

# To allow auto-creation in a controlled environment:
$env:ALLOW_AUTO_CREATE_MASTER = 'yes'
python manage.py bootstrap_master_key --create

# Start server and bootstrap key automatically (create only if ALLOW_AUTO_CREATE_MASTER is set):
python ..\backend\start_server.py --ensure-master-key --create-master-key
```

If you need a hand preparing a production KMS rollout or a PR for these security changes, I can draft the PR and the deployment checklist.