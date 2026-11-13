$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Local-Common.ps1')
Set-Location -LiteralPath $PSScriptRoot
$javaHome = Find-LocalJavaHome
$keyDirectory = Join-Path $localRoot 'signing'
$store = Join-Path $keyDirectory 'declaraucr-release.jks'
$properties = Join-Path $PSScriptRoot 'android\key.properties'
New-Item -ItemType Directory -Force -Path $keyDirectory | Out-Null
if (-not (Test-Path -LiteralPath $properties)) {
    if (Test-Path -LiteralPath $store) { throw 'Ya existe una clave de firma. Restaura su key.properties antes de compilar para conservar las actualizaciones.' }
    $bytes = New-Object byte[] 32
    $random = [Security.Cryptography.RandomNumberGenerator]::Create()
    $random.GetBytes($bytes)
    $random.Dispose()
    $env:DECLARAUCR_KEY_PASSWORD = [Convert]::ToBase64String($bytes)
    try {
        & (Join-Path $javaHome 'bin\keytool.exe') -genkeypair -keystore $store -storetype JKS -alias declaraucr -keyalg RSA -keysize 3072 -validity 10000 -dname 'CN=DeclaraUCR, OU=Proyecto Academico, O=DeclaraUCR, C=CR' -storepass:env DECLARAUCR_KEY_PASSWORD -keypass:env DECLARAUCR_KEY_PASSWORD
        if ($LASTEXITCODE -ne 0) { throw 'No se pudo crear la firma del APK.' }
        $storePath = $store.Replace('\','/')
        "storePassword=$env:DECLARAUCR_KEY_PASSWORD`nkeyPassword=$env:DECLARAUCR_KEY_PASSWORD`nkeyAlias=declaraucr`nstoreFile=$storePath" | Set-Content -LiteralPath $properties -Encoding ASCII
    } finally { Remove-Item Env:\DECLARAUCR_KEY_PASSWORD -ErrorAction SilentlyContinue }
}
& flutter pub get
if ($LASTEXITCODE -ne 0) { throw 'No se pudieron preparar las dependencias Flutter.' }
& flutter build apk --release --target=lib/main.dart --dart-define=USE_FIREBASE_EMULATORS=false
if ($LASTEXITCODE -ne 0) { throw 'No se pudo compilar el APK del telefono.' }
New-Item -ItemType Directory -Force -Path output\android | Out-Null
Copy-Item -LiteralPath build\app\outputs\flutter-apk\app-release.apk -Destination output\android\DeclaraUCR-telefono.apk -Force
Write-Host 'APK listo: output\android\DeclaraUCR-telefono.apk. Conserva android\key.properties y .local\signing para futuras actualizaciones. No los publiques.' -ForegroundColor Green
