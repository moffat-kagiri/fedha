# PowerShell script to create test profiles in Fedha app

# Change to the app directory
Set-Location $PSScriptRoot

# Add log header
Write-Host "===== FEDHA TEST PROFILES CREATOR ====="
Write-Host "Creating test profiles for the Fedha app..."
Write-Host ""

# Run the Flutter tool
flutter run --no-hot test_profiles_tool.dart

# Provide instructions after completion
Write-Host ""
Write-Host "If profiles were created successfully, you can now run the main app:"
Write-Host "flutter run"
