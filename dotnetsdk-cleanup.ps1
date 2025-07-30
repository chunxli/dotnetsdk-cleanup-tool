# Function to check for latest .NET SDK version
function Get-LatestDotNetSDKVersion {
    param(
        [string]$ChannelVersion = "8.0"
    )
    
    try {
        Write-Output "Checking for latest .NET SDK version..."
        $releases = Invoke-RestMethod -Uri 'https://dotnetcli.azureedge.net/dotnet/release-metadata/releases-index.json' -Headers @{'User-Agent'='PowerShell'}
        $channel = $releases.'releases-index' | Where-Object { $_.'channel-version' -eq $ChannelVersion }
        
        if ($channel) {
            return @{
                Version = $channel.'latest-sdk'
                ReleaseDate = $channel.'latest-release-date'
            }
        }
        return $null
    }
    catch {
        Write-Warning "Failed to check for latest .NET SDK version: $_"
        return $null
    }
}

# Function to get latest SDK download URLs
function Get-LatestSDKDownloadUrls {
    param(
        [string]$ChannelVersion = "8.0"
    )
    
    try {
        $releases = Invoke-RestMethod -Uri "https://builds.dotnet.microsoft.com/dotnet/release-metadata/$ChannelVersion/releases.json" -Headers @{'User-Agent'='PowerShell'}
        $latestRelease = $releases.releases[0]
        
        if ($latestRelease.sdk) {
            $winX64 = $latestRelease.sdk.files | Where-Object { $_.name -like '*win-x64.exe' }
            $winX86 = $latestRelease.sdk.files | Where-Object { $_.name -like '*win-x86.exe' }
            
            return @{
                X64Url = if ($winX64) { $winX64.url } else { $null }
                X86Url = if ($winX86) { $winX86.url } else { $null }
                Version = $latestRelease.sdk.version
            }
        }
        return $null
    }
    catch {
        Write-Warning "Failed to get latest SDK download URLs: $_"
        return $null
    }
}

# Function to check for latest .NET Core Uninstall Tool version
function Get-LatestUninstallToolVersion {
    try {
        Write-Output "Checking for latest .NET Core Uninstall Tool version..."
        
        # Try to get the latest release page content directly
        $response = Invoke-WebRequest -Uri 'https://github.com/dotnet/cli-lab/releases/latest' -UseBasicParsing -Headers @{'User-Agent'='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'}
        
        # Look for the MSI download link in the page content
        if ($response.Content -match 'href="[^"]*dotnet-core-uninstall-([0-9]+\.[0-9]+\.[0-9]+)\.msi[^"]*"') {
            return @{
                Version = $matches[1]
                DownloadUrl = "https://github.com/dotnet/cli-lab/releases/download/$($matches[1])/dotnet-core-uninstall-$($matches[1]).msi"
            }
        }
        
        # Alternative pattern matching
        if ($response.Content -match '/dotnet-core-uninstall-([0-9]+\.[0-9]+\.[0-9]+)\.msi') {
            return @{
                Version = $matches[1]
                DownloadUrl = "https://github.com/dotnet/cli-lab/releases/download/$($matches[1])/dotnet-core-uninstall-$($matches[1]).msi"
            }
        }
        
        Write-Warning "Could not extract version from GitHub releases page"
        return $null
    }
    catch {
        Write-Warning "Failed to check for latest uninstall tool version: $_"
        return $null
    }
}
function Test-VersionUpToDate {
    param(
        [string]$CurrentVersion,
        [string]$LatestVersion
    )
    
    try {
        # Check if versions are not empty
        if ([string]::IsNullOrWhiteSpace($CurrentVersion) -or [string]::IsNullOrWhiteSpace($LatestVersion)) {
            Write-Warning "Invalid version data provided for comparison"
            return $false
        }
        
        $current = [version]$CurrentVersion
        $latest = [version]$LatestVersion
        return $current -ge $latest
    }
    catch {
        Write-Warning "Failed to compare versions: $_"
        return $false
    }
}

# Define the versions to keep
$versionsToKeep = "8.0.404"

# Check for updates and provide feedback
Write-Output "=== Checking for Updates ==="
$latestSDKInfo = Get-LatestDotNetSDKVersion -ChannelVersion "8.0"

