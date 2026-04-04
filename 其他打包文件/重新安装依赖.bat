@echo off
chcp 65001 >nul 2>nul
title 强制安装所有依赖
color 0C

echo.
echo ╔══════════════════════════════════════════════════════════════╗
echo ║                                                              ║
echo ║           强制重新安装所有依赖                               ║
echo ║                                                              ║
echo ╚══════════════════════════════════════════════════════════════╝
echo.
echo 此脚本将重新安装后端和前端的所有依赖
echo 包括 AI 功能所需的 axios
echo.
pause

echo.
echo [1/2] 安装后端依赖...
echo ==============================
cd backend
if %errorlevel% neq 0 (
    echo [错误] 无法进入 backend 目录
    pause
    exit /b 1
)

echo 正在安装...
call npm install
if %errorlevel% neq 0 (
    echo [错误] 后端依赖安装失败
    cd ..
    pause
    exit /b 1
)

echo [成功] 后端依赖安装完成
cd ..

echo.
echo [2/2] 安装前端依赖...
echo ==============================
cd frontend
if %errorlevel% neq 0 (
    echo [错误] 无法进入 frontend 目录
    pause
    exit /b 1
)

echo 正在安装...
call npm install
if %errorlevel% neq 0 (
    echo [错误] 前端依赖安装失败
    cd ..
    pause
    exit /b 1
)

echo [成功] 前端依赖安装完成
cd ..

echo.
echo ╔══════════════════════════════════════════════════════════════╗
echo ║                                                              ║
echo ║           ✅ 所有依赖安装完成！                              ║
echo ║                                                              ║
echo ╚══════════════════════════════════════════════════════════════╝
echo.
echo 现在可以运行 启动.bat 启动项目
echo.
pause

