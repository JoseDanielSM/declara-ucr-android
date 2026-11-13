$ErrorActionPreference = 'Stop'
$projectRoot = $PSScriptRoot
$localRoot = Join-Path $projectRoot '.local'
$stateFile = Join-Path $localRoot 'processes.json'
$projectId = 'demo-declaraucr-local'
$appUrl = 'http://127.0.0.1:7357'

function Find-FirebaseCli {
    $localCli = Join-Path $projectRoot 'node_modules\firebase-tools\lib\bin\firebase.js'
    if (Test-Path -LiteralPath $localCli) { return $localCli }
    $command = Get-Command firebase -ErrorAction SilentlyContinue
    if (-not $command) { throw 'No se encontro Firebase CLI. Ejecuta Preparar-DeclaraUCR.cmd para instalar las dependencias del proyecto.' }
    $candidate = Join-Path (Split-Path -Parent $command.Source) 'node_modules\firebase-tools\lib\bin\firebase.js'
    if (-not (Test-Path -LiteralPath $candidate)) {
        throw 'No se encontro Firebase CLI. Instalalo con npm install -g firebase-tools.'
    }
    return $candidate
}

function Find-LocalJavaHome {
    $java = $null
    if ($env:JAVA_HOME -and (Test-Path -LiteralPath (Join-Path $env:JAVA_HOME 'bin\java.exe'))) {
        $java = Join-Path $env:JAVA_HOME 'bin\java.exe'
    } else {
        $command = Get-Command java -ErrorAction SilentlyContinue
        if ($command) { $java = $command.Source }
    }
    if (-not $java) { throw 'Instala un JDK 21 o superior y configura JAVA_HOME o agrega Java al PATH. Consulta documentation\Instalacion_en_otra_PC.md.' }
    $info = New-Object System.Diagnostics.ProcessStartInfo
    $info.FileName = $java
    $info.Arguments = '-XshowSettings:properties -version'
    $info.UseShellExecute = $false
    $info.CreateNoWindow = $true
    $info.RedirectStandardError = $true
    $info.RedirectStandardOutput = $true
    $javaProcess = New-Object System.Diagnostics.Process
    $javaProcess.StartInfo = $info
    try {
        $null = $javaProcess.Start()
        $details = $javaProcess.StandardError.ReadToEnd() + $javaProcess.StandardOutput.ReadToEnd()
        $javaProcess.WaitForExit()
        if ($javaProcess.ExitCode -ne 0 -or $details -notmatch 'java\.specification\.version\s*=\s*(\d+)' -or [int]$Matches[1] -lt 21) {
            throw 'Se requiere JDK 21 o superior para los emuladores. Configura JAVA_HOME con un JDK compatible.'
        }
        if ($details -notmatch 'java\.home\s*=\s*([^\r\n]+)') { throw 'No se pudo detectar la carpeta real de Java.' }
        return $Matches[1].Trim()
    } finally { $javaProcess.Dispose() }
}

function Find-AndroidSdk {
    $candidates = @($env:ANDROID_HOME, $env:ANDROID_SDK_ROOT)
    if ($env:LOCALAPPDATA) { $candidates += Join-Path $env:LOCALAPPDATA 'Android\sdk' }
    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path -LiteralPath (Join-Path $candidate 'platform-tools\adb.exe'))) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }
    throw 'No se encontro Android SDK. Instala Android Studio y Platform-Tools; configura ANDROID_HOME si elegiste otra carpeta.'
}

function Set-LocalEnvironment {
    $env:GCLOUD_PROJECT = $projectId
    $env:GOOGLE_CLOUD_PROJECT = $projectId
    $env:FIREBASE_AUTH_EMULATOR_HOST = '127.0.0.1:9099'
    $env:FIRESTORE_EMULATOR_HOST = '127.0.0.1:8180'
    $env:FIREBASE_STORAGE_EMULATOR_HOST = '127.0.0.1:9199'
    $env:HOST = '127.0.0.1'
    $env:PORT = '8080'
    $env:JAVA_HOME = Find-LocalJavaHome
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
