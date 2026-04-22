# PowerShell Script to Download and Install WhatsApp Desktop
# Based on store.rg-adguard.net API

$StoreURL = "https://apps.microsoft.com/detail/whatsapp/9NKSQGP7F2NH"
$DownloadDir = "C:\Temp\WhatsAppInstall"

if (!(Test-Path $DownloadDir)) {
    New-Item -ItemType Directory -Path $DownloadDir | Out-Null
}

Set-Location $DownloadDir

Write-Host "1. Fetching download links from store.rg-adguard.net..." -ForegroundColor Cyan
$wchttp = [System.Net.WebClient]::new()
$URI = "https://ru.store.rg-adguard.net/api/GetFiles"
$myParameters = "type=url&url=$($StoreURL)"
$wchttp.Headers[[System.Net.HttpRequestHeader]::ContentType] = "application/x-www-form-urlencoded"

try {
    $HtmlResult = $wchttp.UploadString($URI, $myParameters)
} catch {
    Write-Error "Failed to connect to the store API."
    exit
}

if ($HtmlResult.IndexOf("The links were successfully received") -eq -1) {
    Write-Error "Error: Could not retrieve links from server."
    exit
}

# Parse HTML links
$newHtml = New-Object -ComObject "HTMLFile"
try {
    $newHtml.IHTMLDocument2_write($HtmlResult)
} catch {
    $src = [System.Text.Encoding]::Unicode.GetBytes($HtmlResult)
    $newHtml.write($src)
}

$ToDownload = $newHtml.getElementsByTagName("a") | Select-Object textContent, href

Write-Host "2. Downloading necessary packages..." -ForegroundColor Cyan
$incl = @('x64', 'neutral')
$excl = @('blockmap')
$regex_incl = [string]::Join('|', $incl)
$regex_excl = [string]::Join('|', $excl)

foreach ($Download in $ToDownload) {
    if ($Download.textContent -match $regex_incl -and $Download.textContent -notmatch $regex_excl) {
        # Filter for relevant components
        if ($Download.textContent -match "WhatsAppDesktop|VCLibs|UI.Xaml|WindowsAppRuntime") {
            Write-Host "Downloading: $($Download.textContent)" -ForegroundColor Yellow
            try {
                Invoke-WebRequest -Uri $Download.href -OutFile $Download.textContent -ErrorAction Stop
            } catch {
                Write-Warning "Failed to download $($Download.textContent)"
            }
        }
    }
}

Write-Host "3. Installing packages in correct order..." -ForegroundColor Cyan

# Define installation order
$InstallationOrder = @(
    "Microsoft.VCLibs*x64*Desktop.appx",
    "Microsoft.UI.Xaml*x64.appx",
    "Microsoft.WindowsAppRuntime*x64*.Msix",
    "*WhatsAppDesktop*neutral*.Msixbundle"
)

foreach ($pattern in $InstallationOrder) {
    $files = Get-ChildItem -Path $DownloadDir -Filter $pattern
    foreach ($f in $files) {
        Write-Host "Installing: $($f.Name)" -ForegroundColor Green
        try {
            Add-AppxPackage -Path $f.FullName -ErrorAction Stop
        } catch {
            Write-Warning "Failed to install $($f.Name). It might already be installed or require a newer version."
        }
    }
}

Write-Host "4. Starting WhatsApp..." -ForegroundColor Cyan
try {
    Start-Process "shell:AppsFolder\5319275A.WhatsAppDesktop_cv1g1gvanyjgm!App"
} catch {
    Write-Warning "Could not start WhatsApp automatically. Please search for it in the Start menu."
}

Write-Host "Installation process complete!" -ForegroundColor Green
