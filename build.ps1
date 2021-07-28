#Requires -RunAsAdministrator

# Manual build and install M2Crypto on Windows.
# Please read the README.md before running this script.
#
# Author: Satoshi Jek <jks15satoshi@gmail.com>
# License: MIT License, see LICENSE for details.

# Definitions for parameters
param (
    # Path to the Python virtual environment.
    [string] $PythonEnv,
    # Specified version of M2Crypto.
    [string] $ModuleVersion,
    # Path to OpenSSL local installer. If exists, online downloading will be skipped.
    [string] $OpenSSL,
    # Build and generate M2Crypto installable files only.
    [switch] $BuildOnly,
    # Skip to show warning messages.
    [switch] $NoWarnings,
    # Alias to Get-Help.
    [switch] $Help
)

Import-Module BitsTransfer

Clear-Host

function Write-Info {
    <#
    .SYNOPSIS
        Output message with the foreground color as cyan.
    
    .PARAMETER Message
        The output message.
    #>
    param (
        [string] $Message
    )

    Write-Host ("`n>>> " + $Message) -ForegroundColor Cyan
}

function Write-Error {
    <#
    .SYNOPSIS
        Output message with the foreground color as red and exit script.
    
    .PARAMETER Message
        The output message.
    #>
    param (
        [string] $Message
    )

    Write-Host ("ERROR: " + $Message) -ForegroundColor Red -BackgroundColor Black
    exit 1
}

function Install-OpenSSL {
    <#
    .SYNOPSIS
        Install OpenSSL from the specified path.

    .PARAMETER Path
        The path to indicate where to install.
    #>
    param (
        [string] $Path
    )

    Write-Info "Installing OpenSSL..."
    Start-Process msiexec.exe -Wait -ArgumentList (
        "/package " + $(Convert-Path $Path), "/passive", "/le err.log")
    
    try {
        [string] $log = Get-Content .\err.log -ErrorAction Stop
    }
    catch [System.Management.Automation.ItemNotFoundException] {
        Write-Error "Failed to install OpenSSL, script terminated."
    }
    if (!$log -or $log -like "*Error*") {
        Write-Error "Failed to install OpenSSL, script terminated."
    }
}

# Output help message
if ($Help) {
    Get-Help .\build.ps1
    exit
}

# Warning message, use "-NoWarnings" to skip.
if (!${NoWarnings}) {
    $warn_msg = @"
`nThis script will download or install programmes or files to your device. After processing, you will be prompted to clean up the unnecessary files or reserve them.
This script cannot grantee that will not destroy your device, so DO NOT RUN this script unless you completely understand what the intention of this script is.
You can now press Ctrl+C to stop the process if you cannot trust this script or have no idea on how to handle the possible problems.
"@
    Write-Warning $warn_msg
    Read-Host -Prompt "Press Enter to continue, or Ctrl+C to stop"
}

# Step 1: Install OpenSSL.
if ($OpenSSL) {
    if ($OpenSSL -ne "skip") {
        # Install OpenSSL from the indicated path.
        Install-OpenSSL -Path $OpenSSL
    }
}
else {
    # Download and install OpenSSL v1.1.1k for the current system architecture.
    $is_x64 = [System.Environment]::Is64BitOperatingSystem
    $arch = if ($is_x64) { "64" } else { "32" }
    $url = "https://slproweb.com/download/Win" + $arch + "OpenSSL-1_1_1k.msi"

    Write-Info "Downloading OpenSSL..."
    try {
        Start-BitsTransfer $url "OpenSSL.msi" -Description "Downloading OpenSSL.msi." -ErrorAction Stop
    }
    catch {
        Write-Error "Unable to download OpenSSL.msi file, script terminated."
    }

    Install-OpenSSL OpenSSL.msi
}

# Step 2: Get swig via Chocolatey.
Write-Info "Installing Chocolatey..."
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString("https://chocolatey.org/install.ps1"))

Write-Info "Installing swig via Chocolatey..."
choco install -r -y swig

# Step 3: Install Python dependencies.
Write-Info "Installing Python dependencies..."
if ($PythonEnv) {
    try {
        Invoke-Expression ($(Convert-Path $PythonEnv) + "Scripts\Activate.ps1")
    }
    catch {
        Write-Error "The indicated path is not a valid Python virtual environment."
    }
    
    Write-Info "Python virtual environment has been activated."
}

pip install pywin32 wheel
if ( -not $?) {
    Write-Error "Error occurred while installing dependencies from pip."
}

# Step 4: Clone M2Crypto from GitLab
Write-Info "Cloning M2Crypto to local..."

if (!(Test-Path '.\m2crypto')) {
    [void](New-Item -Path . -Name "m2crypto" -ItemType "directory")
}
Set-Location .\m2crypto
git clone "https://gitlab.com/m2crypto/m2crypto" .

# Step 5: Build and generate M2Crypto installable files.
python setup.py build --openssl="C:\Program Files\OpenSSL-Win64" --bundledlls
python setup.py bdist_wheel bdist_wininst bdist_msi

# Step 6: Install M2Crypto to the currently activated Python virtual environment.
if (!$BuildOnly) {
    Set-Location .\dist
    pip install ([string](Get-ChildItem . "*.whl" -Name))
}
