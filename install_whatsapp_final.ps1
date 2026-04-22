# ========= WhatsApp Installer via Playwright Bypass =========
# This script uses a built-in Python Playwright snippet to act as an emulator,
# bypassing the store.rg-adguard.net blocks, downloading the packages, and installing them.

$DownloadDir = "C:\Temp\WhatsAppInstall"
if (!(Test-Path $DownloadDir)) { New-Item -ItemType Directory -Path $DownloadDir | Out-Null }
Set-Location $DownloadDir

Write-Host "1. Setting up Python environment to bypass Store API blocks..." -ForegroundColor Cyan
# Set up a lightweight virtual environment to avoid installing packages globally
if (!(Test-Path ".venv")) {
    python -m venv .venv
}
& .\.venv\Scripts\Activate.ps1
Write-Host "Installing/Verifying Playwright (this might take a minute on first run)..."
pip install playwright --quiet
playwright install chromium --quiet

$pythonScript = @"
import json, sys
from playwright.sync_api import sync_playwright

def main():
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page()
        page.goto('https://store.rg-adguard.net/', wait_until='networkidle')
        page.locator('input[type="text"]').fill('https://apps.microsoft.com/detail/whatsapp/9NKSQGP7F2NH')
        page.locator('input[type="button"], button, input[value="✔"], #btn-submit').first.click()
        
        try:
            page.wait_for_selector('table', timeout=30000)
            page.wait_for_function('document.querySelectorAll("table a").length > 0', timeout=30000)
        except Exception as e:
            print(f"Error extracting DOM results: {e}")
            sys.exit(1)
            
        links = page.locator('table a').element_handles()
        download_list = []
        for link in links:
            text = link.inner_text()
            href = link.get_attribute('href')
            # Filter specific packages
            if ('x64' in text or 'neutral' in text) and 'blockmap' not in text.lower():
                if 'WhatsAppDesktop' in text or 'VCLibs' in text or 'UI.Xaml' in text or 'WindowsAppRuntime' in text:
                    print(f"Discovered package: {text}")
                    download_list.append({"filename": text, "url": href})
                    
        with open('whatsapp_links.json', 'w', encoding='utf-8') as f:
            json.dump(download_list, f, indent=4)
        browser.close()

if __name__ == '__main__':
    main()
"@

Set-Content -Path "get_links.py" -Value $pythonScript
Write-Host "Fetching download links via headless browser emulation..."
python get_links.py

if (-not (Test-Path "whatsapp_links.json")) {
    Write-Error "Failed to retrieve WhatsApp download links."
    exit
}

Write-Host "`n2. Downloading packages..." -ForegroundColor Cyan
$Links = Get-Content "whatsapp_links.json" -Raw | ConvertFrom-Json
foreach ($link in $Links) {
    # Skip redownloading if file already fully exists (basic size check could be added, here we just overwrite)
    Write-Host "Downloading: $($link.filename)"
    Invoke-WebRequest -Uri $link.url -OutFile $link.filename -ErrorAction Stop
}

Write-Host "`n3. Installing packages in correct order..." -ForegroundColor Cyan
$InstallationOrder = @(
    "Microsoft.VCLibs*.appx",
    "Microsoft.UI.Xaml*.appx",
    "Microsoft.WindowsAppRuntime*.msix",
    "*WhatsAppDesktop*.msixbundle"
)

foreach ($pattern in $InstallationOrder) {
    # Sort descending to pick the newest build format
    $files = Get-ChildItem -Path $DownloadDir -Filter $pattern | Sort-Object Name -Descending
    if ($files) {
        $f = $files[0]
        Write-Host "Installing: $($f.Name)" -ForegroundColor Green
        try { 
            Add-AppxPackage -Path $f.FullName -ErrorAction Stop 
        }
        catch { 
            Write-Warning "Skipped $($f.Name) (might be already installed or a newer version exists)."
        }
    }
}

Write-Host "`n4. Starting WhatsApp..." -ForegroundColor Cyan
try { Start-Process "shell:AppsFolder\5319275A.WhatsAppDesktop_cv1g1gvanyjgm!App" } catch {}

Write-Host "WhatsApp Installation pipeline complete!" -ForegroundColor Green
