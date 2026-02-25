<#
launcher\launch.ps1 (FAST)
- backend + frontend 실행
- PID 저장 (launcher\pids)
- 로그 저장 (launcher\logs)
- 설치/정리 작업은 "변경될 때만" 실행하여 런치 속도 단축

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
$BackendReload = $true   # 빠르게만 원하면 $false

# Frontend
$FlutterCmd    = "D:\coding\coin_guide\flutter\bin\flutter.bat"  # 절대경로 (PATH 이슈 방지)
$FlutterDevice = "chrome"
$WebPort       = 5173
$OpenBrowser   = $true
$BrowserExe    = "C:\Program Files\Google\Chrome\Application\chrome.exe"

# Speed toggles
$DoFlutterClean = $false   # 기본은 false (필요할 때만 true)
$ForcePipInstall = $false  # 기본은 false (강제 설치 필요할 때만 true)
$ForcePubGet     = $false  # 기본은 false (강제 pub get 필요할 때만 true)

# ---------------------------
# INTERNALS
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

function Save-Pid([string]$name, [int]$procId) {
  $pidPath = Join-Path $PidDir "$name.pid"
  Set-Content -Path $pidPath -Value $procId -Encoding ascii
  Info "$name PID = $procId (saved to $pidPath)"
}

function Start-LoggedProcess {
  param(
    [Parameter(Mandatory=$true)][string]$Name,
    [Parameter(Mandatory=$true)][string]$WorkDir,
    [Parameter(Mandatory=$true)][string]$FilePath,
    [Parameter(Mandatory=$true)][string]$Arguments
  )

  $out = Join-Path $LogDir "$Name-$ts.out.log"
  $err = Join-Path $LogDir "$Name-$ts.err.log"

  Info "Starting $Name"
  Info "  dir: $WorkDir"
  Info "  cmd: $FilePath $Arguments"
  Info "  out: $out"
  Info "  err: $err"

  # .bat는 cmd.exe로 감싸야 안정적
  if ($FilePath.ToLower().EndsWith(".bat")) {
    $p = Start-Process -FilePath "cmd.exe" `
                      -ArgumentList "/c `"$FilePath`" $Arguments" `
                      -WorkingDirectory $WorkDir `
                      -RedirectStandardOutput $out `
                      -RedirectStandardError  $err `
                      -WindowStyle Normal `
                      -PassThru
  } else {
    $p = Start-Process -FilePath $FilePath `
                      -ArgumentList $Arguments `
                      -WorkingDirectory $WorkDir `
                      -RedirectStandardOutput $out `
                      -RedirectStandardError  $err `
                      -WindowStyle Normal `
                      -PassThru
  }

  Save-Pid $Name $p.Id
  return $p
}

