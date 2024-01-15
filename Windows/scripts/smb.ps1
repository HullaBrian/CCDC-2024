Write-Host "Using every known way to disable SMBv1..."


# Disable SMBv1 on the client and server
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" -Name "SMB1" -Value 0 -Type DWORD
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name "SMB1" -Value 0 -Type DWORD
# Disable SMBv1 on the client alone (for Windows 10)
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "AllowInsecureGuestAuth" -Value 0 -Type DWORD
Write-Host "SMBv1 has been disabled. Restart the system for changes to take effect."


Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol


Write-Host "Done!`nDeleteting default shares..."


# Remove default SMB shares if they exist
if (Get-SmbShare -Name 'ADMIN$' -ErrorAction SilentlyContinue) {
    Remove-SmbShare -Name 'ADMIN$' -Force
}

if (Get-SmbShare -Name 'C$' -ErrorAction SilentlyContinue) {
    Remove-SmbShare -Name 'C$' -Force
}

if (Get-SmbShare -Name 'IPC$' -ErrorAction SilentlyContinue) {
    Remove-SmbShare -Name 'IPC$' -Force
}

# Notify the user that default shares have been removed
Write-Host "Default SMB shares have been removed. Restart the system as soon as possible."

