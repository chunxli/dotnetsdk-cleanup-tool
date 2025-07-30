# dotnetsdk-cleanup-tool

This PowerShell script helps clean up old .NET SDK installations on Windows, keeping only the specified version. The script now includes **automatic update checking** to ensure you're using the latest versions.

## Features

- ✅ **Automatic Update Checking**: Checks if the .NET SDK version in the script is up-to-date
- ✅ **Smart Version Management**: Keeps specified .NET SDK version and removes older ones
- ✅ **Automatic Tool Installation**: Downloads and installs the .NET Core Uninstall Tool if needed
- ✅ **Comprehensive Cleanup**: Removes old SDKs, runtimes, and runtime folders
- ✅ **Detailed Logging**: Creates timestamped log files of all operations

## Update Checking

When you run the script, it will:
1. Check the latest available .NET SDK version from Microsoft's official API
2. Compare it with the version specified in the script
3. Provide warnings and download URLs if a newer version is available
4. Attempt to check for newer versions of the .NET Core Uninstall Tool

## Define the versions to keep | Set the version you want to keep on the device
```
$versionsToKeep = "8.0.404"
```

## Get the download links for the .NET SDK Download Page: https://dotnet.microsoft.com/en-us/download/dotnet/8.0
```
$sdk64Link = "https://download.visualstudio.microsoft.com/download/pr/ba3a1364-27d8-472e-a33b-5ce0937728aa/6f9495e5a587406c85af6f93b1c89295/dotnet-sdk-8.0.404-win-x64.exe"
$sdk32Link = "https://download.visualstudio.microsoft.com/download/pr/acd3875c-e28a-46a1-85fd-e99948175d90/a98148f58ddb7cc1d31305e1e5244518/dotnet-sdk-8.0.404-win-x86.exe"
```

## Get the link from https://github.com/dotnet/cli-lab/releases
```
$uninstallToolLink = "https://github.com/dotnet/cli-lab/releases/download/1.7.550802/dotnet-core-uninstall-1.7.550802.msi"
```

## Usage

1. **Run as Administrator** - The script requires administrator privileges
2. **Review Update Warnings** - Check the output for any available updates before proceeding
3. **Customize Versions** - Modify the `$versionsToKeep` variable to specify which version to keep
4. **Execute the Script** - The script will handle the rest automatically

## Sample Output

```
=== Checking for Updates ===
Current SDK version in script: 8.0.404
Latest available SDK version: 8.0.412
Latest release date: 2025-07-08
⚠ WARNING: A newer SDK version is available!
  Consider updating the script to use version 8.0.412
  Latest download URLs:
    x64: https://builds.dotnet.microsoft.com/dotnet/Sdk/8.0.412/dotnet-sdk-8.0.412-win-x64.exe
    x86: https://builds.dotnet.microsoft.com/dotnet/Sdk/8.0.412/dotnet-sdk-8.0.412-win-x86.exe
================================
```
