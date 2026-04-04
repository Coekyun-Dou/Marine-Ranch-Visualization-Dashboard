@echo off
title 极简启动
color 0A

echo.
echo ========================================
echo   极简启动 - 跳过所有检查
echo ========================================
echo.
echo 当前目录: %cd%
echo.
echo 按任意键开始启动...
pause >nul

echo.
echo 正在启动后端...
start "后端" cmd /k "cd /d %~dp0backend && npm start"

echo 等待 3 秒...
timeout /t 3 >nul

echo 正在启动前端...
start "前端" cmd /k "cd /d %~dp0frontend && npm run dev"

echo.
echo ========================================
echo 启动完成！
echo ========================================
echo.
echo 访问: http://localhost:5173
echo 账号: admin / 123456
echo.
echo 如果启动失败，查看弹出窗口的错误信息
echo.
pause

