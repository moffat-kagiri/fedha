# Fix withOpacity deprecations
$files = @(
    "lib\screens\add_goal_screen.dart",
    "lib\screens\add_transaction_screen.dart",
    "lib\screens\biometric_lock_screen.dart",
    "lib\screens\biometric_setup_screen.dart",
    "lib\screens\budget_management_screen.dart",
    "lib\screens\change_password_screen.dart",
    "lib\screens\create_budget_screen.dart",
    "lib\screens\currency_converter_screen.dart",
    "lib\screens\dashboard_screen.dart",
    "lib\screens\goal_detail_screen.dart",
    "lib\screens\goals_screen.dart",
    "lib\screens\investment_calculator_screen.dart",
    "lib\screens\loan_calculator_screen.dart",
    "lib\screens\login_screen.dart",
    "lib\screens\onboarding_screen.dart",
    "lib\screens\permission_setup_screen.dart",
    "lib\screens\profile_creation_screen.dart",
    "lib\screens\profile_screen.dart",
    "lib\screens\profile_type_screen.dart",
    "lib\screens\profile_type_selection_screen.dart",
    "lib\screens\progressive_goal_wizard_screen.dart",
    "lib\screens\signin_screen.dart",
    "lib\screens\sms_review_screen.dart",
    "lib\screens\transactions_screen.dart",
    "lib\services\proactive_permission_service.dart",
    "lib\utils\app_icon_generator.dart",
    "lib\widgets\quick_transaction_entry.dart"
)

foreach ($file in $files) {
    if (Test-Path $file) {
        Write-Host "Fixing $file"
        $content = Get-Content $file -Raw
        $content = $content -replace '\.withOpacity\(([^)]+)\)', '.withValues(alpha: $1)'
        Set-Content $file -Value $content -NoNewline
    }
}

Write-Host "Done fixing withOpacity deprecations"
