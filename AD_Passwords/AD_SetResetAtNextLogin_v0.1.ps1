<#
By Martin Carroll
Version 0.1 - tested and working.
#>

# Load the Active Directory module
Import-Module ActiveDirectory

Write-Host "This will take a list of users and import them, then set their 'PasswordNeverExpires' to FALSE, and 'ChangePasswordAtLogin' to TRUE"
# Path to the text file with usernames
$usernamesFile = Read-Host = "Please enter the path of the usernames to change their flags: "

# Read the usernames from the file
$usernames = Get-Content -Path $usernamesFile

# Loop through each username
foreach ($username in $usernames) {
    # Trim any whitespace from the username
    $username = $username.Trim()
    
    # Check if the user exists in AD
    $user = Get-ADUser -Identity $username -ErrorAction SilentlyContinue
    if ($user -ne $null) {
        # Set the user to require a password change at next login
        Set-ADUser -Identity $username -PasswordNeverExpires $false -ChangePasswordAtLogon $true
        Write-Host "Password reset required for user: $username"
        }
    else {
        Write-Host "User $username not found in Active Directory."
    }
}

Write-Host "All users in the list have been processed."
