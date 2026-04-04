@echo off
chcp 65001 >nul 2>nul
title 检查 AI 助手功能
color 0D

echo.
echo ╔══════════════════════════════════════════════════════════════╗
echo ║                                                              ║
echo ║           AI 助手功能 - 环境检查工具                        ║
echo ║                                                              ║
echo ╚══════════════════════════════════════════════════════════════╝
echo.

REM 进入后端目录
cd backend
if %errorlevel% neq 0 (
    echo [✗ 错误] 无法进入 backend 目录
    pause
    exit /b 1
)

echo [检查 1/3] 检查 axios 依赖...
echo.

REM 检查 axios 是否安装
if exist "node_modules\axios" (
    echo [✓ 通过] axios 已安装
) else (
    echo [✗ 失败] axios 未安装
    echo [修复] 正在安装 axios...
    call npm install axios
    if %errorlevel% equ 0 (
        echo [✓ 成功] axios 安装完成
    ) else (
        echo [✗ 失败] axios 安装失败
    )
)

echo.
echo [检查 2/3] 检查 package.json 配置...
echo.

REM 检查 package.json 中是否有 axios
findstr "axios" package.json >nul
if %errorlevel% equ 0 (
    echo [✓ 通过] package.json 中已配置 axios
) else (
    echo [! 警告] package.json 中未找到 axios 配置
)

cd ..

echo.
echo [检查 3/3] 检查前端路由配置...
echo.

REM 检查前端路由
findstr "AIAssistant" frontend\src\router\index.js >nul
if %errorlevel% equ 0 (
    echo [✓ 通过] 前端路由已配置 AI 助手
) else (
    echo [✗ 失败] 前端路由未配置 AI 助手
)

echo.
echo ==============================
echo   检查完成！
echo ==============================
echo.
echo [下一步]
echo 1. 如果 axios 未安装，已自动安装
echo 2. 重新启动后端和前端服务
echo 3. 访问 http://localhost:5173/ai-assistant
echo.
echo [常见问题]
echo - 页面空白: 按 Ctrl+F5 强制刷新
echo - 无法连接: 检查后端是否启动
echo - 网络错误: AI 功能需要互联网连接
echo.
pause