function Run-Step {
  param(
    [Parameter(Mandatory=$true)][string]$Name,
    [Parameter(Mandatory=$true)][string]$WorkDir,
    [Parameter(Mandatory=$true)][string]$FilePath,
    [Parameter(Mandatory=$true)][string[]]$Args
  )
  $out = Join-Path $LogDir "$Name-$ts.out.log"
  $err = Join-Path $LogDir "$Name-$ts.err.log"

  Info "Step: $Name"
  Info "  dir: $WorkDir"
  Info "  cmd: $FilePath $($Args -join ' ')"
  Push-Location $WorkDir
  try {
    if ($FilePath.ToLower().EndsWith(".bat")) {
      & cmd.exe /c "`"$FilePath`" $($Args -join ' ')" *>> $out 2>> $err
    } else {
      & $FilePath @Args *>> $out 2>> $err
    }
  } finally {
    Pop-Location
  }
}

try {
  if (-not (Test-Path $BackendDir))  { throw "BackendDir not found: $BackendDir" }
  if (-not (Test-Path $FrontendDir)) { throw "FrontendDir not found: $FrontendDir" }
  if (-not (Test-Path $FlutterCmd))  { throw "FlutterCmd not found: $FlutterCmd" }

  # ---------------------------
  # Backend: venv + deps (only when changed)
  # ---------------------------
  if (-not (Test-Path $VenvPython)) {
    Info "Creating venv: $VenvDir"
    & python -m venv $VenvDir
  }
  if (-not (Test-Path $VenvPython)) {
    throw "Venv python not found: $VenvPython"
  }

  $req   = Join-Path $BackendDir "requirements.txt"
  $stamp = Join-Path $PidDir "backend_requirements.stamp"

  if (Test-Path $req) {
    $needInstall = $ForcePipInstall `
      -or (-not (Test-Path $stamp)) `
      -or ((Get-Item $req).LastWriteTime -gt (Get-Item $stamp).LastWriteTime)

    if ($needInstall) {
      Info "requirements changed (or forced) -> pip install"
      & $VenvPython -m pip install --upgrade pip | Out-Null
      & $VenvPython -m pip install -r $req
      New-Item -ItemType File -Force -Path $stamp | Out-Null
    } else {
      Info "requirements unchanged -> skip pip install"
    }
  } else {
    Warn "requirements.txt not found at $req (skip pip install)"
  }

  # ---------------------------
  # Backend: start uvicorn
  # ---------------------------
  $reloadFlag = if ($BackendReload) { "--reload" } else { "" }
  $backendArgs = "-m uvicorn $BackendApp $reloadFlag --port $BackendPort"
  $null = Start-LoggedProcess -Name "backend" -WorkDir $BackendDir -FilePath $VenvPython -Arguments $backendArgs

  Start-Sleep -Seconds 1

  # ---------------------------
  # Frontend: flutter steps (only when needed)
  # ---------------------------
  if ($DoFlutterClean) {
    Run-Step -Name "flutter-clean" -WorkDir $FrontendDir -FilePath $FlutterCmd -Args @("clean")
  } else {
    Info "Skip flutter clean (DoFlutterClean=false)"
  }

  $pubspec = Join-Path $FrontendDir "pubspec.yaml"
  $pst     = Join-Path $PidDir "flutter_pubget.stamp"

  if (Test-Path $pubspec) {
    $needPubGet = $ForcePubGet `
      -or (-not (Test-Path $pst)) `
      -or ((Get-Item $pubspec).LastWriteTime -gt (Get-Item $pst).LastWriteTime)

    if ($needPubGet) {
      Info "pubspec changed (or forced) -> flutter pub get"
      Run-Step -Name "flutter-pub-get" -WorkDir $FrontendDir -FilePath $FlutterCmd -Args @("pub","get")
      New-Item -ItemType File -Force -Path $pst | Out-Null
    } else {
      Info "pubspec unchanged -> skip flutter pub get"
    }
  } else {
    Warn "pubspec.yaml not found -> still trying flutter run"
  }

  # ---------------------------
  # Frontend: start flutter web (no auto browser)
  # ---------------------------
  $frontendArgs = "run -d $FlutterDevice --web-port=$WebPort --web-hostname=127.0.0.1"
  $null = Start-LoggedProcess -Name "frontend" -WorkDir $FrontendDir -FilePath $FlutterCmd -Arguments $frontendArgs

  Start-Sleep -Seconds 2

  # ---------------------------
  # Open browser ourselves
  # ---------------------------
  if ($OpenBrowser) {
    $url = "http://127.0.0.1:$WebPort"
    Info "Opening browser: $url"
    if (Test-Path $BrowserExe) {
      Start-Process -FilePath $BrowserExe -ArgumentList "--new-window",$url | Out-Null
    } else {
      Start-Process $url | Out-Null
    }
  }

  Info "All started."
  Info "Stop with: .\stop.ps1"

} catch {
  Err "Launch failed: $($_.Exception.Message)"
  Err "Check logs in: $LogDir"
  throw
}