$file = "users.txt"
$domain = "DC=teamone,DC=local"
$ouName = ""

Import-Module ActiveDirectory

# FILE FORMAT
# *OU_NAME_1
# USER
# ...
# *OU_NAME_2
# USER

Get-Content $file | ForEach-Object {
    $line = $_.Trim()

    if ($line -match '^\*') {
        $ouName = $line -replace "*",""

        # Create the OU if it doesn't exist
        $ouPath = "OU=$ouName,$domain"
        if (-not (Get-ADOrganizationalUnit -Filter {Name -eq $ouName})) {
            New-ADOrganizationalUnit -Name $ouName -Path "$domain"
            Write-Host "OU '$ouName' created."
        } else {
            Write-Host "OU '$ouName' already exists."
        }
    }
    elseif (-not [string]::IsNullOrWhiteSpace($line)) {
        $user = $line.Trim()
        $userOUPath = "OU=$ouName,$domain"
        
        if (-not (Get-ADUser -Filter {SamAccountName -eq $user})) {
            $securePassword = ConvertTo-SecureString -String "P@ssw0rd" -AsPlainText -Force
            New-ADUser -SamAccountName $user -UserPrincipalName "$user@teamone.local" -Name $user -GivenName $user -Surname "User" -Enabled $true -Path "OU=$ouName,$domain" -AccountPassword $securePassword -PassThru
            Write-Host "User '$user' added to OU '$ouName'."
        } else {
            Write-Host "User '$user' already exists in the domain."
        }
    }
}

