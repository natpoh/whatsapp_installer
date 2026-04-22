# ========= WhatsApp Offline Downloader =========
# This script bypasses store restrictions using Playwright to download the latest WhatsApp packages.
# It saves them to a local directory for later offline installation.

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$DownloadDir = Join-Path -Path $ScriptDir -ChildPath "WhatsApp_Offline_Packages"
if (!(Test-Path $DownloadDir)) { New-Item -ItemType Directory -Path $DownloadDir | Out-Null }

Write-Host "1. Bypassing Store API blocks via Playwright engine..." -ForegroundColor Cyan
Set-Location $ScriptDir

$ExeName = "get_links.exe"
if (-not (Test-Path $ExeName)) {
    Write-Error "Could not find $ExeName! Please ensure it is in the same folder as this script."
    exit
}

Write-Host "Fetching download links via standalone browser emulation ($ExeName)..."
& .\$ExeName

if (-not (Test-Path "whatsapp_links.json")) {
    Write-Error "Failed to retrieve WhatsApp download links."
    exit
}

Write-Host "`n2. Downloading packages to $DownloadDir..." -ForegroundColor Cyan
Set-Location $DownloadDir
$Links = Get-Content "..\whatsapp_links.json" -Raw | ConvertFrom-Json
$total = $Links.Count
$current = 1

foreach ($link in $Links) {
    Write-Host "Downloading ($current/$total): $($link.filename)"
    Invoke-WebRequest -Uri $link.url -OutFile $link.filename -ErrorAction Stop
    $current++
}

$BatContent = @"
@echo off
chcp 65001 >nul
title Установка WhatsApp Desktop (Офлайн)
color 0B

echo =========================================================
echo       WhatsApp Desktop - Автономный Установщик
echo =========================================================
echo.

:: Переходим в папку скрипта, чтобы искать файлы рядом
cd /d "%~dp0"

:: Проверяем наличие скачанных файлов
if not exist *WhatsAppDesktop*msixbundle (
    color 0C
    echo ОШИБКА: Установочные пакеты WhatsApp не найдены в этой папке!
    echo Убедитесь, что вы сначала запустили скрипт скачивания.
    echo.
    pause
    exit /b 1
)

echo 1. Установка пакетов... Важен правильный порядок!
echo.

echo Установка VCLibs...
powershell -NoProfile -Command "Get-ChildItem '.' -Filter 'Microsoft.VCLibs*appx' | Sort-Object Name -Descending | ForEach-Object { Add-AppxPackage `$_.FullName }"

echo.
echo Установка UI.Xaml...
powershell -NoProfile -Command "Get-ChildItem '.' -Filter 'Microsoft.UI.Xaml*appx' | Sort-Object Name -Descending | ForEach-Object { Add-AppxPackage `$_.FullName }"

echo.
echo Установка WindowsAppRuntime...
powershell -NoProfile -Command "Get-ChildItem '.' -Filter 'Microsoft.WindowsAppRuntime*msix' | Sort-Object Name -Descending | ForEach-Object { Add-AppxPackage `$_.FullName }"

echo.
echo Установка WhatsApp Desktop...
powershell -NoProfile -Command "Get-ChildItem '.' -Filter '*WhatsAppDesktop*msixbundle' | Sort-Object Name -Descending | Select-Object -First 1 | ForEach-Object { Add-AppxPackage `$_.FullName }"

echo.
color 0A
echo =========================================================
echo       Установка завершена!
echo =========================================================
echo.

echo 2. Попытка запуска WhatsApp...
start "" "shell:AppsFolder\5319275A.WhatsAppDesktop_cv1g1gvanyjgm!App" >nul 2>&1

if %errorlevel% neq 0 (
    echo.
    echo Не удалось запустить WhatsApp автоматически. 
    echo Найдите его в меню "Пуск".
)

echo.
pause
"@

$BatPath = Join-Path -Path $DownloadDir -ChildPath "install_whatsapp_offline.bat"
Set-Content -Path $BatPath -Value $BatContent -Encoding UTF8
Write-Host "Создан автоустановщик: $BatPath" -ForegroundColor Green

Write-Host "`nAll required packages have been successfully downloaded to:" -ForegroundColor Green
Write-Host $DownloadDir
Write-Host "You can now run 'install_whatsapp_offline.bat' from this folder on any machine to install WhatsApp without an internet connection." -ForegroundColor Green
