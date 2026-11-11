@echo off
rem ============================================================
rem  DVD-VR Splitter — run from source (needs Python 3.9+ & PySide6)
rem ============================================================
setlocal
cd /d "%~dp0"

where python >nul 2>nul
if errorlevel 1 (
  echo Python not found in PATH. Install Python 3.9+ first.
  pause
  exit /b 1
)

python -c "import PySide6" >nul 2>nul
if errorlevel 1 (
  echo Installing PySide6 ...
  python -m pip install PySide6
)

python dvdvr_split.py %*
if errorlevel 1 pause
endlocal
