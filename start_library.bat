@echo off
setlocal
cd /d "%~dp0"

set "PY_CMD=py -3"
py -3 --version >nul 2>&1
if errorlevel 1 set "PY_CMD=python"

%PY_CMD% -c "import sys; raise SystemExit(sys.version_info < (3, 10))" >nul 2>&1
if errorlevel 1 (
  echo Python 3.10 or newer was not found. Install Python and try again.
  pause
  exit /b 1
)

%PY_CMD% -c "import pymupdf" >nul 2>&1
if errorlevel 1 (
  echo Installing the library's required Python package...
  %PY_CMD% -m pip install -r requirements.txt
  if errorlevel 1 (
    echo Dependency installation failed. Check your internet connection and try again.
    pause
    exit /b 1
  )
)

powershell -NoProfile -Command "try { Invoke-WebRequest -Uri 'http://127.0.0.1:8000/api/session' -TimeoutSec 2 -UseBasicParsing | Out-Null; exit 0 } catch { exit 1 }"
if errorlevel 1 (
  start "Library server" %PY_CMD% server.py
)

powershell -NoProfile -Command "$deadline = (Get-Date).AddSeconds(20); do { try { $response = Invoke-WebRequest -Uri 'http://127.0.0.1:8000/api/session' -TimeoutSec 2 -UseBasicParsing; if ($response.StatusCode -eq 200) { exit 0 } } catch { }; Start-Sleep -Milliseconds 500 } while ((Get-Date) -lt $deadline); exit 1"
if errorlevel 1 (
  echo The library server did not start. Check the server window for an error.
  pause
  exit /b 1
)

start "" "http://127.0.0.1:8000"
echo The library is open at http://127.0.0.1:8000
