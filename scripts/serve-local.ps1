# Start VisiMed locally: Django API on :8000, Flutter web on :8080.
# Run from repo root:  .\scripts\serve-local.ps1

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$backend = Join-Path $root "backend"
$web = Join-Path $root "frontend\build\web"

Write-Host "Building Flutter web (API -> http://127.0.0.1:8000/api)..." -ForegroundColor Cyan
Push-Location (Join-Path $root "frontend")
flutter build web --dart-define=VISIMED_API_URL=http://127.0.0.1:8000/api
if ($LASTEXITCODE -ne 0) { Pop-Location; exit 1 }
Pop-Location

Write-Host "Starting Django on http://127.0.0.1:8000 ..." -ForegroundColor Green
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$backend'; `$env:DJANGO_DEBUG='true'; python manage.py runserver 8000"

Start-Sleep -Seconds 2

Write-Host "Serving web on http://127.0.0.1:8080 ..." -ForegroundColor Green
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$web'; python -m http.server 8080"

Start-Sleep -Seconds 1
Start-Process "http://127.0.0.1:8080"

Write-Host ""
Write-Host "VisiMed is up." -ForegroundColor Green
Write-Host "  Frontend : http://127.0.0.1:8080"
Write-Host "  Backend  : http://127.0.0.1:8000/api/health/"
Write-Host "  Logins   : medrep1/med123  admin/admin123  manager1/manager123  pharmrep1/pharma123"
