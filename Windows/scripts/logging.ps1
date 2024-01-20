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



Write-Host "INSTALLING SYSMON"
$tempDownloadPath = [System.IO.Path]::GetTempFileName()
$downloadPath = $tempDownloadPath -replace '\.tmp$', ''
$programFilesPath = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::ProgramFiles)  # Get around sneaky misconfigurations
$installDirPath = Join-Path $programFilesPath "Sysmon"
New-Item -ItemType Directory -Path $installDirPath -Force
$executableDirectory = Join-Path $programFilesPath "Sysmon"

Write-Host "Downloading Sysmon.zip to '$tempDownloadPath'"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri "https://download.sysinternals.com/files/Sysmon.zip" -OutFile $tempDownloadPath
$newDownloadPath = [System.IO.Path]::ChangeExtension($tempDownloadPath, "zip")
Rename-Item -Path $tempDownloadPath -NewName $newDownloadPath
Expand-Archive -Path $newDownloadPath -DestinationPath $executableDirectory -Force

$executablePath = Join-Path $executableDirectory "Sysmon.exe"
Write-Host "Executing '$executablePath'"
$args = "-accepteula -i"
Start-Process -FilePath $executablePath -ArgumentList $args

$tmp = $tempDownloadPath -replace '\.tmp$', '.zip'
Write-Host "Deleting '$tmp'"
Remove-Item -Path $tmp -Recurse -Force
