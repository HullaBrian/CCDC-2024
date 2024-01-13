# HOSTNAME
    # cmd: hostname
    # powershell command: [System.Net.Dns]::GetHostName()
    # environment variables: $env:COMPUTERNAME
$name = hostname
Write-Host "Workstation / VM Identification: '$name'"


# OS version
$os_version = (Get-WmiObject -class Win32_OperatingSystem).Caption
Write-Host "OS Version: '$os_version'"

# Services
#$services = Get-Process | Where-Object { $_.Company -notlike 'Microsoft*' }
#$services | Select-Object Id, ProcessName, Company
Write-Host ""
Write-Host "Services:"
Write-Host "---------"
$services = Get-Process | Where-Object {
    $_.Company -notlike 'Microsoft*' -and
    $_.ProcessName -ne 'svchost' -and
    $_.ProcessName -ne 'conhost' -and
    $_.ProcessName -ne 'csrss' -and
    $_.ProcessName -ne 'Registry'
}
$tmp = $services | Select-Object Id, ProcessName | Out-String
Write-Host $tmp

# Open Ports
Write-Host ""
Write-Host "Open ports:"
Write-Host "-----------"
# Get all open TCP and UDP connections
$openTcpPorts = Get-NetTCPConnection -State Listen
$openUdpPorts = Get-NetUDPEndpoint
$output = @()

# Display open TCP ports with corresponding applications
foreach ($tcpPort in $openTcpPorts) {
    $processId = $tcpPort.OwningProcess
    $process = Get-Process -Id $processId -ErrorAction SilentlyContinue

    $output += [PSCustomObject]@{
        'Protocol'     = 'TCP'
        'LocalAddress' = $tcpPort.LocalAddress
        'LocalPort'    = $tcpPort.LocalPort
        'Application'  = if ($process) { $process.ProcessName } else { 'N/A' }
    }
}

# Display open UDP ports with corresponding applications
foreach ($udpPort in $openUdpPorts) {
    $processId = $udpPort.OwningProcess
    $process = Get-Process -Id $processId -ErrorAction SilentlyContinue

    $output += [PSCustomObject]@{
        'Protocol'     = 'UDP'
        'LocalAddress' = $udpPort.LocalAddress
        'LocalPort'    = $udpPort.LocalPort
        'Application'  = if ($process) { $process.ProcessName } else { 'N/A' }
    }
}
Write-Host ($output | Format-Table -AutoSize | Out-String)


# IP Addresses
Write-Host "Network Configuration:"
Write-Host "----------------------`n"
# Get network interfaces
$networkInterfaces = Get-NetIPConfiguration

# Display information in a table
foreach ($interface in $networkInterfaces) {
    Write-Host "Network Interface: $($interface.InterfaceAlias)"
    
    $ipv4Info = $interface | Select-Object InterfaceIndex, InterfaceAlias, 
                @{Name='IPv4Address'; Expression={$_.IPv4Address.IPAddress}},
                @{Name='SubnetMask'; Expression={
                    if ($_.IPv4SubnetMask) {
                        ($_.IPv4SubnetMask.IPAddress -as [IPAddress]).IPAddressToString
                    } else {
                        'N/A'
                    }
                }},
                @{Name='DefaultGateway'; Expression={$_.IPv4DefaultGateway.NextHop}},
                @{Name='DNSServers'; Expression={$_.DNSServer.ServerAddresses -join ', '}}

    $ipv4Info | Format-Table -AutoSize
    Write-Host "`n"  # Add a newline for separation
}

