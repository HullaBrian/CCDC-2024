# Gather info
$hostinfo = Get-ComputerInfo
$netinfo = Get-NetIPConfiguration -Detailed
$domain = (Get-WmiObject Win32_ComputerSystem).Domain
# Get Enabled Windows Features
if ( $hostinfo.WindowsProductName.Contains("Server")){
    # Machine is running Windows Server
    $featurelist = Get-WindowsFeature | Where-Object {$_.Installed -eq "Installed"} 
} else {
    # Machine is running Windows 10
    $featurelist = Get-WindowsCapability -Online | Where-Object {$_.State -eq "Enabled"} | Select-Object FeatureName
}
                                             
Write-output "================"
Write-output "██████████  ██████      ████    ██      ██  " 
Write-output "   ██      ██   ███   ██   ██  ████    ██   " 
Write-output "  ██      ██████     ██   ██  ██  ██  ██    " 
Write-output " ██      ██    ██   ██   ██  ██    ████     " 
Write-output "██      ██    ██    █████   ██      ██      "
Write-output "Target Recognition Operator Notification (TRON) system"

# Hostname
Write-output "================"
Write-output "HOSTNAME: $($hostinfo.CsDomain)\$($hostinfo.CsName)"


# Operating System
Write-output "================"
Write-output "OS: $($hostinfo.WindowsProductName) - $($hostinfo.OSVersion) - $($hostinfo.OsBuildNumber)"
foreach( $hotfix in $hostinfo.OsHotFixes){
   Write-Output "$($hotfix.HotFixID) - $($hotfix.Description) - $($hotfix.InstalledOn)"
}


# Network Interfaces
Write-output "================"
Write-output "Network Interfaces:"
foreach( $interface in $netinfo ) {
    Write-Output "- $($interface.InterfaceAlias)"
    Write-Output "    - MAC: $($interface.NetAdapter.LinkLayerAddress)"
    Write-Output "    - IPv4: $($interface.IPv4Address.Ipv4Address)"
    Write-Output "    - IPv6: $($interface.IPv6Address.IPv6Address)"
    Write-Output "    - Default gateway: $($interface.IPv4DefaultGateway.NextHop)"
    Write-Output "    - DNS: $($interface.DNSServer.ServerAddresses)"
}


# Purpose
Write-output "================"
Write-output "Purpose:"
Write-output "Assess what this system's purpose is with context to business operations."
Write-output "Is it a web server? What context does it host? Who would access it (public or intranet)?"
Write-output "Part of domain? $($hostinfo.CsPartOfDomain) - $($hostinfo.CsDomainRole)"
$isDomainJoined = $domain -ne $null -and $domain -ne ""
Write-Output "Domain joined? - $($isDomainJoined)"

# Pause space
# Write-output "================"
# Write-output "Press enter to continue"
# read-host

# Active Services
Write-output "================"
Write-output "Installed Features:"
Write-output "~~~~~~~~~~~~~~~~~~~"
foreach( $feature in $featurelist){
   Write-Output $feature.DisplayName
}

Write-output "----------------"

# Installed Applications:
Write-output "Installed Applications:"
Write-output "~~~~~~~~~~~~~~~~~~~~~~~"
$applist = Get-WmiObject -Class Win32_Product | select Name,Vendor,Version
foreach( $app in $applist){
   Write-Output "$($app.Name) | ($($app.Vendor))"
   Write-Output "- $($app.Version)"
}

# Pause space
# Write-output "================"
# Write-output "Press enter to continue"
# read-host


# Ports
Write-output "================"
Write-output "Processes:"
$processList = Get-CimInstance Win32_Process
foreach ($process in $processList) {
    $portList = Get-NetTCPConnection -OwningProcess $process.ProcessId -ErrorAction SilentlyContinue |
        Select-Object LocalAddress,LocalPort,RemoteAddress,RemotePort
    if ($portList) {
        if ($process.ProcessName -eq 'svchost.exe') {
            $service = Get-WmiObject -Class Win32_Service -Filter "ProcessID=$($process.ProcessId)" | Select-Object -Property Name 
            Write-Output "$($process.ProcessName) ($($process.ProcessId)) - $($service.Name)"
            Write-Output "- $($process.CommandLine)"
            foreach( $port in $portList){
                if($port.LocalAddress -ne "::1" -and $port.LocalAddress -ne "127.0.0.1"){ 
                    Write-Output "  - $($port.LocalAddress):$($port.LocalPort) - $($port.RemoteAddress):$($port.RemotePort)"
                }
            }
        }
        else {
            $service = Get-WmiObject -Class Win32_Service -Filter "ProcessID=$($process.ProcessId)" 
            Write-Output "$($process.ProcessName) ($($process.ProcessId))"
            Write-Output "- $($process.CommandLine)"
            foreach( $port in $portList){
                if($port.LocalAddress -ne "::1" -and $port.LocalAddress -ne "127.0.0.1"){ 
                    Write-Output "  - $($port.LocalAddress):$($port.LocalPort) - $($port.RemoteAddress):$($port.RemotePort)"
                }
            }
        }
        write-output ""
    }
}

# Pause space
# Write-output "================"
# Write-output "Press enter to continue"
# read-host


#Users
Write-output "================"
Write-output "Local Users:"
Get-LocalUser | Select-Object Name, PrincipalSource

$privgroups = (Get-ACL "AD:\$($(get-addomain).DistinguishedName)").Access | where-object {($_.ActiveDirectoryRights -ne "ReadProperty") -and ($_.ActiveDirectoryRights -ne "ListChildren") -and ($_.ActiveDirectoryRights -ne "DeleteChild") -and ($_.ActiveDirectoryRights -ne "GenericRead") -and ($_.ActiveDirectoryRights -ne "readProperty, ReadControl")} | Select-Object -Property IdentityReference -Unique 
foreach( $group in $privgroups){
    $t2 = $group.IdentityReference.ToString().split("\")
    try{
        Get-ADGroupMember -Identity $t2[1] -Recursive  | Format-Table name,distinguishedName,objectClass
    }
    catch{}
}

if ($isDomainJoined) {
    Write-output "================"
    Write-output "`nDomain Users`n-----------------"
    $users = Get-ADUser -Filter *
    $userInfoArray = @()

    foreach ($user in $users) {
        $userDN = $user.DistinguishedName
        $ou = $userDN -replace '^CN=[^,]+,'
        $groups = Get-ADUser $user | Get-ADPrincipalGroupMembership | Select-Object -ExpandProperty Name

        $userInfo = [PSCustomObject]@{
            'Username' = $user.SamAccountName
            'OU' = $ou
            'Groups' = $groups -join ', '
        }
        $userInfoArray += $userInfo
    }

    $userInfoArray | Format-Table -AutoSize
}


# Startup Tasks
Write-Output "=================="
Write-Output "Startup Tasks:"
Get-CimInstance Win32_StartupCommand | Select-Object Name, Command, Location, User | Format-Table -AutoSize
Write-Output "=================="


# Shares
Write-Output "SMB Shares:"
Get-SmbShare | Format-Table -Property Name, Path, Description, FullAccess, ReadAccess -AutoSize
Write-Output "==================="