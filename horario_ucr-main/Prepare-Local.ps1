param([switch]$WebOnly, [switch]$CheckOnly)
. (Join-Path $PSScriptRoot 'Local-Common.ps1')
Set-Location -LiteralPath $projectRoot
New-Item -ItemType Directory -Force -Path $localRoot | Out-Null

foreach ($tool in @('node', 'npm.cmd', 'flutter')) {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
        throw "No se encontro $tool en PATH. Consulta documentation\Instalacion_en_otra_PC.md y abre una terminal nueva despues de instalarlo."
    }
}
$nodeVersion = & node --version
if ($nodeVersion -notmatch '^v24\.') { throw "Usa Node.js 24 LTS. Version detectada: $nodeVersion" }
Set-LocalEnvironment
Write-Host "Node: $nodeVersion"
Write-Host "Java: $env:JAVA_HOME"
& flutter --version
if ($LASTEXITCODE -ne 0) { throw 'Flutter no se pudo ejecutar. Revisa su instalacion y PATH.' }

if (-not $WebOnly) {
    $sdk = Find-AndroidSdk
    foreach ($required in @('emulator\emulator.exe', 'cmdline-tools\latest\bin\avdmanager.bat')) {
        if (-not (Test-Path -LiteralPath (Join-Path $sdk $required))) {
            throw "Falta $required. Instala Android Emulator y Command-line Tools (latest) desde Android Studio > SDK Manager."
        }
    }
    Write-Host "Android SDK: $sdk"
    Write-Host 'Revisa las licencias Android con flutter doctor --android-licenses y la aceleracion con emulator -accel-check.'
}
if ($CheckOnly) {
    Write-Host 'Herramientas base detectadas. No se instalaron dependencias ni se iniciaron servicios.' -ForegroundColor Green
    exit 0
}

foreach ($directory in @('.', 'functions', 'websocket_server')) {
    Write-Host "Instalando dependencias de $directory con su archivo de versiones..."
    Push-Location $directory
    try {
        & npm.cmd ci --no-audit --no-fund
        if ($LASTEXITCODE -ne 0) { throw "No se pudieron instalar las dependencias de $directory." }
    } finally { Pop-Location }
}
& flutter pub get
if ($LASTEXITCODE -ne 0) { throw 'No se pudieron preparar las dependencias Flutter.' }
$firebaseCli = Find-FirebaseCli
& node $firebaseCli --version
if ($LASTEXITCODE -ne 0) { throw 'Firebase CLI no se pudo ejecutar.' }
Write-Host 'Preparacion completada. Usa Iniciar-DeclaraUCR-Android.cmd o Iniciar-DeclaraUCR.cmd.' -ForegroundColor Green
