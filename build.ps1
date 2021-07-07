# Manual build and install M2Crypto on Windows.
# Please read the README.md before running this script.
#
# Author: Satoshi Jek <jks15satoshi@gmail.com>
# License: MIT License, see LICENSE for details.

# Definitions for formatted outputs
function ErrorOutput {
    process { Write-Host $_ -ForegroundColor Red }    
}

# Get system architecture information
$arch_version = if ([System.Environment]::Is64BitOperatingSystem) { '64' } else { '32' }

# Download and install OpenSSL v1.1.1k for the current system architecture.
$url = 'https://slproweb.com/download/Win{0}OpenSSL-1_1_1k.mi' -f $arch_version

Write-Output 'Downloading OpenSSL...'
try {
    $wc = New-Object System.Net.WebClient
    $wc.DownloadFile($url, 'OpenSSL.msi')
} catch [System.Net.WebException],[System.IO.IOException] {
    Write-Output 'Unable to download OpenSSL installer, script terminated.' | ErrorOutput
    exit 1
}

Write-Output 'Installing OpenSSL...'
msiexec.exe /package /quiet .\OpenSSL.msi
# msiexec.exe /uninstall /quiet '.\OpenSSL.msi'
