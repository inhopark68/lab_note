<#
launcher\stop.ps1
- Stops backend + frontend using PID files saved by launch.ps1
- Uses taskkill /T /F to kill the whole process tree (important for uvicorn --reload).
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$Here   = Split-Path -Parent $MyInvocation.MyCommand.Path
$PidDir = Join-Path $Here "pids"

function Info($m){ Write-Host "[stop] $m" -ForegroundColor Cyan }
function Warn($m){ Write-Host "[stop] $m" -ForegroundColor Yellow }
function Err ($m){ Write-Host "[stop] $m" -ForegroundColor Red }

function Stop-TreeFromPidFile([string]$Name) {
  $pidPath = Join-Path $PidDir "$Name.pid"
  if (-not (Test-Path $pidPath)) {
    Warn "PID file not found: $pidPath (nothing to stop)"
    return
  }

  $pidText = (Get-Content $pidPath -ErrorAction SilentlyContinue | Select-Object -First 1).Trim()
  if (-not ($pidText -match '^\d+$')) {
    Warn "Invalid PID in $pidPath: '$pidText' (removing pid file)"
    Remove-Item $pidPath -Force -ErrorAction SilentlyContinue
    return
  }

  $pid = [int]$pidText
  $p = Get-Process -Id $pid -ErrorAction SilentlyContinue
  if ($null -eq $p) {
    Warn "$Name not running (PID $pid). Cleaning PID file."
    Remove-Item $pidPath -Force -ErrorAction SilentlyContinue
    return
  }

  Info "Stopping $Name (PID $pid) + children ..."
  try {
    # /T = kill child processes too, /F = force
    & taskkill /PID $pid /T /F | Out-Null
    Info "Stopped $Name."
  } catch {
    Err "Failed to stop $Name: $($_.Exception.Message)"
  } finally {
    Remove-Item $pidPath -Force -ErrorAction SilentlyContinue
  }
}

Info "Stopping processes using PID files in: $PidDir"
Stop-TreeFromPidFile "frontend"
Stop-TreeFromPidFile "backend"
Info "Done."
