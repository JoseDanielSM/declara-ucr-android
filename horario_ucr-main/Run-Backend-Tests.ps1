param([switch]$UnitOnly)
. (Join-Path $PSScriptRoot 'Local-Common.ps1')
Set-Location -LiteralPath $projectRoot
New-Item -ItemType Directory -Force -Path $localRoot | Out-Null
Set-LocalEnvironment
& node --test security_tests/backend_validator.test.cjs
if ($LASTEXITCODE -ne 0) { throw 'Fallaron las pruebas del validador.' }
if ($UnitOnly) { exit 0 }

$backendArguments = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', (Join-Path $projectRoot 'Start-Local.ps1'), '-NoBrowser')
if (Test-Path -LiteralPath (Join-Path $localRoot 'local-build.txt')) { $backendArguments += '-SkipBuild' }
& powershell.exe @backendArguments
if ($LASTEXITCODE -ne 0) { throw 'No se pudieron preparar los servicios de prueba.' }
foreach ($script in @('scripts/check-local.cjs', 'scripts/check-drafts.cjs')) {
    & node $script
    if ($LASTEXITCODE -ne 0) { throw "Fallo $script. Revisa los resultados en .local." }
}
Write-Host 'Validador, flujo local, borradores y permisos comprobados. Los servicios quedan encendidos; usa Detener-DeclaraUCR.cmd al terminar.' -ForegroundColor Green
