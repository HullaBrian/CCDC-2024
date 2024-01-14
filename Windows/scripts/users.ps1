function Generate-RandomPassword {
    $passwordLength = 12
    $chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*()'
    $randomPassword = -join (0..($passwordLength-1) | ForEach-Object { $chars[(Get-Random -Maximum $chars.Length)] })
    return $randomPassword
}


# Get all local users
$localUsers = Get-WmiObject Win32_UserAccount | Where-Object { $_.LocalAccount -eq $true }
$userPasswords = @()

# Loop through each local user
foreach ($user in $localUsers) {
    # Generate a random password
    $randomPassword = Generate-RandomPassword

    # Print the random password
    # Write-Host "Username: $($user.Name), Password: $randomPassword"
    $userPasswords += [PSCustomObject]@{
        'Username' = $user.Name
        'Password' = $randomPassword
    }

    # CHANGE ALL USER PASSWORDS
    # Set-LocalUser -Name $user.Name -Password (ConvertTo-SecureString -AsPlainText $randomPassword -Force)
}

$userPasswords | Format-Table -AutoSize
