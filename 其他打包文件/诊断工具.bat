@echo off
chcp 65001 >nul 2>nul
title 诊断工具
color 0E

echo.
echo ╔══════════════════════════════════════════════════════════════╗
echo ║                                                              ║
echo ║           智慧海洋牧场 - 系统诊断工具                       ║
echo ║                                                              ║
echo ╚══════════════════════════════════════════════════════════════╝
echo.
echo 此工具将帮助诊断启动问题
echo.
pause

echo.
echo ==============================
echo 诊断 1/7: 检查当前目录
echo ==============================
echo 当前目录: %cd%
echo.

if exist "backend" (
    echo [✓ 通过] backend 目录存在
) else (
    echo [✗ 失败] backend 目录不存在！
    echo [原因] 可能不在项目根目录
)

if exist "frontend" (
    echo [✓ 通过] frontend 目录存在
) else (
    echo [✗ 失败] frontend 目录不存在！
    echo [原因] 可能不在项目根目录
)

if exist "package.json" (
    echo [✓ 通过] package.json 存在
) else (
    echo [✗ 失败] package.json 不存在！
)

echo.
pause

echo.
echo ==============================
echo 诊断 2/7: 检查 Node.js
echo ==============================
where node >nul 2>nul
if %errorlevel% equ 0 (
    echo [✓ 通过] Node.js 已安装
    node -v
    echo.
    where npm >nul 2>nul
    if %errorlevel% equ 0 (
        echo [✓ 通过] npm 已安装
        npm -v
    ) else (
        echo [✗ 失败] npm 未安装！
    )
) else (
    echo [✗ 失败] Node.js 未安装！
    echo.
    echo [解决方案]
    echo 1. 访问 https://nodejs.org/
    echo 2. 下载 LTS 版本
    echo 3. 安装完成后重启电脑
    echo 4. 重新运行此诊断
)

echo.
pause

echo.
echo ==============================
echo 诊断 3/7: 检查后端依赖
echo ==============================
if exist "backend\node_modules" (
    echo [✓ 通过] 后端依赖已安装
    if exist "backend\node_modules\express" (
        echo   [✓] express: 已安装
    ) else (
        echo   [✗] express: 未安装
    )
    if exist "backend\node_modules\socket.io" (
        echo   [✓] socket.io: 已安装
    ) else (
        echo   [✗] socket.io: 未安装
    )
    if exist "backend\node_modules\axios" (
        echo   [✓] axios: 已安装 (AI功能)
    ) else (
        echo   [!] axios: 未安装 (AI功能将无法使用)
        echo   [提示] 运行 安装axios.bat
    )
) else (
    echo [✗ 失败] 后端依赖未安装
    echo [解决方案] 运行: cd backend ^&^& npm install
)

echo.
pause

echo.
echo ==============================
echo 诊断 4/7: 检查前端依赖
echo ==============================
if exist "frontend\node_modules" (
    echo [✓ 通过] 前端依赖已安装
    if exist "frontend\node_modules\vue" (
        echo   [✓] vue: 已安装
    ) else (
        echo   [✗] vue: 未安装
    )
    if exist "frontend\node_modules\three" (
        echo   [✓] three: 已安装 (3D地球)
    ) else (
        echo   [✗] three: 未安装
    )
) else (
    echo [✗ 失败] 前端依赖未安装
    echo [解决方案] 运行: cd frontend ^&^& npm install
)

echo.
pause

echo.
echo ==============================
echo 诊断 5/7: 检查端口占用
echo ==============================
netstat -ano | findstr :3000 > nul 2>nul
if %errorlevel% equ 0 (
    echo [! 警告] 端口 3000 已被占用
    echo.
    echo 占用进程:
    netstat -ano | findstr :3000
    echo.
    echo [解决方案] 运行 关闭占用端口.bat
) else (
    echo [✓ 通过] 端口 3000 空闲
)

echo.

netstat -ano | findstr :5173 > nul 2>nul
if %errorlevel% equ 0 (
    echo [! 警告] 端口 5173 已被占用
    echo.
    echo 占用进程:
    netstat -ano | findstr :5173
    echo.
    echo [解决方案] 运行 关闭占用端口.bat
) else (
    echo [✓ 通过] 端口 5173 空闲
)

echo.
pause

echo.
echo ==============================
echo 诊断 6/7: 检查文件权限
echo ==============================
cd backend >nul 2>nul
if %errorlevel% equ 0 (
    echo [✓ 通过] 可以进入 backend 目录
    cd ..
) else (
    echo [✗ 失败] 无法进入 backend 目录
    echo [原因] 可能是权限问题
)

cd frontend >nul 2>nul
if %errorlevel% equ 0 (
    echo [✓ 通过] 可以进入 frontend 目录
    cd ..
) else (
    echo [✗ 失败] 无法进入 frontend 目录
    echo [原因] 可能是权限问题
)

echo.
pause

echo.
echo ==============================
echo 诊断 7/7: 检查启动脚本
echo ==============================
if exist "backend\package.json" (
    echo [✓ 通过] backend\package.json 存在
    findstr "\"start\"" backend\package.json >nul
    if %errorlevel% equ 0 (
        echo [✓ 通过] npm start 脚本已配置
    ) else (
        echo [✗ 失败] 未找到 start 脚本
    )
) else (
    echo [✗ 失败] backend\package.json 不存在
)

echo.

if exist "frontend\package.json" (
    echo [✓ 通过] frontend\package.json 存在
    findstr "\"dev\"" frontend\package.json >nul
    if %errorlevel% equ 0 (
        echo [✓ 通过] npm run dev 脚本已配置
    ) else (
        echo [✗ 失败] 未找到 dev 脚本
    )
) else (
    echo [✗ 失败] frontend\package.json 不存在
)

echo.
echo ==============================
echo   诊断完成！
echo ==============================
echo.
echo [下一步]
echo.
echo 如果所有检查都通过:
echo   - 运行 启动.bat
echo.
echo 如果有检查失败:
echo   1. 根据提示解决问题
echo   2. 重新运行此诊断工具
echo   3. 将错误信息截图反馈
echo.
echo 常见问题解决:
echo   - Node.js未安装: 访问 nodejs.org 下载安装
echo   - 依赖未安装: 分别进入 backend 和 frontend 运行 npm install
echo   - axios未安装: 运行 安装axios.bat
echo   - 端口被占用: 运行 关闭占用端口.bat
echo.
pause
