$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot
$adb = Join-Path $env:LOCALAPPDATA 'Android\sdk\platform-tools\adb.exe'
$output = Join-Path $PSScriptRoot 'evidence\android'
New-Item -ItemType Directory -Force -Path $output | Out-Null
$runner = Join-Path $PSScriptRoot '.local\run-android-drive.ps1'
@'
Set-Location -LiteralPath $PSScriptRoot
Set-Location ..
flutter drive --driver=test_driver/integration_driver.dart --target=integration_test/mobile_workflow_test.dart -d emulator-5554 --disable-dds --host-vmservice-port=53102 --dart-define=USE_FIREBASE_EMULATORS=true --dart-define=FIREBASE_EMULATOR_HOST=10.0.2.2 --dart-define=NOTIFICATIONS_WS_URL=ws://10.0.2.2:8080
exit $LASTEXITCODE
'@ | Set-Content -LiteralPath $runner
$log = Join-Path $PSScriptRoot '.local\android-drive.log'
$process = Start-Process powershell.exe -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File',('"'+$runner+'"')) -WindowStyle Hidden -PassThru -RedirectStandardOutput $log -RedirectStandardError (Join-Path $PSScriptRoot '.local\android-drive-errors.log')
$null = $process.Handle
$recording = $null
$deadline = (Get-Date).AddMinutes(15)
while (-not $process.HasExited) {
    if ((Get-Date) -gt $deadline) { throw 'La prueba Android supero 15 minutos. Revisa .local\android-drive.log.' }
    if (-not $recording -and (Test-Path -LiteralPath $log) -and (Select-String -LiteralPath $log -SimpleMatch 'VIDEO_READY' -Quiet)) {
        Write-Host 'Grabando la demostracion real de Android...'
        $recording = Start-Process $adb -ArgumentList @('-s','emulator-5554','shell','screenrecord','--time-limit','70','--bit-rate','3000000','/sdcard/declara-ucr-demo.mp4') -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $PSScriptRoot '.local\recording.log') -RedirectStandardError (Join-Path $PSScriptRoot '.local\recording-errors.log')
    }
    Start-Sleep -Milliseconds 500
    $process.Refresh()
}
$process.WaitForExit()
$driveExitCode = $process.ExitCode
if ($recording) {
    if (-not $recording.HasExited) {
        $recordingPid = & $adb -s emulator-5554 shell pidof screenrecord
        if ($recordingPid -match '^\d+$') { & $adb -s emulator-5554 shell kill -2 $recordingPid }
    }
    $recording.WaitForExit()
    & $adb -s emulator-5554 pull /sdcard/declara-ucr-demo.mp4 (Join-Path $output 'demostracion-android.mp4')
}
Get-Content -LiteralPath $log -Tail 35 | ForEach-Object { if ($_.Length -gt 700) { $_.Substring(0,700) } else { $_ } }
Get-Content -LiteralPath (Join-Path $PSScriptRoot '.local\android-drive-errors.log') -Tail 15
if ($driveExitCode -ne 0) { throw "La prueba Android encontro un problema (codigo $driveExitCode). Revisa los registros." }
Write-Host 'Pruebas, capturas y video Android completados.' -ForegroundColor Green
