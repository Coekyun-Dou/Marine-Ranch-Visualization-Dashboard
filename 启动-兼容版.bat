@echo off
chcp 65001 >nul
title 智慧海洋牧场 - 兼容启动脚本
color 0A
setlocal enabledelayedexpansion

echo.
echo ========================================
echo   智慧海洋牧场 兼容启动脚本 v1.0
echo ========================================
echo.

REM 进入脚本所在目录，避免双击时路径错误
cd /d %~dp0
echo [信息] 当前目录: %cd%
echo.

if not exist "backend" (
  echo [错误] 缺少 backend 目录，请在项目根目录运行。
  pause
  exit /b 1
)

if not exist "frontend" (
  echo [错误] 缺少 frontend 目录，请在项目根目录运行。
  pause
  exit /b 1
)

echo [检查] Node.js...
where node >nul 2>nul
if errorlevel 1 (
  echo [错误] 未找到 Node.js，请先安装: https://nodejs.org/
  pause
  exit /b 1
)
node -v
echo.

echo [检查] Python...
where python >nul 2>nul
if errorlevel 1 (
  echo [警告] 未找到 Python，鱼类识别功能不可用（页面可打开）。
) else (
  python --version
  python -c "import cv2" >nul 2>nul
  if errorlevel 1 (
    echo [警告] 当前 Python 未安装 cv2，上传识别会失败。
    echo [提示] 可执行: python -m pip install opencv-python ultralytics
  ) else (
    echo [成功] Python 环境可用于鱼类识别。
  )
)
echo.

echo [清理] 关闭旧端口占用 (3000/5173)...
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :3000 2^>nul') do taskkill /F /PID %%a >nul 2>nul
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :5173 2^>nul') do taskkill /F /PID %%a >nul 2>nul
echo [完成] 端口清理完成
echo.

echo [安装] 检查后端依赖...
cd /d %~dp0backend
if not exist "node_modules" (
  call npm install
) else (
  call npm install --silent
)
if errorlevel 1 (
  echo [错误] 后端依赖安装失败。
  pause
  exit /b 1
)

REM 关键依赖兜底
if not exist "node_modules\multer" call npm install multer
if not exist "node_modules\axios" call npm install axios

echo [安装] 检查前端依赖...
cd /d %~dp0frontend
if not exist "node_modules" (
  call npm install
) else (
  call npm install --silent
)
if errorlevel 1 (
  echo [错误] 前端依赖安装失败。
  pause
  exit /b 1
)

cd /d %~dp0
echo.
echo [启动] 后端服务...
start "MarineRanch-Backend" cmd /k "cd /d %~dp0backend && node server.js"
timeout /t 3 >nul
echo [启动] 前端服务...
start "MarineRanch-Frontend" cmd /k "cd /d %~dp0frontend && npm run dev"

echo.
echo ========================================
echo 启动完成
echo 前端: http://localhost:5173
echo 后端: http://localhost:3000/api/sensor/current
echo 上传识别: http://localhost:3000/api/fish/recognition/upload
echo ========================================
echo.
echo 提示: 若页面仍是旧内容，请 Ctrl+F5 强制刷新。
echo.
pause
