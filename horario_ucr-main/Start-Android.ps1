param([switch]$SkipBuild)
. (Join-Path $PSScriptRoot 'Local-Common.ps1')
Set-Location -LiteralPath $PSScriptRoot
Set-LocalEnvironment
$sdk = Find-AndroidSdk
$env:ANDROID_HOME = $sdk
$adb = Join-Path $sdk 'platform-tools\adb.exe'
$emulator = Join-Path $sdk 'emulator\emulator.exe'
$manager = Join-Path $sdk 'cmdline-tools\latest\bin\android.exe'
if (-not (Test-Path -LiteralPath $adb)) { throw 'No se encontro Android SDK. Instala Android Studio y sus herramientas SDK.' }
if (-not (Test-Path -LiteralPath (Join-Path $sdk 'system-images\android-36\google_apis\x86_64\package.xml'))) {
    if (Test-Path -LiteralPath $manager) {
        & $manager sdk install system-images/android-36/google_apis/x86_64
    } else {
        $legacyManager = Join-Path $sdk 'cmdline-tools\latest\bin\sdkmanager.bat'
        if (-not (Test-Path -LiteralPath $legacyManager)) { throw 'Instala Android SDK Command-line Tools (latest) desde SDK Manager de Android Studio.' }
        & $legacyManager 'system-images;android-36;google_apis;x86_64'
    }
    if (-not (Test-Path -LiteralPath (Join-Path $sdk 'system-images\android-36\google_apis\x86_64\package.xml'))) { throw 'No se pudo preparar la imagen Android API 36.' }
}
$avds = & $emulator -list-avds
if ($avds -notcontains 'DeclaraUCR_API36') {
    'no' | & (Join-Path $sdk 'cmdline-tools\latest\bin\avdmanager.bat') create avd --name DeclaraUCR_API36 --package 'system-images;android-36;google_apis;x86_64' --device pixel_6
    if ($LASTEXITCODE -ne 0) { throw 'No se pudo crear el telefono virtual DeclaraUCR.' }
}
$backendArguments = @('-NoProfile','-ExecutionPolicy','Bypass','-File',(Join-Path $PSScriptRoot 'Start-Local.ps1'),'-NoBrowser')
if (Test-Path -LiteralPath '.local\local-build.txt') { $backendArguments += '-SkipBuild' }
& powershell.exe @backendArguments
if ($LASTEXITCODE -ne 0) { throw 'No se pudieron iniciar los servicios locales.' }
$devices = & $adb devices
if (-not ($devices -match 'emulator-5554\s+device')) {
    Start-Process $emulator -ArgumentList @('-avd','DeclaraUCR_API36','-port','5554','-no-boot-anim','-gpu','auto') -WindowStyle Hidden
    Write-Host 'Iniciando el telefono virtual...'
    for ($attempt=0; $attempt -lt 120; $attempt++) {
        if (((& $adb devices) -match 'emulator-5554\s+device') -and ((& $adb -s emulator-5554 shell getprop sys.boot_completed) -match '1')) { break }
        Start-Sleep -Seconds 1
    }
    if ($attempt -eq 120) { throw 'El telefono virtual no termino de iniciar en dos minutos.' }
}
$avdName = & $adb -s emulator-5554 emu avd name
if (-not ($avdName -contains 'DeclaraUCR_API36')) { throw 'El puerto 5554 pertenece a otro telefono virtual. Cerralo antes de iniciar DeclaraUCR.' }
if (-not $SkipBuild -or -not (Test-Path -LiteralPath '.local\android-app-build.txt')) {
    & flutter build apk --debug --target=lib/main.dart --dart-define=USE_FIREBASE_EMULATORS=true --dart-define=FIREBASE_EMULATOR_HOST=10.0.2.2 --dart-define=NOTIFICATIONS_WS_URL=ws://10.0.2.2:8080
    if ($LASTEXITCODE -ne 0) { throw 'No se pudo compilar la aplicacion Android.' }
    Set-Content -LiteralPath '.local\android-app-build.txt' -Value (Get-Date -Format o)
}
& $adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-debug.apk
if ($LASTEXITCODE -ne 0) { throw 'No se pudo instalar la APK.' }
& $adb -s emulator-5554 shell am start -n cr.ac.ucr.declaraucr/cr.ac.ucr.horario_ucr_integrador.MainActivity
Write-Host 'DeclaraUCR esta funcionando en Android con las mismas cuentas locales.' -ForegroundColor Green
