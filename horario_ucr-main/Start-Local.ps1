param([switch]$NoBrowser, [switch]$SkipBuild)
. (Join-Path $PSScriptRoot 'Local-Common.ps1')
Set-Location -LiteralPath $projectRoot
New-Item -ItemType Directory -Force -Path $localRoot | Out-Null
$entries = @()
$firebaseCli = Find-FirebaseCli
Set-LocalEnvironment

if (Test-Path -LiteralPath $stateFile) {
    $previous = Get-Content -LiteralPath $stateFile -Raw | ConvertFrom-Json
    if (@($previous | Where-Object { Get-OwnedProcess $_ }).Count -gt 0) {
        if ((Test-LocalPort 7357) -and (Test-LocalPort 8080)) {
            Write-Host "DeclaraUCR ya esta en marcha: $appUrl" -ForegroundColor Green
            if (-not $NoBrowser) { Start-Process $appUrl }
            exit 0
        }
        throw 'Hay un inicio incompleto. Ejecuta Detener-DeclaraUCR.cmd y vuelve a iniciar.'
    }
}

foreach ($port in @(7357, 8080, 9099, 8180, 5001, 9199, 4000, 4400, 4500, 9299)) {
    if (Test-LocalPort $port) { throw "El puerto $port esta ocupado. Cierra la aplicacion que lo usa y vuelve a intentar." }
}

try {
    foreach ($directory in @('.', 'functions', 'websocket_server')) {
        if (-not (Test-Path -LiteralPath (Join-Path $directory 'node_modules'))) {
            Push-Location $directory
            try {
                & npm ci --no-audit --no-fund
                if ($LASTEXITCODE -ne 0) { throw "No se pudieron instalar las dependencias de $directory." }
            } finally { Pop-Location }
        }
    }

    if (-not $SkipBuild) {
        Write-Host 'Preparando la aplicacion local (el primer inicio puede tardar unos minutos)...'
        & flutter pub get
        if ($LASTEXITCODE -ne 0) { throw 'No se pudieron preparar las dependencias de Flutter.' }
        & flutter build web --no-pub --dart-define=USE_FIREBASE_EMULATORS=true --dart-define=NOTIFICATIONS_WS_URL=ws://127.0.0.1:8080
        if ($LASTEXITCODE -ne 0) { throw 'La aplicacion no se pudo compilar.' }
        Set-Content -LiteralPath (Join-Path $localRoot 'local-build.txt') -Value (Get-Date -Format o)
    } elseif (-not (Test-Path -LiteralPath (Join-Path $localRoot 'local-build.txt'))) {
        throw 'Primero ejecuta el inicio normal para compilar la version local.'
    }

    $emulatorArguments = @(('"' + $firebaseCli + '"'), 'emulators:start', '--config', 'firebase.local.json', '--project', $projectId, '--only', 'auth,firestore,functions,storage,hosting', '--export-on-exit', ('"' + (Join-Path $localRoot 'firebase-data') + '"'))
    if (Test-Path -LiteralPath (Join-Path $localRoot 'firebase-data\firebase-export-metadata.json')) {
        $emulatorArguments += @('--import', ('"' + (Join-Path $localRoot 'firebase-data') + '"'))
    }
    Write-Host 'Iniciando cuentas, base de datos, funciones y archivos locales...'
    $entries += Start-LocalNode -name 'firebase' -nodeArguments $emulatorArguments
    $entries | ConvertTo-Json -Depth 3 | Set-Content -LiteralPath $stateFile
    $ready = $false
    for ($attempt = 0; $attempt -lt 180; $attempt++) {
        if (-not (Get-OwnedProcess $entries[0])) { throw 'Firebase no pudo iniciar. Revisa .local\firebase.log y .local\firebase-errors.log.' }
        $log = Get-Content -LiteralPath (Join-Path $localRoot 'firebase.log') -Raw -ErrorAction SilentlyContinue
        if ($log -match 'All emulators ready') { $ready = $true; break }
        Start-Sleep -Seconds 1
    }
    if (-not $ready) { throw 'Los servicios no terminaron de iniciar. Revisa .local\firebase.log.' }

    & node scripts/seed-local.cjs
    if ($LASTEXITCODE -ne 0) { throw 'No se pudieron preparar las cuentas locales.' }
    $entries += Start-LocalNode -name 'notifications' -nodeArguments @('websocket_server/server.js')
    $entries | ConvertTo-Json -Depth 3 | Set-Content -LiteralPath $stateFile
    for ($attempt = 0; $attempt -lt 20; $attempt++) {
        if (Test-LocalPort 8080) { break }
        Start-Sleep -Seconds 1
    }
    if (-not (Test-LocalPort 8080)) { throw 'No se pudo iniciar el servicio de notificaciones.' }

    Write-Host "Aplicacion lista: $appUrl" -ForegroundColor Green
    Write-Host 'Cuentas: declarante@local.test, superior@local.test, rrhh@local.test, admin@local.test'
    Write-Host 'Contrasena de prueba: PruebaUCR2026!'
    Write-Host 'Para cerrar y guardar los datos, usa Detener-DeclaraUCR.cmd.'
    if (-not $NoBrowser) { Start-Process $appUrl }
} catch {
    Stop-OwnedProcesses $entries
    throw
}
