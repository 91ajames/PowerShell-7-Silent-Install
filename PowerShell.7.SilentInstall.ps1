# ========================================
# Fresh Install Latest PowerShell 7 (OOBE Ready)
# SAFE DOWNLOAD + CACHE FALLBACK + CLEANUP
# ========================================

# -------------------------------
# Self-bypass Execution Policy
# -------------------------------
if ($PSVersionTable.PSVersion.Major -lt 7 -and $env:PSExecutionPolicyPreference -ne "Bypass") {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs -Wait
    exit
}

# -------------------------------
# Temp path for MSI
# -------------------------------
$tempDir = "$env:TEMP"
$tempMsiPattern = "PowerShell-*-win-x64.msi"

# -------------------------------
# Check Internet connectivity
# -------------------------------
function Test-Internet {
    try { Invoke-WebRequest -Uri "https://github.com" -UseBasicParsing -TimeoutSec 5 | Out-Null; return $true }
    catch { return $false }
}

$internetAvailable = Test-Internet

# -------------------------------
# Get installed PowerShell 7 version
# -------------------------------
function Get-InstalledPwshVersion {
    try {
        $pwshPath = Get-Command pwsh.exe -ErrorAction Stop | Select-Object -ExpandProperty Source
        $version = & $pwshPath -NoProfile -Command '$PSVersionTable.PSVersion.ToString()'
        return $version
    } catch { return $null }
}

# -------------------------------
# Clean old PowerShell 7 installations
# -------------------------------
$installedPS7 = Get-ChildItem "C:\Program Files\PowerShell" -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '^7' }
foreach ($dir in $installedPS7) {
    Remove-Item $dir.FullName -Recurse -Force -ErrorAction SilentlyContinue
}

# -------------------------------
# Clear caches and temp logs
# -------------------------------
$localCache = "$env:LOCALAPPDATA\Microsoft\PowerShell"
if (Test-Path $localCache) {
    Remove-Item $localCache -Recurse -Force -ErrorAction SilentlyContinue
}

$programDataModules = "$env:ProgramData\Microsoft\PowerShell\Modules"
if (Test-Path $programDataModules) {
    Get-ChildItem $programDataModules -Recurse | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
}

$msiLogs = Get-ChildItem "$env:TEMP" -Include "*.log","*.tmp" -Recurse -ErrorAction SilentlyContinue
foreach ($file in $msiLogs) {
    Remove-Item $file.FullName -Force -ErrorAction SilentlyContinue
}

# -------------------------------
# Detect cached MSI
# -------------------------------
$cachedMsiObj = Get-ChildItem "$tempDir\$tempMsiPattern" -File -ErrorAction SilentlyContinue |
Sort-Object LastWriteTime -Descending |
Select-Object -First 1

$cachedMsi = $cachedMsiObj?.FullName

# -------------------------------
# Initialize summary
# -------------------------------
$summary = @{
    "Action" = ""
    "InstalledVersion" = ""
}

# -------------------------------
# Fetch latest release from GitHub
# -------------------------------
if ($internetAvailable) {
    $headers = @{ "User-Agent" = "PowerShell" }

    $release = Invoke-RestMethod `
        -Uri "https://api.github.com/repos/PowerShell/PowerShell/releases/latest" `
        -Headers $headers `
        -UseBasicParsing

    $latestVersion = $release.tag_name.TrimStart("v")
    $msiAsset = $release.assets | Where-Object { $_.name -match "win-x64.msi$" }

    $msiUrl = $msiAsset.browser_download_url
    $msiSize = $msiAsset.size
}

# -------------------------------
# Decide download vs cache
# -------------------------------
$downloadMsi = $true

if ($cachedMsiObj) {
    if ($cachedMsiObj.BaseName -match "PowerShell-(\d+\.\d+\.\d+)-win-x64") {
        $cachedVersion = $matches[1]

        if ($internetAvailable) {
            if ($cachedVersion -eq $latestVersion) {
                $downloadMsi = $false
                $summary["Action"] = "Used cached MSI (latest)"
            }
        }
        else {
            $downloadMsi = $false
            $summary["Action"] = "Used cached MSI (offline, version $cachedVersion)"
        }
    }
}

# Handle no Internet + no cache
if (-not $internetAvailable -and -not $cachedMsi) {
    Write-Output "No Internet and no cached installer available."
    Start-Sleep -Seconds 3
    return
}

# -------------------------------
# SAFE Download MSI
# -------------------------------
$newMsiPath = "$tempDir\$($msiAsset.name)"
$tempDownloadPath = "$newMsiPath.download"

if ($downloadMsi) {
    try {
        Write-Output "Downloading latest MSI..."

        Invoke-WebRequest `
            -Uri $msiUrl `
            -OutFile $tempDownloadPath `
            -UseBasicParsing `
            -ErrorAction Stop

        if (Test-Path $tempDownloadPath) {
            $downloadedSize = (Get-Item $tempDownloadPath).Length

            if ($downloadedSize -ge ($msiSize * 0.9)) {
                Move-Item $tempDownloadPath $newMsiPath -Force
                $cachedMsi = $newMsiPath

                if (-not $summary["Action"]) {
                    $summary["Action"] = "Downloaded latest MSI"
                }
            }
            else {
                throw "Downloaded file too small"
            }
        }
        else {
            throw "Download failed"
        }
    }
    catch {
        Write-Output "Download failed. Falling back to cached MSI..."

        if ($cachedMsi) {
            $downloadMsi = $false
            $summary["Action"] = "Used cached MSI (download failed)"
        }
        else {
            Write-Output "No valid MSI available. Aborting."
            return
        }
    }
}

# -------------------------------
# Install
# -------------------------------
Start-Process msiexec.exe -ArgumentList "/i `"$cachedMsi`" /qn /norestart" -Wait

# -------------------------------
# OPTIONAL: Cleanup old MSI files
# Keeps only the newest one
# -------------------------------
Get-ChildItem "$tempDir\$tempMsiPattern" -File |
Sort-Object LastWriteTime -Descending |
Select-Object -Skip 1 |
Remove-Item -Force -ErrorAction SilentlyContinue

# -------------------------------
# Verification
# -------------------------------
$installedVersion = Get-InstalledPwshVersion
$summary["InstalledVersion"] = $installedVersion ? $installedVersion : "Failed"

# -------------------------------
# Summary
# -------------------------------
Write-Output "`n==== Installation Summary ===="
Write-Output "Action Taken       : $($summary["Action"])"
Write-Output "Installed Version  : $($summary["InstalledVersion"])"
Write-Output "==============================`n"

# -------------------------------
# Final Session Cleanup
# -------------------------------
Remove-Variable * -ErrorAction SilentlyContinue

Get-Command |
Where-Object { $_.CommandType -eq 'Function' -and $_.Name -notlike 'Get-*' } |
ForEach-Object {
    Remove-Item Function:\$($_.Name) -ErrorAction SilentlyContinue
}

Clear-History
Remove-Item Alias:\* -ErrorAction SilentlyContinue
Clear-Host
