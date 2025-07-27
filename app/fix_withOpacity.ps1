$filePath = "lib\screens\welcome_onboarding_screen.dart"
$content = Get-Content -Path $filePath -Raw
$content = $content -replace "Colors\.white\.withOpacity\(0\.1\)", "Colors.white.withValues(red: 255, green: 255, blue: 255, alpha: 0.1)"
$content = $content -replace "Colors\.white\.withOpacity\(0\.2\)", "Colors.white.withValues(red: 255, green: 255, blue: 255, alpha: 0.2)"
$content = $content -replace "Colors\.white\.withOpacity\(0\.3\)", "Colors.white.withValues(red: 255, green: 255, blue: 255, alpha: 0.3)"
Set-Content -Path $filePath -Value $content
