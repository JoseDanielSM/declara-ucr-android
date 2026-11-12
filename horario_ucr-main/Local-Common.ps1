$ErrorActionPreference = 'Stop'
$projectRoot = $PSScriptRoot
$localRoot = Join-Path $projectRoot '.local'
$stateFile = Join-Path $localRoot 'processes.json'
$projectId = 'demo-declaraucr-local'
$appUrl = 'http://127.0.0.1:7357'

function Find-FirebaseCli {
    $command = Get-Command firebase -ErrorAction Stop
    $candidate = Join-Path (Split-Path -Parent $command.Source) 'node_modules\firebase-tools\lib\bin\firebase.js'
    if (-not (Test-Path -LiteralPath $candidate)) {
        throw 'No se encontro Firebase CLI. Instalalo con npm install -g firebase-tools.'
    }
    return $candidate
}

function Set-LocalEnvironment {
    $env:GCLOUD_PROJECT = $projectId
    $env:GOOGLE_CLOUD_PROJECT = $projectId
    $env:FIREBASE_AUTH_EMULATOR_HOST = '127.0.0.1:9099'
    $env:FIRESTORE_EMULATOR_HOST = '127.0.0.1:8180'
    $env:FIREBASE_STORAGE_EMULATOR_HOST = '127.0.0.1:9199'
    $env:HOST = '127.0.0.1'
    $env:PORT = '8080'
    $env:JAVA_HOME = 'C:\Program Files\Java\jdk-21'
    if (-not (Test-Path -LiteralPath (Join-Path $env:JAVA_HOME 'bin\java.exe'))) {
        $java = Get-Command java -ErrorAction Stop
        $env:JAVA_HOME = Split-Path -Parent (Split-Path -Parent $java.Source)
    }
    $env:PATH = (Join-Path $env:JAVA_HOME 'bin') + [IO.Path]::PathSeparator + $env:PATH
}

function Get-OwnedProcess($entry) {
    $process = Get-Process -Id $entry.id -ErrorAction SilentlyContinue
    if ($process -and $process.StartTime.ToUniversalTime().Ticks.ToString() -eq [string]$entry.startedAt) {
        return $process
    }
    return $null
}

function Stop-OwnedProcesses($entries) {
    foreach ($entry in @($entries)) {
        if (Get-OwnedProcess $entry) {
            & taskkill.exe /PID $entry.id /T /F 2>$null | Out-Null
        }
    }
}

function Test-LocalPort([int]$port) {
    $socket = New-Object Net.Sockets.TcpClient
    try {
        $task = $socket.ConnectAsync('127.0.0.1', $port)
        return ($task.Wait(300) -and $socket.Connected)
    } catch {
        return $false
    } finally {
        $socket.Dispose()
    }
}

function Start-LocalNode([string]$name, [string[]]$nodeArguments) {
    $process = Start-Process -FilePath (Get-Command node).Source -ArgumentList $nodeArguments `
        -WorkingDirectory $projectRoot -WindowStyle Hidden -PassThru `
        -RedirectStandardOutput (Join-Path $localRoot "$name.log") `
        -RedirectStandardError (Join-Path $localRoot "$name-errors.log")
    return [pscustomobject]@{
        name = $name
        id = $process.Id
        startedAt = $process.StartTime.ToUniversalTime().Ticks.ToString()
    }
}
