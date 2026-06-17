# build_web.ps1
# Compila o app Flutter web e injeta o hash do build em index.html.
# Use este script em vez de "flutter build web" direto.
#
# Como usar:
#   cd C:\TURBOENTREGACOMPLETO\Cliente
#   .\build_web.ps1
#
# Depois suba a pasta build\web\ inteira para o servidor.

Set-Location $PSScriptRoot

Write-Host "Compilando Flutter web..." -ForegroundColor Cyan
flutter build web --release --pwa-strategy=offline-first --no-wasm-dry-run
if ($LASTEXITCODE -ne 0) {
    Write-Error "Build falhou (exit $LASTEXITCODE)"
    exit 1
}

# Extrai o hash do flutter_bootstrap.js registrado no flutter_service_worker.js
$swPath = Join-Path $PSScriptRoot 'build\web\flutter_service_worker.js'
$sw = Get-Content $swPath -Raw
$hashMatch = [regex]::Match($sw, '"flutter_bootstrap\.js"\s*:\s*"([a-f0-9]+)"')
if (-not $hashMatch.Success) {
    Write-Error "Nao foi possivel extrair o hash do build"
    exit 1
}
$hash = $hashMatch.Groups[1].Value

# Substitui __BUILD_HASH__ em build\web\index.html pelo hash real
$htmlPath = Join-Path $PSScriptRoot 'build\web\index.html'
$html = Get-Content $htmlPath -Raw
if ($html -notmatch '__BUILD_HASH__') {
    Write-Error "Token __BUILD_HASH__ nao encontrado em index.html"
    exit 1
}
$html = $html -replace '__BUILD_HASH__', $hash
[System.IO.File]::WriteAllText($htmlPath, $html)

Write-Host "Build completo!" -ForegroundColor Green
Write-Host "Hash injetado: $hash" -ForegroundColor Yellow
Write-Host "Arquivos prontos em: build\web\" -ForegroundColor Green
