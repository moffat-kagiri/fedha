$filePath = "lib\screens\welcome_onboarding_screen.dart"
$content = Get-Content -Path $filePath -Raw
$content = $content -replace "alpha: \)", "alpha: 0.2)"
Set-Content -Path $filePath -Value $content
