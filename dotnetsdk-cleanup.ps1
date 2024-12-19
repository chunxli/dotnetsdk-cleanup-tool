# Define the versions to keep
$versionsToKeep = "8.0.404"

# Get the download links for the .NET SDK Download Page: https://dotnet.microsoft.com/en-us/download/dotnet/8.0
$sdk64Link = "https://download.visualstudio.microsoft.com/download/pr/ba3a1364-27d8-472e-a33b-5ce0937728aa/6f9495e5a587406c85af6f93b1c89295/dotnet-sdk-8.0.404-win-x64.exe"
$sdk32Link = "https://download.visualstudio.microsoft.com/download/pr/acd3875c-e28a-46a1-85fd-e99948175d90/a98148f58ddb7cc1d31305e1e5244518/dotnet-sdk-8.0.404-win-x86.exe"

# Get the link from https://github.com/dotnet/cli-lab/releases
$uninstallToolLink = "https://github.com/dotnet/cli-lab/releases/download/1.7.550802/dotnet-core-uninstall-1.7.550802.msi"

# Print Current Location
Write-Output "Current Location: "
Write-Output (Get-Location).Path

# Get the path to the .NET Core Uninstall Tool
$toolPath = (Get-Command dotnet-core-uninstall.exe -ErrorAction SilentlyContinue).Source

# Install the .NET Core Uninstall Tool if it is not installed
if (-not $toolPath) {
    Write-Output "dotnet-core-uninstall.exe is not installed on $env:COMPUTERNAME"
    Write-Output "Downloading the .NET Core Uninstall Tool from $uninstallToolLink ..."
    Invoke-WebRequest -Uri $uninstallToolLink -OutFile dotnet-core-uninstall.msi -UseBasicParsing
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
$sdkList = dotnet --list-sdks
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
        Start-Process -FilePath .\dotnet-sdk-win-x64.exe -ArgumentList "/quiet /norestart" -Wait
		Write-Output "Completed the installation of the .NET SDK"
    }
    else {
        Write-Output "This is a 32-bit operating system."
		Write-Output "Downloading the .NET SDK from $sdk32Link"
        Invoke-WebRequest -Uri $sdk32Link -OutFile dotnet-sdk-win-x86.exe -UseBasicParsing
		Write-Output "Installing the .NET SDK"
        Start-Process -FilePath .\dotnet-sdk-win-x86.exe -ArgumentList "/quiet /norestart" -Wait
		Write-Output "Completed the installation of the .NET SDK"
    }
}

# List the installed .NET SDKs after installation
Write-Output "Listing the installed .NET SDKs after installation:"
dotnet --list-sdks

# Uninstall old .NET SDKs
Write-Output "Uninstalling old .NET SDKs ..."
& $toolPath remove --all-but $versionsToKeep --sdk --yes --force
& $toolPath remove --all-but $versionsToKeep --runtime --yes --force
& $toolPath remove --all-but $versionsToKeep --aspnet-runtime --yes --force
& $toolPath remove --all-but $versionsToKeep --hosting-bundle --yes --force

# List the installed .NET SDKs after uninstallation
Write-Output "Listing the installed .NET SDKs after uninstallation:"
dotnet --list-sdks
