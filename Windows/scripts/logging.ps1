# Enable PowerShell Script Block Logging
$scriptBlockLoggingKeyPath = "HKLM:\SOFTWARE\Wow6432Node\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging"
New-Item -Path $scriptBlockLoggingKeyPath -Force | Out-Null
New-ItemProperty -Path $scriptBlockLoggingKeyPath -Name "EnableScriptBlockLogging" -Value 1 -PropertyType DWORD -Force | Out-Null

# Enable PowerShell Module Logging
$moduleLoggingKeyPath = "HKLM:\SOFTWARE\Wow6432Node\Policies\Microsoft\Windows\PowerShell\ModuleLogging"
New-Item -Path $moduleLoggingKeyPath -Force | Out-Null
New-ItemProperty -Path $moduleLoggingKeyPath -Name "EnableModuleLogging" -Value 1 -PropertyType DWORD -Force | Out-Null

# Enable PowerShell Transcription
$transcriptionKeyPath = "HKLM:\SOFTWARE\Wow6432Node\Policies\Microsoft\Windows\PowerShell\Transcription"
New-Item -Path $transcriptionKeyPath -Force | Out-Null
New-ItemProperty -Path $transcriptionKeyPath -Name "EnableTranscripting" -Value 1 -PropertyType DWORD -Force | Out-Null

# Set Execution Policy to RemoteSigned (or any other suitable policy)
Set-ExecutionPolicy RemoteSigned -Scope LocalMachine -Force

Write-Host "Enabled powershell logging"