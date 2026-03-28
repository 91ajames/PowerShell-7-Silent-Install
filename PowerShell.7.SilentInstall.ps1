# ========================================
# Fresh Install Latest PowerShell 7 (OOBE Ready)
# Smart Cached MSI, Auto-Delete Old Offline Files, Detailed Summary
# ========================================

# Requires Administrator privileges

$tempDir = "$env:TEMP"
$tempMsiPattern = "PowerShell-*-win-x64.msi"

# Function: Check Internet connectivity
function Test-Internet {
    try { Invoke-WebRequest -Uri "https://github.com" -UseBasicParsing -TimeoutSec 5 | Out-Null; return $true }
    catch { return $false }
}

$internetAvailable = Test-Internet

# Function: Get installed PowerShell 7 version
function Get-InstalledPwshVersion {
    try {
        $pwshPath = Get-Command pwsh.exe -ErrorAction Stop | Select-Object -ExpandProperty Source
        $version = & $pwshPath -NoProfile -Command '$PSVersionTable.PSVersion.ToString()'
        return $version
    } catch { return $null }
}

# Remove old PS7 installations
$installedPS7 = Get-ChildItem "C:\Program Files\PowerShell" -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '^7' }
foreach ($dir in $installedPS7) { Remove-Item $dir.FullName -Recurse -Force -ErrorAction SilentlyContinue }

# Clear module caches & temp logs
$localCache = "$env:LOCALAPPDATA\Microsoft\PowerShell"
if (Test-Path $localCache) { Remove-Item $localCache -Recurse -Force -ErrorAction SilentlyContinue }
$programDataModules = "$env:ProgramData\Microsoft\PowerShell\Modules"
if (Test-Path $programDataModules) { Get-ChildItem $programDataModules -Recurse | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue }
$msiLogs = Get-ChildItem "$env:TEMP" -Include "*.log","*.tmp" -Recurse -ErrorAction SilentlyContinue
foreach ($file in $msiLogs) { Remove-Item $file.FullName -Force -ErrorAction SilentlyContinue }

# Detect cached MSI
$cachedMsi = Get-ChildItem "$tempDir\$tempMsiPattern" -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1

# Initialize summary
$summary = @{
    "Action" = ""
    "InstalledVersion" = ""
}

# Fetch latest release info if Internet is available
if ($internetAvailable) {
    $headers = @{ "User-Agent" = "PowerShell" }
    $release = Invoke-RestMethod -Uri "https://api.github.com/repos/PowerShell/PowerShell/releases/latest" -Headers $headers -UseBasicParsing
    $latestVersion = $release.tag_name.TrimStart("v")
    $msiAsset = $release.assets | Where-Object { $_.name -match "win-x64.msi$" }
    $msiUrl = $msiAsset.browser_download_url
    $msiSizeMB = [math]::Round($msiAsset.size / 1MB, 2)
}

$downloadMsi = $true

if ($cachedMsi) {
    if ($cachedMsi.BaseName -match "PowerShell-(\d+\.\d+\.\d+)-win-x64") {
        $cachedVersion = $matches[1]

        if ($internetAvailable) {
            if ($cachedVersion -eq $latestVersion) {
                $downloadMsi = $false
                $summary["Action"] = "Used cached MSI (latest)"
            } else {
                Remove-Item $cachedMsi.FullName -Force
                $summary["Action"] = "Deleted old cached MSI and downloaded latest"
            }
        } else {
            $downloadMsi = $false
            $summary["Action"] = "Used cached MSI (offline, version $cachedVersion)"
        }
    }
}

# Handle no Internet + no cached MSI
if (-not $internetAvailable -and -not $cachedMsi) {
    Write-Output "Check Internet"
    Start-Sleep -Seconds 3
    return
}

# Download MSI if required
if ($downloadMsi) {
    Invoke-WebRequest -Uri $msiUrl -OutFile "$tempDir\$msiAsset.name" -UseBasicParsing
    $cachedMsi = "$tempDir\$msiAsset.name"
    if (-not $summary["Action"]) { $summary["Action"] = "Downloaded latest MSI" }
}

# Silent Install
Start-Process msiexec.exe -ArgumentList "/i `"$cachedMsi`" /qn /norestart" -Wait

# Cleanup if downloaded
if ($downloadMsi -and Test-Path $cachedMsi) { Remove-Item $cachedMsi -Force }

# Verification
$installedVersion = Get-InstalledPwshVersion
$summary["InstalledVersion"] = $installedVersion ? $installedVersion : "Failed"

# Final Summary
Write-Output "`n==== Installation Summary ===="
Write-Output "Action Taken       : $($summary["Action"])"
Write-Output "Installed Version  : $($summary["InstalledVersion"])"
Write-Output "==============================`n"
