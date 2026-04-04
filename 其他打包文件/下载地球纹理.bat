@echo off
chcp 65001 >nul
title 下载高清地球纹理
color 0B

echo.
echo ╔══════════════════════════════════════════════════════════════╗
echo ║                                                              ║
echo ║           🌍 下载 4K/2K 高清真实地球纹理 🌍                ║
echo ║                                                              ║
echo ╚══════════════════════════════════════════════════════════════╝
echo.

set "TARGET_DIR=frontend\public\textures"

if not exist "%TARGET_DIR%" (
    echo [创建目录] %TARGET_DIR%
    mkdir "%TARGET_DIR%"
)

echo [提示] 正在从 GitHub/CDN 下载纹理资源...
echo [提示] 如果下载失败，请检查网络连接
echo.

REM 定义下载链接 (使用 Three.js 官方示例资源)
set "URL_MAP=https://raw.githubusercontent.com/mrdoob/three.js/dev/examples/textures/planets/earth_atmos_2048.jpg"
set "URL_SPEC=https://raw.githubusercontent.com/mrdoob/three.js/dev/examples/textures/planets/earth_specular_2048.jpg"
set "URL_NORM=https://raw.githubusercontent.com/mrdoob/three.js/dev/examples/textures/planets/earth_normal_2048.jpg"
set "URL_CLOUD=https://raw.githubusercontent.com/mrdoob/three.js/dev/examples/textures/planets/earth_clouds_1024.png"

echo [1/4] 下载地表纹理 (Diffuse Map)...
curl -L "%URL_MAP%" -o "%TARGET_DIR%\earth_map.jpg" --ssl-no-revoke
if %errorlevel% neq 0 (
    echo [!] 下载失败，尝试备用源...
    curl -L "https://threejs.org/examples/textures/planets/earth_atmos_2048.jpg" -o "%TARGET_DIR%\earth_map.jpg"
)

echo [2/4] 下载高光纹理 (Specular Map - 用于海洋反光)...
curl -L "%URL_SPEC%" -o "%TARGET_DIR%\earth_spec.jpg" --ssl-no-revoke

echo [3/4] 下载法线纹理 (Normal Map - 用于地形凹凸)...
curl -L "%URL_NORM%" -o "%TARGET_DIR%\earth_normal.jpg" --ssl-no-revoke

echo [4/4] 下载云层纹理 (Cloud Map)...
curl -L "%URL_CLOUD%" -o "%TARGET_DIR%\earth_clouds.png" --ssl-no-revoke

echo.
echo ╔══════════════════════════════════════════════════════════════╗
echo ║                     ✅ 下载完成！                            ║
echo ╚══════════════════════════════════════════════════════════════╝
echo.
echo [检查] 请确认 frontend\public\textures 目录下有 4 张图片
echo.

pause



