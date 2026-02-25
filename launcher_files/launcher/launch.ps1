<#
launcher\launch.ps1
- Windows 11 PowerShell launcher
- Starts backend + frontend
- Saves PIDs to launcher\pids\
- Writes logs to launcher\logs\

✅ You already provided the paths & commands; they are set in CONFIG below.
Tip: This script uses the venv's python directly, so it does NOT require "activate".
#>

# ---------------------------
# CONFIG
# ---------------------------
$BackendDir  = "D:\coding\lab_note\backend"
$FrontendDir = "D:\coding\lab_note\frontend"

# Backend
$VenvDir     = Join-Path $BackendDir ".venv"
$VenvPython  = Join-Path $VenvDir "Scripts\python.exe"
$BackendPort = 8000
$BackendApp  = "app.main:app"

# Frontend
$FlutterCmd  = "flutter"
$FlutterDevice = "chrome"   # or "edge" / "windows"

# ---------------------------
# INTERNALS (do not edit)
# ---------------------------
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$Here   = Split-Path -Parent $MyInvocation.MyCommand.Path
$PidDir = Join-Path $Here "pids"
$LogDir = Join-Path $Here "logs"
New-Item -ItemType Directory -Force -Path $PidDir, $LogDir | Out-Null
$ts = Get-Date -Format "yyyyMMdd_HHmmss"

function Info($m){ Write-Host "[launch] $m" -ForegroundColor Cyan }
function Warn($m){ Write-Host "[launch] $m" -ForegroundColor Yellow }
function Err ($m){ Write-Host "[launch] $m" -ForegroundColor Red }

function Save-Pid([string]$name, [int]$pid) {
  $pidPath = Join-Path $PidDir "$name.pid"
  Set-Content -Path $pidPath -Value $pid -Encoding ascii
  Info "$name PID = $pid (saved to $pidPath)"
}

function Start-LoggedProcess {
  param(
    [Parameter(Mandatory=$true)][string]$Name,
    [Parameter(Mandatory=$true)][string]$WorkDir,
    [Parameter(Mandatory=$true)][string]$FilePath,
    [Parameter(Mandatory=$true)][string]$Arguments
  )
  if (-not (Test-Path $WorkDir)) { throw "WorkDir not found: $WorkDir" }

  $out = Join-Path $LogDir "$Name-$ts.out.log"
  $err = Join-Path $LogDir "$Name-$ts.err.log"

  Info "Starting $Name"
  Info "  dir: $WorkDir"
  Info "  cmd: $FilePath $Arguments"
  Info "  out: $out"
  Info "  err: $err"

  $p = Start-Process -FilePath $FilePath `
                    -ArgumentList $Arguments `
                    -WorkingDirectory $WorkDir `
                    -RedirectStandardOutput $out `
                    -RedirectStandardError  $err `
                    -WindowStyle Normal `
                    -PassThru
  Save-Pid $Name $p.Id
  return $p
}

# ---- Preflight ----
Info "Launcher directory: $Here"
Info "BackendDir:  $BackendDir"
Info "FrontendDir: $FrontendDir"

if (-not (Test-Path $BackendDir))  { throw "BackendDir not found: $BackendDir" }
if (-not (Test-Path $FrontendDir)) { throw "FrontendDir not found: $FrontendDir" }

# ---- Backend: ensure venv + deps ----
if (-not (Test-Path $VenvPython)) {
  Info "Creating venv: $VenvDir"
  & python -m venv $VenvDir
}

if (-not (Test-Path $VenvPython)) {
  throw "Venv python not found after creation: $VenvPython"
}

$req = Join-Path $BackendDir "requirements.txt"
if (Test-Path $req) {
  Info "Installing backend deps from requirements.txt"
  & $VenvPython -m pip install --upgrade pip | Out-Null
  & $VenvPython -m pip install -r $req
} else {
  Warn "requirements.txt not found at $req"
  Warn "Skipping pip install. If uvicorn is missing, add requirements.txt or install packages into .venv."
}

# ---- Backend: start uvicorn ----
$backendArgs = "-m uvicorn $BackendApp --reload --port $BackendPort"
$backendProc = Start-LoggedProcess -Name "backend" -WorkDir $BackendDir -FilePath $VenvPython -Arguments $backendArgs

Start-Sleep -Seconds 1

# ---- Frontend: flutter clean/pub get (sync) ----
Info "Running: flutter clean"
& $FlutterCmd clean --project-dir $FrontendDir | Out-Null

Info "Running: flutter pub get"
& $FlutterCmd pub get --project-dir $FrontendDir

# ---- Frontend: start flutter run ----
$frontendArgs = "run -d $FlutterDevice"
$frontendProc = Start-LoggedProcess -Name "frontend" -WorkDir $FrontendDir -FilePath $FlutterCmd -Arguments $frontendArgs

Info "All started."
Info "Stop with: .\stop.ps1"
