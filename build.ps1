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
    # Path to OpenSSL local installer. If exists, online downloading will be 
    # skipped.
    [string] $OpenSSL,
    [string[]] $BuildType = ('whl', 'exe', 'msi'),
    [switch] $BuildOnly,
    # Skip to show warning messages.
    [switch] $NoWarnings,
    # Alias to Get-Help.
    [switch] $Help
)

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

    Write-Host $Message -ForegroundColor Red
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

    Write-Output 'Installing OpenSSL...'
    Start-Process msiexec.exe -Wait -ArgumentList (
        '/package {0}' -f $(Convert-Path $Path), '/passive', '/le err.log')
    
    try {
        [string] $log = Get-Content .\err.log -ErrorAction Stop
    }
    catch [System.Management.Automation.ItemNotFoundException] {
        Write-Error 'Failed to install OpenSSL, script terminated.'
    }
    if (!$log -or $log -like '*Error*') {
        Write-Error 'Failed to install OpenSSL, script terminated.'
    }
}

# Output help message
if ($Help) {
    Get-Help .\build.ps1
    exit
}

# Warning message, use '-NoWarnings' to skip.
if (!${NoWarnings}) {
    $warn_msg = @"
`nThis script will download or install programmes or files to your device. After
processing, you will be prompted to clean up the unnecessary files or reserve 
them.
This script cannot grantee that will not destroy your device, so DO NOT RUN this
script unless you completely understand what the intention of this script is.
You can now press Ctrl+C to stop the process if you cannot trust this script or 
have no idea on how to handle the possible problems.
"@
    Write-Warning $warn_msg
    Read-Host -Prompt 'Press Enter to continue, or Ctrl+C to stop'
}

Clear-Host

# Step 1: Install OpenSSL.
if ($OpenSSL) {
    if ($OpenSSL -ne 'skip') {
        # Install OpenSSL from the indicated path.
        Install-OpenSSL -Path $OpenSSL
    }
}
else {
    # Download and install OpenSSL v1.1.1k for the current system architecture.
    $is_x64 = [System.Environment]::Is64BitOperatingSystem
    $arch = if ($is_x64) { '64' } else { '32' }
    $url = 'https://slproweb.com/download/Win{0}OpenSSL-1_1_1k.msi' -f $arch

    Write-Output 'Downloading OpenSSL...'
    try {
        $wc = New-Object System.Net.WebClient
        $wc.DownloadFile($url, 'OpenSSL.msi')
    }
    catch [System.Net.WebException], [System.IO.IOException] {
        $err_msg = 'Unable to download OpenSSL.msi file, script terminated.'
        Write-Error $err_msg
        exit 1
    }
    # Install downloaded OpenSSL.
    Install-OpenSSL -Path .\OpenSSL.msi
}

# Step 2: Get swig via Chocolatey.
Write-Output "`nInstalling Chocolatey..."
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = (
    [System.Net.ServicePointManager]::SecurityProtocol -bor 3072)
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString(
        'https://chocolatey.org/install.ps1'))

Write-Output 'Installing swig via Chocolatey...'
choco install -r -y swig

# Step 3: Install Python dependencies.
Write-Output "`nInstalling Python dependencies..."
if ($PythonEnv) {
    Invoke-Expression ('{0}Scripts\Activate.ps1' -f $(Convert-Path $PythonEnv))
    Write-Output 'Python virtual environment has been activated.'
}

pip install pywin32 wheel
if ( -not $?) {
    Write-Error 'Error occurred while installing dependencies from pip.'
}
