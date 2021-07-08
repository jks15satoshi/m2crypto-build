# Manual build and install M2Crypto on Windows.
# Please read the README.md before running this script.
#
# Author: Satoshi Jek <jks15satoshi@gmail.com>
# License: MIT License, see LICENSE for details.

# Definitions for formatted outputs
function Format-Error {
    process { Write-Host $_ -ForegroundColor Red }    
}
function Format-Warning {
    process { Write-Host $_ -ForegroundColor Yellow }
}

Clear-Host

# WARNING MESSAGE
$warn_msg = @'
CAUTION:
This script will download or install programmes or files to your device. After processing, you will be prompted to clean up the unnecessary files or reserve them.
This script cannot grantee that will not destroy your device, so DO NOT RUN this script unless you completely understand what the intention of this script is.
You can now press Ctrl+C to stop the process if you cannot trust this script or have no idea on how to handle the possible problems.
'@
Write-Output $warn_msg | Format-Warning
Read-Host -Prompt 'Press Enter to continue, or Ctrl+C to stop'

# Get system architecture information
$arch_version = if ([System.Environment]::Is64BitOperatingSystem) { '64' } else { '32' }

# Download and install OpenSSL v1.1.1k for the current system architecture.
$url = 'https://slproweb.com/download/Win{0}OpenSSL-1_1_1k.mi' -f $arch_version

Write-Output 'Downloading OpenSSL...'
try {
    $wc = New-Object System.Net.WebClient
    $wc.DownloadFile($url, 'OpenSSL.msi')
}
catch [System.Net.WebException], [System.IO.IOException] {
    Write-Output 'Unable to download OpenSSL.msi file, script terminated.' | Format-Error
    exit 1
}

Write-Output 'Installing OpenSSL...'
msiexec.exe / package / quiet .\OpenSSL.msi
# msiexec.exe /uninstall /quiet '.\OpenSSL.msi'
