param(
    [Parameter(Mandatory=$true)]
    [string]$Version
)

# Release script — Usage: .\release.ps1 1.2.0

$tag = "v$Version"

Write-Host "Releasing FishCash POS $tag..." -ForegroundColor Cyan

# 1. Update pubspec.yaml version
$pubspec = Get-Content pubspec.yaml -Raw
$buildNum = (Get-Date).ToString('yyMMdd')
$pubspec = $pubspec -replace 'version: .+', "version: $Version+$buildNum"
$pubspec | Set-Content pubspec.yaml -NoNewline
Write-Host "Updated pubspec.yaml -> $Version"

# 2. Build
Write-Host "Building Windows..." -ForegroundColor Yellow
flutter build windows --release
if ($LASTEXITCODE -ne 0) { Write-Host "Build failed!" -ForegroundColor Red; exit 1 }

# 3. ZIP
Compress-Archive -Path "build\windows\x64\runner\Release\*" -DestinationPath "FishCash-POS-Windows.zip" -Force
Write-Host "Created FishCash-POS-Windows.zip"

# 4. Git commit + tag + push
git add .
git commit -m "release: $tag"
git push origin main

# Delete old tag if exists
git tag -d $tag 2>$null
git push origin ":refs/tags/$tag" 2>$null

git tag $tag
git push origin $tag

Write-Host ""
Write-Host "Released $tag!" -ForegroundColor Green
$releaseUrl = "https://github.com/NguyenQuangTrung19/FishCashing/releases/tag/$tag"
Write-Host "Link: $releaseUrl"