if ($latestSDKInfo) {
    Write-Output "Current SDK version in script: $versionsToKeep"
    Write-Output "Latest available SDK version: $($latestSDKInfo.Version)"
    Write-Output "Latest release date: $($latestSDKInfo.ReleaseDate)"
    
    $isUpToDate = Test-VersionUpToDate -CurrentVersion $versionsToKeep -LatestVersion $latestSDKInfo.Version
    
    if ($isUpToDate) {
        Write-Output "✓ The SDK version in this script is up to date!"
    }
    else {
        Write-Output "⚠ WARNING: A newer SDK version is available!"
        Write-Output "  Consider updating the script to use version $($latestSDKInfo.Version)"
        
        # Get updated download URLs
        $latestUrls = Get-LatestSDKDownloadUrls -ChannelVersion "8.0"
        if ($latestUrls) {
            Write-Output "  Latest download URLs:"
            Write-Output "    x64: $($latestUrls.X64Url)"
            Write-Output "    x86: $($latestUrls.X86Url)"
        }
    }
}
else {
    Write-Output "⚠ Could not check for SDK updates. Proceeding with current version."
}

# Check uninstall tool version
$currentUninstallVersion = "1.7.550802"
$latestUninstallInfo = Get-LatestUninstallToolVersion

if ($latestUninstallInfo -and $latestUninstallInfo.Version) {
    Write-Output ""
    Write-Output "Current uninstall tool version in script: $currentUninstallVersion"
    Write-Output "Latest available uninstall tool version: $($latestUninstallInfo.Version)"
    
    $isUninstallToolUpToDate = Test-VersionUpToDate -CurrentVersion $currentUninstallVersion -LatestVersion $latestUninstallInfo.Version
    
    if ($isUninstallToolUpToDate) {
        Write-Output "✓ The uninstall tool version in this script is up to date!"
    }
    else {
        Write-Output "⚠ WARNING: A newer uninstall tool version is available!"
        Write-Output "  Consider updating the script to use version $($latestUninstallInfo.Version)"
        Write-Output "  Latest download URL: $($latestUninstallInfo.DownloadUrl)"
    }
}
else {
    Write-Output ""
    Write-Output "⚠ Could not check for uninstall tool updates. Proceeding with current version."
    Write-Output "  Current uninstall tool version in script: $currentUninstallVersion"
}

Write-Output "================================"
Write-Output ""

# Get the download links for the .NET SDK Download Page: https://dotnet.microsoft.com/en-us/download/dotnet/8.0
$sdk64Link = "https://download.visualstudio.microsoft.com/download/pr/ba3a1364-27d8-472e-a33b-5ce0937728aa/6f9495e5a587406c85af6f93b1c89295/dotnet-sdk-8.0.404-win-x64.exe"
$sdk32Link = "https://download.visualstudio.microsoft.com/download/pr/acd3875c-e28a-46a1-85fd-e99948175d90/a98148f58ddb7cc1d31305e1e5244518/dotnet-sdk-8.0.404-win-x86.exe"

# Get the link from https://github.com/dotnet/cli-lab/releases
$uninstallToolLink = "https://github.com/dotnet/cli-lab/releases/download/1.7.550802/dotnet-core-uninstall-1.7.550802.msi"

# Start recording the output to a log file
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = ".\log_$timestamp.txt"

Start-Transcript -Path $logFile

# Print the versions to keep
Write-Output "Versions to keep: $versionsToKeep" 

# Check if the version format is valid
$versionsToKeepFormatted = [version]$versionsToKeep
if (-Not ([version]::TryParse($versionsToKeepFormatted, [ref]$null))) {
    Write-Error "Invalid version format: $versionsToKeep" 
    exit 1
}

# Check if run as Admin
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "This script must be run as Administrator." 
    exit 1
}

# Print Current Location
Write-Output "Current Location: " 
Write-Output (Get-Location).Path 

# Get the path to the .NET Core Uninstall Tool
$toolPath = (Get-Command dotnet-core-uninstall.exe -ErrorAction SilentlyContinue).Source

# Install the .NET Core Uninstall Tool if it is not installed
if (-not $toolPath) {
    Write-Output "dotnet-core-uninstall.exe is not installed on $env:COMPUTERNAME" 
    Write-Output "Downloading the .NET Core Uninstall Tool from $uninstallToolLink ..."
    
    # Test Connection to the download link GitHub
    Test-NetConnection github.com -Port 443
    # Use TLS 1.2 for secure connection
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    try {
        # Added User-Agent header
        Invoke-WebRequest -Uri $uninstallToolLink -OutFile dotnet-core-uninstall.msi -UseBasicParsing -Headers @{ "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)" } -Verbose
    }
    catch {
        Write-Host "Error Message: $_"
        Write-Host "Full Exception: $($_.Exception | Format-List -Force)"
    }

    Write-Output "Installing the .NET Core Uninstall Tool ..."
    # Install the MSI file
    Start-Process msiexec.exe -ArgumentList '/i dotnet-core-uninstall.msi /quiet /norestart' -Wait
    Write-Output "Completed the installation of the .NET Core Uninstall Tool"
    Write-Output "Adding the .NET Core Uninstall Tool to the PATH ..."
    $env:Path += ";C:\Program Files (x86)\dotnet-core-uninstall"
    $toolPath = (Get-Command dotnet-core-uninstall.exe).Source
}

