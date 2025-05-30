# Pre-commit check script for Windows PowerShell
# Run this script before committing code changes

Write-Host "🔍 Running pre-commit checks..." -ForegroundColor Yellow

# Check if we're in the backend directory
if (-not (Test-Path "manage.py")) {
    Write-Host "❌ Error: Run this script from the backend directory" -ForegroundColor Red
    exit 1
}

# Initialize error flag
$errors = 0

# 1. Check Django models
Write-Host "`n📋 Checking Django models..." -ForegroundColor Yellow
try {
    $result = python manage.py check --quiet 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Django check passed" -ForegroundColor Green
    } else {
        Write-Host "❌ Django check failed" -ForegroundColor Red
        Write-Host $result -ForegroundColor Red
        $errors = 1
    }
} catch {
    Write-Host "❌ Error running Django check: $_" -ForegroundColor Red
    $errors = 1
}

# 2. Check for migration issues
Write-Host "`n🔄 Checking for pending migrations..." -ForegroundColor Yellow
try {
    $result = python manage.py makemigrations --dry-run --check 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ No pending migrations" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Pending migrations detected" -ForegroundColor Yellow
        python manage.py makemigrations --dry-run
    }
} catch {
    Write-Host "❌ Error checking migrations: $_" -ForegroundColor Red
}

# 3. Run Python syntax check
Write-Host "`n🐍 Checking Python syntax..." -ForegroundColor Yellow
$files = @("api\models.py", "api\views.py", "api\serializers.py")
$syntaxOk = $true

foreach ($file in $files) {
    if (Test-Path $file) {
        try {
            python -m py_compile $file 2>&1 | Out-Null
            if ($LASTEXITCODE -ne 0) {
                Write-Host "❌ Syntax error in $file" -ForegroundColor Red
                $syntaxOk = $false
                $errors = 1
            }
        } catch {
            Write-Host "❌ Error checking syntax in $file" -ForegroundColor Red
            $syntaxOk = $false
            $errors = 1
        }
    }
}

if ($syntaxOk) {
    Write-Host "✅ Python syntax check passed" -ForegroundColor Green
}

# 4. Format code with Black (if available)
$blackPath = Get-Command black -ErrorAction SilentlyContinue
if ($blackPath) {
    Write-Host "`n🎨 Checking code formatting with Black..." -ForegroundColor Yellow
    try {
        black --check --diff api\ 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Code formatting looks good" -ForegroundColor Green
        } else {
            Write-Host "⚠️ Code formatting issues found. Run 'black api\' to fix" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "⚠️ Error running Black" -ForegroundColor Yellow
    }
} else {
    Write-Host "`n⚠️ Black not installed. Install with: pip install black" -ForegroundColor Yellow
}

# 5. Sort imports with isort (if available)
$isortPath = Get-Command isort -ErrorAction SilentlyContinue
if ($isortPath) {
    Write-Host "`n📝 Checking import sorting..." -ForegroundColor Yellow
    try {
        isort --check-only --diff api\ 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Import sorting looks good" -ForegroundColor Green
        } else {
            Write-Host "⚠️ Import sorting issues found. Run 'isort api\' to fix" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "⚠️ Error running isort" -ForegroundColor Yellow
    }
} else {
    Write-Host "`n⚠️ isort not installed. Install with: pip install isort" -ForegroundColor Yellow
}

# 6. Run flake8 linting (if available)
$flake8Path = Get-Command flake8 -ErrorAction SilentlyContinue
if ($flake8Path) {
    Write-Host "`n🔍 Running flake8 linting..." -ForegroundColor Yellow
    try {
        flake8 api\ 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Linting passed" -ForegroundColor Green
        } else {
            Write-Host "⚠️ Linting issues found" -ForegroundColor Yellow
            flake8 api\
        }
    } catch {
        Write-Host "⚠️ Error running flake8" -ForegroundColor Yellow
    }
} else {
    Write-Host "`n⚠️ flake8 not installed. Install with: pip install flake8" -ForegroundColor Yellow
}

# Summary
Write-Host "`n📊 Summary:" -ForegroundColor Yellow
if ($errors -eq 0) {
    Write-Host "✅ All critical checks passed!" -ForegroundColor Green
    Write-Host "🚀 Ready for commit" -ForegroundColor Green
} else {
    Write-Host "❌ Some critical checks failed" -ForegroundColor Red
    Write-Host "🛑 Please fix errors before committing" -ForegroundColor Red
}

exit $errors
