<#
.SYNOPSIS
  Starts the Wedpilot backend only if it isn't already up.

.DESCRIPTION
  Safe to run any number of times: it probes /health first and does nothing
  when the server already answers, so it can never produce the EADDRINUSE
  confusion that comes from double-starting nodemon.

  This exists because a stopped backend is indistinguishable from a broken app
  from the outside — every request fails with a connection error, and the app
  can only say "could not reach the server". Running this before a Flutter
  session removes that whole class of false alarm.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File backend/scripts/dev-up.ps1
#>

[CmdletBinding()]
param(
    # Seconds to wait for the server to bind. A cold `sequelize.sync({alter:true})`
    # against a schema this size can take a while on first boot.
    [int]$TimeoutSeconds = 90
)

$ErrorActionPreference = 'Stop'

$backendDir = Split-Path -Parent $PSScriptRoot
$envFile    = Join-Path $backendDir '.env'
$logOut     = Join-Path $backendDir 'dev-server.log'
$logErr     = Join-Path $backendDir 'dev-server.err.log'

# ── Port comes from .env so this follows a PORT override ──────────────────────
$port = 3000
if (Test-Path $envFile) {
    $portLine = Select-String -Path $envFile -Pattern '^\s*PORT\s*=\s*(\d+)' -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($portLine) { $port = [int]$portLine.Matches[0].Groups[1].Value }
}

$healthUrl = "http://localhost:$port/health"

function Test-Backend {
    try {
        $r = Invoke-WebRequest -Uri $healthUrl -UseBasicParsing -TimeoutSec 3
        return ($r.StatusCode -eq 200)
    } catch {
        return $false
    }
}

function Get-PortOwner {
    try {
        $c = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction Stop | Select-Object -First 1
        return $c.OwningProcess
    } catch {
        return $null
    }
}

# ── Already running? Then we are done. ───────────────────────────────────────
if (Test-Backend) {
    $owner = Get-PortOwner
    if ($null -ne $owner) {
        Write-Host "Backend already running on port $port (PID $owner). Nothing to do." -ForegroundColor Green
    } else {
        Write-Host "Backend already answering on port $port. Nothing to do." -ForegroundColor Green
    }
    exit 0
}

# Something holds the port but does not answer /health — starting a second
# copy would only add a confusing EADDRINUSE, so report and let a human look.
$squatter = Get-PortOwner
if ($null -ne $squatter) {
    Write-Host "Port $port is held by PID $squatter but /health does not answer." -ForegroundColor Yellow
    Write-Host "Inspect it, or stop it with:  Stop-Process -Id $squatter" -ForegroundColor Yellow
    exit 1
}

# ── Pre-flight: MySQL. The server exits when the DB is unreachable, so ───────
# checking first turns a silent process death into a clear message.
$dbHost = 'localhost'
$dbPort = 3306
if (Test-Path $envFile) {
    $hostLine = Select-String -Path $envFile -Pattern '^\s*DB_HOST\s*=\s*(.+)$' -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($hostLine) { $dbHost = $hostLine.Matches[0].Groups[1].Value.Trim() }
    $dbPortLine = Select-String -Path $envFile -Pattern '^\s*DB_PORT\s*=\s*(\d+)' -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($dbPortLine) { $dbPort = [int]$dbPortLine.Matches[0].Groups[1].Value }
}

$dbOk = $false
try {
    $dbOk = (Test-NetConnection -ComputerName $dbHost -Port $dbPort -InformationLevel Quiet -WarningAction SilentlyContinue)
} catch {
    # Test-NetConnection does not exist on every host; fall back to a raw socket.
    try {
        $client = New-Object System.Net.Sockets.TcpClient
        $dbOk = $client.ConnectAsync($dbHost, $dbPort).Wait(3000)
        $client.Close()
    } catch {
        $dbOk = $false
    }
}

if (-not $dbOk) {
    Write-Host "Cannot reach MySQL at ${dbHost}:${dbPort}." -ForegroundColor Red
    Write-Host "The backend exits on boot when the database is down. Start it first:" -ForegroundColor Red
    Write-Host "  Start-Service MySQL80" -ForegroundColor Red
    exit 1
}

# ── Start nodemon detached ───────────────────────────────────────────────────
Write-Host "Backend is down. Starting on port $port..." -ForegroundColor Cyan

# Truncated per run so the log always describes the current process only.
Set-Content -Path $logOut -Value '' -Encoding utf8
Set-Content -Path $logErr -Value '' -Encoding utf8

$npm = (Get-Command npm.cmd -ErrorAction SilentlyContinue)
if ($null -eq $npm) { $npm = (Get-Command npm -ErrorAction SilentlyContinue) }
if ($null -eq $npm) {
    Write-Host 'npm is not on PATH.' -ForegroundColor Red
    exit 1
}

$proc = Start-Process -FilePath $npm.Source -ArgumentList 'run', 'dev' `
    -WorkingDirectory $backendDir `
    -RedirectStandardOutput $logOut -RedirectStandardError $logErr `
    -WindowStyle Hidden -PassThru

$deadline = (Get-Date).AddSeconds($TimeoutSeconds)
while ((Get-Date) -lt $deadline) {
    if (Test-Backend) {
        $owner = Get-PortOwner
        Write-Host "Backend up on port $port (nodemon PID $($proc.Id), listener PID $owner)." -ForegroundColor Green
        Write-Host "  health: $healthUrl"
        Write-Host "  log:    $logOut"
        Write-Host "  stop:   Stop-Process -Id $($proc.Id)"
        exit 0
    }
    if ($proc.HasExited) {
        Write-Host "Backend process exited (code $($proc.ExitCode)) before binding. Last output:" -ForegroundColor Red
        if ((Get-Item $logErr).Length -gt 0) { Get-Content $logErr -Tail 25 }
        if ((Get-Item $logOut).Length -gt 0) { Get-Content $logOut -Tail 25 }
        exit 1
    }
    Start-Sleep -Milliseconds 700
}

Write-Host "Backend did not answer $healthUrl within ${TimeoutSeconds}s. Last output:" -ForegroundColor Red
if ((Get-Item $logOut).Length -gt 0) { Get-Content $logOut -Tail 25 }
if ((Get-Item $logErr).Length -gt 0) { Get-Content $logErr -Tail 25 }
Write-Host "Leaving PID $($proc.Id) running; stop it with:  Stop-Process -Id $($proc.Id)" -ForegroundColor Yellow
exit 1
