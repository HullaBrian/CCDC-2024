# Set the console font to Consolas (replace with your desired TrueType font)
$fontName = "Consolas"
$regPath = "HKCU:\Console"
$regName = "FaceName"

# Check if the registry path exists, create it if not
if (-not (Test-Path $regPath)) {
    New-Item -Path $regPath -Force
}

# Set the FaceName registry value to the desired font name
Set-ItemProperty -Path $regPath -Name $regName -Value $fontName

# Notify the user to restart the console for changes to take effect
Write-Host "Console font set to $fontName. Restart the console for changes to take effect."


# Set the keyboard layout to standard United States English (US)
$layoutId = 0x0409  # 0x0409 corresponds to the English (United States) layout

# Set the registry key for the keyboard layout
Set-ItemProperty -Path 'HKCU:\Keyboard Layout\Preload' -Name 1 -Value $layoutId

# Notify the user to log out and log back in for changes to take effect
Write-Host "Keyboard layout set to standard United States English. Please log out and log back in for changes to take effect."