# dotnet core uninstall Tool Path
Write-Output "dotnet-core-uninstall tool path: "
Write-Output $toolPath

# Install Latest the Version of .NET SDK you want to keep if it is not installed.
try {
    $sdkList = dotnet --list-sdks
}
catch {
    Write-Output "No dotnet cli found"
}
$exists = $sdkList -match $versionsToKeep

if ($exists) {
    Write-Output "The .NET SDK version $versionsToKeep is installed."
}
else {
    Write-Output "The .NET SDK version $versionsToKeep is not installed."

    if ([Environment]::Is64BitOperatingSystem) {
        Write-Output "This is a 64-bit operating system."
        Write-Output "Downloading the .NET SDK from $sdk64Link"
        Invoke-WebRequest -Uri $sdk64Link -OutFile dotnet-sdk-win-x64.exe -UseBasicParsing
        Write-Output "Installing the .NET SDK"
        Start-Process -FilePath .\dotnet-sdk-win-x64.exe -ArgumentList "/install /quiet /norestart /log installation_log.txt" -Verb RunAs -Wait
        Write-Output "Completed the installation of the .NET SDK"
    }
    else {
        Write-Output "This is a 32-bit operating system."
        Write-Output "Downloading the .NET SDK from $sdk32Link"
        Invoke-WebRequest -Uri $sdk32Link -OutFile dotnet-sdk-win-x86.exe -UseBasicParsing
        Write-Output "Installing the .NET SDK"
        Start-Process -FilePath .\dotnet-sdk-win-x86.exe -ArgumentList "/install /quiet /norestart /log installation_log.txt" -Verb RunAs -Wait
        Write-Output "Completed the installation of the .NET SDK"
    }
}

# Reload Path environment variables
$Env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
$dncli = (Get-Command dotnet.exe).Source

# List the installed .NET SDKs after installation
Write-Output ""
Write-Output "Listing the installed .NET SDKs and Runtimes after installation:"
Write-Output "dotnet --list-sdks"
Write-Output (& $dncli --list-sdks )
Write-Output "dotnet --list-runtimes"
Write-Output (& $dncli --list-runtimes ) 

# Uninstall old .NET SDKs
Write-Output ""
Write-Output "Uninstalling old .NET SDKs ..."
Write-Output (& $toolPath remove --all-below $versionsToKeep --sdk --yes --force --verbosity diagnostic )
Write-Output (& $toolPath remove --all-below $versionsToKeep --runtime --yes --force --verbosity diagnostic )
Write-Output (& $toolPath remove --all-below $versionsToKeep --aspnet-runtime --yes --force --verbosity diagnostic )
Write-Output (& $toolPath remove --all-below $versionsToKeep --hosting-bundle --yes --force --verbosity diagnostic )

Write-Output ""
Write-Output "dotnet-core-uninstall list:"
Write-Output (& $toolPath list)

# List the installed .NET SDKs after uninstallation
Write-Output ""
Write-Output "Listing the installed .NET SDKs and Runtimes after uninstallation:"
Write-Output "dotnet --list-sdks"
Write-Output (& $dncli --list-sdks)
Write-Output "dotnet --list-runtimes"
Write-Output (& $dncli --list-runtimes)

# 
# Clean up remaining runtime folders if any
# Clean the .NET runtime folders that are older than the versions to keep (Major version)
#
Write-Output ""
Write-Output "Cleaning up remaining runtime folders ..."
Write-Output "Version (Major) to keep: $($versionsToKeepFormatted.Major) "
Write-Output "Cleaning up runtime folders that are older than the versions to keep (Major version) ..."

# Define potential .NET folder paths for 64-bit and 32-bit Windows
# Set the default Program Files paths
$dotnet64 = "C:\Program Files\dotnet"
$dotnet32 = "C:\Program Files (x86)\dotnet"

$existDotnet64 = Test-Path $dotnet64
$existDotnet32 = Test-Path $dotnet64

if ($existDotnet64) {
    Write-Output ".NET Root exists: $dotnet64"
}
else {
    Write-Output ".NET Root doesn't exist: $dotnet64"
}

if ($existDotnet32) {
    Write-Output ".NET Root exists: $dotnet32"
}
else {
    Write-Output ".NET Root doesn't exist: $dotnet32"
}

