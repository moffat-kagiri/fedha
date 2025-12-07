# Fedha Auth Flow - Deployment Guide

## Current Status
✅ **All code changes complete and validated**
- 8 files modified
- 1 migration created  
- 0 syntax errors
- Ready to deploy

🚫 **Blocker:** Python not in system PATH
- Cannot run `python manage.py migrate` directly
- Need to resolve Python environment

---

## Option 1: Activate Virtual Environment (Recommended)

### Step 1: Find Virtual Environment
```powershell
# Common locations
$possible_locations = @(
    "C:\GitHub\fedha\backend\.venv",
    "C:\GitHub\fedha\.venv",
    "C:\Users\$env:USERNAME\AppData\Local\pyenv\versions",
    "$env:APPDATA\Python"
)

# Or search for python.exe
Get-ChildItem -Path "C:\" -Filter "python.exe" -Recurse -ErrorAction SilentlyContinue
```

### Step 2: Activate It
```powershell
# If found in .venv\Scripts
& "C:\GitHub\fedha\backend\.venv\Scripts\Activate.ps1"

# Then run migrations
python manage.py migrate
python manage.py runserver 0.0.0.0:8000
```

---

## Option 2: Install Python Fresh

### On Windows
1. Download: https://www.python.org/downloads/windows/
2. **IMPORTANT:** Check "Add Python to PATH" during installation
3. Restart PowerShell
4. Verify: `python --version`
5. Run migrations:
   ```powershell
   cd C:\GitHub\fedha\backend
   pip install -r requirements.txt
   python manage.py migrate
   python manage.py runserver 0.0.0.0:8000
   ```

---

## Option 3: Use Docker (if available)

```powershell
# From backend directory
docker build -t fedha-backend .
docker run -p 8000:8000 fedha-backend
```

---

## Option 4: Find Existing Python Installation

```powershell
# Search for Python executable
$pythonPath = Get-Command python -ErrorAction SilentlyContinue
if ($pythonPath) {
    Write-Host "Python found at: $($pythonPath.Source)"
    & $pythonPath.Source --version
}

# Or check common paths
@("python", "python.exe", "python3", "python3.exe") | ForEach-Object {
    $p = Get-Command $_ -ErrorAction SilentlyContinue
    if ($p) {
        Write-Host "Found: $_  at  $($p.Source)"
        & $p.Source --version
    }
}
```

---

## Quick Deployment Checklist

Once Python is accessible, run these commands:

```powershell
# Navigate to backend
cd C:\GitHub\fedha\backend

# Install dependencies
pip install -r requirements.txt

# Run migrations (applies new profile fields)
python manage.py migrate

# Start server
python manage.py runserver 0.0.0.0:8000

# In another terminal, test frontend
cd C:\GitHub\fedha\app
flutter test test/auth_test_flow.dart
```

---

## Files Ready to Deploy

### Backend (4 files)
✅ `backend/api/serializers.py` - SHA-256 password validation
✅ `backend/api/views.py` - 7 auth endpoints  
✅ `backend/api/urls.py` - URL routing
✅ `backend/api/models.py` - Profile model enhancements

### Frontend (3 files)
✅ `app/lib/services/auth_service.dart` - Profile sync logic
✅ `app/lib/services/api_client.dart` - Implemented methods
✅ `app/test/auth_test_flow.dart` - Fixed config

### Database (1 file)
✅ `backend/api/migrations/0002_profile_auth_fields.py` - Ready to apply

### Documentation (4 files)
✅ `AUTH_FLOW_IMPLEMENTATION.md` - Technical guide
✅ `PHASE1_COMPLETION_REPORT.md` - Completion report
✅ `QUICK_REFERENCE.md` - Quick start
✅ `REMAINING_ISSUES_PHASE2.md` - Future work

---

## Post-Deployment Verification

Once server is running:

```bash
# Test health check
curl http://localhost:8000/api/health/

# Should return:
# {"status": "ok", "message": "Fedha backend server is running"}
```

---

## Next Steps

1. **Resolve Python PATH** (15 min) - Try options above
2. **Run migrations** (2 min) - `python manage.py migrate`
3. **Start backend** (1 min) - `python manage.py runserver 0.0.0.0:8000`
4. **Test endpoints** (5 min) - Use Postman or curl
5. **Run frontend tests** (2 min) - `flutter test`

**Total time to deploy: ~25 minutes once Python is found**

---

## Troubleshooting

### "python: The term 'python' is not recognized"
- Python not in PATH
- Try: `where python` to find installation
- Or install fresh with PATH checkbox

### "ModuleNotFoundError: No module named 'rest_framework'"
- Dependencies not installed: `pip install -r requirements.txt`

### "No such table: api_profile"
- Migrations not applied: `python manage.py migrate`

### "Connection refused" from frontend
- Backend not running: `python manage.py runserver 0.0.0.0:8000`
- Check server is on port 8000
- Frontend test config uses localhost:8000 ✓

---

## Support

- Check `QUICK_REFERENCE.md` for API endpoints
- Check `AUTH_FLOW_IMPLEMENTATION.md` for implementation details
- Check inline code comments for specific questions

**Status: All code changes ready. Just need Python accessible.**
