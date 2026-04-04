@echo off
chcp 65001 >nul
title 关闭占用的端口
color 0C

echo.
echo ╔══════════════════════════════════════════════════════════════╗
echo ║                                                              ║
echo ║              🔴 关闭占用的3000和5173端口 🔴                  ║
echo ║                                                              ║
echo ╚══════════════════════════════════════════════════════════════╝
echo.

echo [提示] 正在查找占用端口的进程...
echo.

REM 查找占用3000端口的进程
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo  端口 3000（后端服务）
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

netstat -ano | findstr :3000 > nul
if %errorlevel% equ 0 (
    echo [找到] 端口 3000 正在被使用
    echo.
    netstat -ano | findstr :3000
    echo.
    
    for /f "tokens=5" %%a in ('netstat -ano ^| findstr :3000') do (
        echo [操作] 正在关闭进程 PID: %%a
        taskkill /F /PID %%a >nul 2>nul
        if %errorlevel% equ 0 (
            echo [✓] 进程 %%a 已关闭
        ) else (
            echo [!] 进程 %%a 无法关闭（可能需要管理员权限）
        )
    )
) else (
    echo [i] 端口 3000 未被占用
)
echo.

REM 查找占用5173端口的进程
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo  端口 5173（前端服务）
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

netstat -ano | findstr :5173 > nul
if %errorlevel% equ 0 (
    echo [找到] 端口 5173 正在被使用
    echo.
    netstat -ano | findstr :5173
    echo.
    
    for /f "tokens=5" %%a in ('netstat -ano ^| findstr :5173') do (
        echo [操作] 正在关闭进程 PID: %%a
        taskkill /F /PID %%a >nul 2>nul
        if %errorlevel% equ 0 (
            echo [✓] 进程 %%a 已关闭
        ) else (
            echo [!] 进程 %%a 无法关闭（可能需要管理员权限）
        )
    )
) else (
    echo [i] 端口 5173 未被占用
)
echo.

echo ╔══════════════════════════════════════════════════════════════╗
echo ║                      ✅ 操作完成                             ║
echo ╚══════════════════════════════════════════════════════════════╝
echo.
echo [提示] 现在可以运行 start.bat 启动项目了
echo.

pause



