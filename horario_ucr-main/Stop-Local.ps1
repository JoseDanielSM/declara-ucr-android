. (Join-Path $PSScriptRoot 'Local-Common.ps1')
Set-Location -LiteralPath $projectRoot
if (-not (Test-Path -LiteralPath $stateFile)) {
    Write-Host 'No hay servicios locales registrados.'
    exit 0
}
$entries = Get-Content -LiteralPath $stateFile -Raw | ConvertFrom-Json
$firebaseEntry = $entries | Where-Object { $_.name -eq 'firebase' } | Select-Object -First 1
if ($firebaseEntry -and (Get-OwnedProcess $firebaseEntry)) {
    Write-Host 'Guardando los datos de prueba para el proximo inicio...'
    $hub = Invoke-RestMethod -Uri 'http://127.0.0.1:4400/' -TimeoutSec 5
    if ($hub.pid -ne $firebaseEntry.id) { throw 'El servicio local no coincide con el proceso iniciado por este proyecto.' }
    $exportDirectory = [IO.Path]::GetFullPath((Join-Path $localRoot 'firebase-data'))
    if (-not $exportDirectory.StartsWith(([IO.Path]::GetFullPath($localRoot) + [IO.Path]::DirectorySeparatorChar), [StringComparison]::OrdinalIgnoreCase)) {
        throw 'La carpeta de exportacion debe estar dentro de .local.'
    }
    # Usa la misma operacion del CLI sin lanzar otro proceso de Node en Windows.
    $body = @{ path = $exportDirectory; initiatedBy = 'DeclaraUCR local'; targets = @('auth', 'firestore', 'storage') } | ConvertTo-Json
    $export = Invoke-RestMethod -Uri 'http://127.0.0.1:4400/_admin/export' -Method Post -ContentType 'application/json' -Body $body -TimeoutSec 120
    if ($export.message -ne 'OK' -or -not (Test-Path -LiteralPath (Join-Path $exportDirectory 'firebase-export-metadata.json'))) {
        throw 'No se pudieron guardar los datos. Los servicios siguen encendidos para no perder tu trabajo.'
    }
}
Stop-OwnedProcesses $entries
Set-Content -LiteralPath $stateFile -Value '[]'
Write-Host 'DeclaraUCR detenido. Los datos de prueba quedan guardados.' -ForegroundColor Green