if (-not ($existDotnet64 -or $existDotnet32)) {
    Write-Output "No .NET Root found in default paths: $dotnet64 or $dotnet32. Attempting to find the .NET executable."
    Write-Output "Searching for dotnet executable in the system PATH..."

    $dotnetExePath = where.exe dotnet 2>$null | Select-Object -First 1

    if ($dotnetExePath) {
        Write-Output "Found dotnet executable at: $dotnetExePath"
    }
    else {
        Write-Output "No dotnet executable found in the system PATH."
    }

    $dotnetRootPath = [System.IO.Path]::GetDirectoryName($dotnetExePath)
    Write-Output "Extracting .NET root path from dotnet executable path: $dotnetRootPath"
    $dotnet64 = $dotnetRootPath
    $dotnet32 = $dotnetRootPath -replace "Program Files", "Program Files (x86)"
}

Write-Output "64-bit .NET Root: $dotnet64"
Write-Output "32-bit .NET Root: $dotnet32"

$dotnetPaths = @(
    "$dotnet64", # 64-bit .NET location
    "$dotnet32"          # 32-bit .NET location
)

# Check if any .NET processes are running
$processes = Get-Process | Where-Object { $_.Path -like "*dotnet*" }
if ($processes) {
    Write-Host "There are .NET processes running which may prevent runtime cleanup."
    $processes | ForEach-Object {
        Write-Host "Process found: $($_.Name) with PID: $($_.Id)"
    }
}
else {
    Write-Host "No .NET processes are running."
}

foreach ($dotnetPath in $dotnetPaths) {
    # Check if the .NET folder exists
    if (-Not (Test-Path -Path $dotnetPath)) {
        Write-Warning "The path '$dotnetPath' does not exist. Skipping..."
        continue
    }

    Write-Host "Processing .NET folder: $dotnetPath"

    # Navigate to the 'shared' folder
    $sharedFolderPath = Join-Path -Path $dotnetPath -ChildPath "shared"

    # Check if the shared folder exists
    if (-Not (Test-Path -Path $sharedFolderPath)) {
        Write-Warning "The shared folder '$sharedFolderPath' does not exist. Skipping..."
        continue
    }

    # Get all runtime folders under 'shared'
    $runtimeFolders = Get-ChildItem -Path $sharedFolderPath -Directory

    Write-Host "Viewing .NET folder: $dotnetPath"
    foreach ($runtimeFolder in $runtimeFolders) {
        # Get all version subdirectories
        $versionFolders = Get-ChildItem -Path $runtimeFolder.FullName -Directory
        foreach ($versionFolder in $versionFolders) {
            Write-Host "Version folder: $($versionFolder.FullName)"
        }
    }

    Write-Host "Start to cleanup ..."
    foreach ($runtimeFolder in $runtimeFolders) {

        # Get all version subdirectories
        $versionFolders = Get-ChildItem -Path $runtimeFolder.FullName -Directory

        foreach ($versionFolder in $versionFolders) {
 
            # Extract the version number from the folder name
            if ([version]::TryParse($versionFolder.Name, [ref]$null)) {
                $version = [version]$versionFolder.Name

                # Check if the version is less than Major version of the version to keep
                if ($version.Major -lt $versionsToKeepFormatted.Major) {
                    Write-Host "Removing folder: $($versionFolder.FullName)"
                    try {
                        Remove-Item -Path $versionFolder.FullName -Recurse -Force -Verbose
                        # Wait a bit before checking again
                        Start-Sleep -Seconds 1  
                        # Check if the folder still exists
                        if (Test-Path $versionFolder.FullName) {
                            Write-Host "The folder $($versionFolder.FullName) still exists after removal."
                        }
                        else {
                            Write-Host "Successfully removed $($versionFolder.FullName)."
                        }
                    }
                    catch {
                        Write-Error "Failed to remove folder: $($versionFolder.FullName). Error: $_"
                    }
                    
                }
            }
            else {
                Write-Warning "Skipping invalid version folder: $($versionFolder.FullName)"
            }
        }
    }

    Write-Host "Cleanup completed for .NET folder: $dotnetPath"

    Write-Host "Reviewing .NET folder: $dotnetPath"
    foreach ($runtimeFolder in $runtimeFolders) {
        # Get all version subdirectories
        $versionFolders = Get-ChildItem -Path $runtimeFolder.FullName -Directory
        foreach ($versionFolder in $versionFolders) {
            Write-Host "Version folder: $($versionFolder.FullName)"
        }
    }
}

Write-Host "Cleanup completed."

# List the installed .NET SDKs after cleanup
Write-Output "Listing the installed .NET SDKs and Runtimes after cleanup:"
Write-Output "dotnet --list-sdks"
Write-Output (& $dncli --list-sdks)
Write-Output "dotnet --list-runtimes"
Write-Output (& $dncli --list-runtimes)

# End recording the output
Stop-Transcript
