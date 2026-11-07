@echo off
rem Starts Smart Class on this PC (relay + backend + web app). See run_local.py.
title Smart Class
set "PY=%~dp0..\..\backend\.venv\Scripts\python.exe"
if not exist "%PY%" set "PY=%~dp0..\..\backend\venv\Scripts\python.exe"
if not exist "%PY%" (
  echo Backend virtual environment not found in backend\.venv or backend\venv.
  pause
  exit /b 1
)
"%PY%" "%~dp0run_local.py" %*
if errorlevel 1 pause
