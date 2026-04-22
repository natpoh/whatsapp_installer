# WhatsApp Offline Installer & Downloader

A set of scripts designed to bypass Microsoft Store restrictions, download all required offline packages for WhatsApp Desktop, and automatically install them without an internet connection.

## 🚀 Features

- **Microsoft Store Bypass**: Fetches raw download links for UWP installation files directly via `store.rg-adguard.net`.
- **Cloudflare Evasion**: Uses Python and Playwright (Chromium browser emulation) to successfully bypass captchas and blocks that typical PowerShell curl requests cannot handle.
- **Smart Link Extraction (JSON)**: Parses the download table, automatically filtering out junk `.BlockMap` files and selecting only the required `x64` and `neutral` architectures.
- **Standalone Installer Generation**: Automatically downloads the required libraries (`Microsoft.VCLibs`, `Microsoft.WindowsAppRuntime`) and the WhatsApp `.msixbundle` itself, generating a 1-click `.bat` installer.

## 📥 How to Use

The workflow is split into two logical stages:

### Stage 1: Preparation (On a PC WITH Internet access)
1. Open PowerShell.
2. Run the download script:
   ```powershell
   .\download_whatsapp_packages.ps1
   ```
3. The script will launch the parser (either the `get_links.py` source or the compiled `get_links.exe`), bypass Cloudflare, save links to `whatsapp_links.json`, and automatically download all necessary packages into the `WhatsApp_Offline_Packages` folder.
4. An `install_whatsapp_offline.bat` auto-installer file will be pre-generated inside that folder.

### Stage 2: Offline Installation (On the target PC WITHOUT Internet)
1. Copy the entire `WhatsApp_Offline_Packages` folder to the target computer or server.
2. Run the `install_whatsapp_offline.bat` file (preferably as Administrator).
3. The script will automatically install dependencies in the correct order (VCLibs -> UI.Xaml -> WindowsAppRuntime -> WhatsAppDesktop) and launch the application.

## ⚙️ Technical Requirements for Developers
If you wish to run the parser from source or rebuild the `.exe` file:
- Python 3.10+
- `pip install playwright`
- `playwright install chromium`

*Important Note: If you want to compile a working `get_links.exe` via PyInstaller with the embedded browser, you must set the environment variable `set PLAYWRIGHT_BROWSERS_PATH=0` before compilation.*
