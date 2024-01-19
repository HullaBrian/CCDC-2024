# Check if WinDbg is installed
if (-not (Get-WindowsFeature -Name "WinDbg")) {

    # Install WinDbg
    Write-Host "Installing WinDbg..."
    Install-WindowsFeature -Name "WinDbg" -IncludeAllSubFeature
}

# Get the list of running processes
$processes = Get-Process

# Loop through each process and check if it has been hollowed
foreach ($process in $processes) {

    # Get the process image file path
    try {
        $path = (Get-WmiObject -Class Win32_Process -Filter "ProcessId = $($process.Id)" | Select-Object -ExpandProperty ExecutablePath) -replace '"'
    } catch {
        Write-Host "Error: Could not get path of process with PID $($process.Id)"
        continue
    }

    # Get the hash of the process image file
    try {
        $hash = (Get-FileHash $path -Algorithm SHA256).Hash
    } catch {
        Write-Host "Error: Could not get hash of $path"
        continue
    }

    # Create a minidump of the process
    $dumpPath = "C:\Temp\$($process.Id).dmp"
    try {
        & "C:\Program Files (x86)\Windows Kits\10\Debuggers\x64\windbg.exe" -c ".dump /ma $dumpPath" -z "$path" -y srv*
    } catch {
        Write-Host "Error: Could not create minidump of $($process.Name) with PID $($process.Id)"
        continue
    }

    # Check if the process has been hollowed
    $hollowed = $false
    try {
        $dump = (Get-Content $dumpPath -Encoding Byte)
        for ($i = 0; $i -lt $dump.Length - 8; $i++) {
            if ($dump[$i] -eq 0x4D -and $dump[$i + 1] -eq 0x5A -and $dump[$i + 2] -eq 0x90 -and $dump[$i + 3] -eq 0x00) {
                $peOffset = [BitConverter]::ToInt32($dump, $i + 0x3C)
                $peHeader = $i + $peOffset
                $magic = [BitConverter]::ToInt16($dump, $peHeader)
                if ($magic -ne 0x5A4D) {
                    continue
                }
                $sectionsOffset = $peHeader + 0x14 + [BitConverter]::ToInt16($dump, $peHeader + 0x10)
                $numSections = [BitConverter]::ToInt16($dump, $peHeader + 0x6)
                $optionalHeaderSize = [BitConverter]::ToInt16($dump, $peHeader + 0x14)
                $imageBase = [BitConverter]::ToUInt64($dump, $peHeader + 0x18)
                $sectionHeadersSize = $numSections * 0x28
                for ($j = 0; $j -lt $numSections; $j++) {
                    $sectionHeaderOffset = $sectionsOffset + ($j * 0x28)
                    $sectionName = [System.Text.Encoding]::ASCII.GetString($dump, $sectionHeaderOffset, 0x8)
                $sectionVirtualSize = [BitConverter]::ToUInt32($dump, $sectionHeaderOffset + 0x8)
                $sectionVirtualAddress = [BitConverter]::ToUInt32($dump, $sectionHeaderOffset + 0xC)
                $sectionSize = [BitConverter]::ToUInt32($dump, $sectionHeaderOffset + 0x10)
                $sectionPointerToRawData = [BitConverter]::ToUInt32($dump, $sectionHeaderOffset + 0x14)
                $sectionCharacteristics = [BitConverter]::ToUInt32($dump, $sectionHeaderOffset + 0x24)
                if ($sectionVirtualSize -ne $sectionSize -and ($sectionCharacteristics -band 0x20000000)) {
                    $sectionVirtualEndAddress = $sectionVirtualAddress + $sectionVirtualSize
                    $sectionOffset = $sectionVirtualAddress - $imageBase + $sectionPointerToRawData
                    $sectionDump = $dump[$sectionOffset..($sectionOffset + $sectionVirtualSize - 1)]
                    if ([System.Text.Encoding]::ASCII.GetString($sectionDump, 0, 4) -eq "MZ\x90\x00") {
                        $hollowed = $true
                        break
                    }
                }
            }
        }
    }
} catch {
    Write-Host "Error: Could not check if $($process.Name) with PID $($process.Id) has been hollowed"
    continue
}

# Remove the minidump file
try {
    Remove-Item $dumpPath -Force
} catch {
    Write-Host "Warning: Could not remove minidump file $dumpPath"
}

# Output the results
if ($hollowed) {
    Write-Host "$($process.Name) with PID $($process.Id) has been hollowed"
} else {
    Write-Host "$($process.Name) with PID $($process.Id) has not been hollowed"
}

