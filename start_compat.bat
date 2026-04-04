@echo off
chcp 65001 >nul
title Marine Ranch - Compatible Starter
color 0A
setlocal enabledelayedexpansion

cd /d %~dp0
echo [INFO] CWD: %cd%

if not exist "backend" (
  echo [ERROR] backend folder not found.
  pause
  exit /b 1
)
if not exist "frontend" (
  echo [ERROR] frontend folder not found.
  pause
  exit /b 1
)

where node >nul 2>nul
if errorlevel 1 (
  echo [ERROR] Node.js not found. Install from https://nodejs.org/
  pause
  exit /b 1
)

where python >nul 2>nul
if errorlevel 1 (
  echo [WARN] Python not found, fish recognition will be unavailable.
) else (
  python -c "import cv2" >nul 2>nul
  if errorlevel 1 (
    echo [WARN] cv2 not found. Run: python -m pip install opencv-python ultralytics
  )
)

for /f "tokens=5" %%a in ('netstat -ano ^| findstr :3000 2^>nul') do taskkill /F /PID %%a >nul 2>nul
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :5173 2^>nul') do taskkill /F /PID %%a >nul 2>nul

cd /d %~dp0backend
if not exist "node_modules" call npm install
if errorlevel 1 (
  echo [ERROR] backend npm install failed.
  pause
  exit /b 1
)
if not exist "node_modules\multer" call npm install multer
if not exist "node_modules\axios" call npm install axios

cd /d %~dp0frontend
if not exist "node_modules" call npm install
if errorlevel 1 (
  echo [ERROR] frontend npm install failed.
  pause
  exit /b 1
)

cd /d %~dp0
start "MarineRanch-Backend" cmd /k "cd /d %~dp0backend && node server.js"
timeout /t 3 >nul
start "MarineRanch-Frontend" cmd /k "cd /d %~dp0frontend && npm run dev"

echo Done.
echo Frontend: http://localhost:5173
echo Backend : http://localhost:3000/api/sensor/current
pause
