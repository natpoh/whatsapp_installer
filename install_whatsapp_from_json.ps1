$DownloadDir = "C:\Temp\WhatsAppInstall"
if (!(Test-Path $DownloadDir)) {
    New-Item -ItemType Directory -Path $DownloadDir | Out-Null
}

Set-Location $DownloadDir

Write-Host "1. Reading retrieved links from whatsapp_links.json..." -ForegroundColor Cyan
$LinksFile = "c:\wsl\whatsapp\whatsapp_links.json"
if (-not (Test-Path $LinksFile)) {
    Write-Error "whatsapp_links.json not found."
    exit
}

$Links = Get-Content $LinksFile -Raw | ConvertFrom-Json

Write-Host "2. Downloading packages..." -ForegroundColor Cyan
foreach ($link in $Links) {
    if ($link.filename -notmatch "BlockMap") {
        Write-Host "Downloading: $($link.filename)"
        try {
            Invoke-WebRequest -Uri $link.url -OutFile $link.filename -ErrorAction Stop
        }
        catch {
            Write-Warning "Failed to download $($link.filename)"
        }
    }
}

Write-Host "3. Installing packages in correct order..." -ForegroundColor Cyan

$InstallationOrder = @(
    "Microsoft.VCLibs*x64*Desktop.appx",
    "Microsoft.UI.Xaml*x64.appx",
    "Microsoft.WindowsAppRuntime*x64*.Msix",
    "*WhatsAppDesktop*neutral*.Msixbundle"
)

foreach ($pattern in $InstallationOrder) {
    # Sort descending to pick the highest version if multiple exist
    $files = Get-ChildItem -Path $DownloadDir -Filter $pattern | Sort-Object Name -Descending
    if ($files) {
        $f = $files[0]
        Write-Host "Installing: $($f.Name)" -ForegroundColor Green
        try {
            Add-AppxPackage -Path $f.FullName -ErrorAction Stop
        }
        catch {
            Write-Warning "Failed to install $($f.Name). Error: $_"
        }
    }
}

Write-Host "4. Starting WhatsApp..." -ForegroundColor Cyan
try {
    Start-Process "shell:AppsFolder\5319275A.WhatsAppDesktop_cv1g1gvanyjgm!App"
}
catch {
    Write-Warning "Could not start WhatsApp automatically."
}

Write-Host "Installation process complete!" -ForegroundColor Green
