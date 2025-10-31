# Creates users based on a .csv with 'firstname,lastname,username' as the header.
# Should be ran on a machine with the Active Directory module installed and appropriate permissions.
# Example CSV content:
# firstname,lastname,username
# John,Doe,jdoe
# Jane,Smith,jsmith 

Write-Host "This code has NOT been tested in a live environment. Please review and test before use." -ForegroundColor Yellow
Read-Host "Press Enter to continue..."

# Define the path to the CSV file
$csvPath = Read-Host "Enter the path to the CSV file containing user details"
$domain = Read-Host "Enter the domain for user principal names (e.g., acmecorp)"
$domain_suffix = Read-Host "Enter the domain suffix (e.g., com)"


# Import the CSV file
$users = Import-Csv -Path $csvPath

# Loop through each user and create them in Active Directory
foreach ($user in $users) {
    $firstName = $user.firstname
    $lastName = $user.lastname
    $username = $user.username
    $displayName = "$firstName $lastName"
    $userPrincipalName = "$username@$domain.$domain_suffix"
    $password = ConvertTo-SecureString "P@ssw0rd123" -AsPlainText -Force

    # Create the user
    New-ADUser `
        -Name $displayName `
        -GivenName $firstName `
        -Surname $lastName `
        -SamAccountName $username `
        -UserPrincipalName $userPrincipalName `
        -AccountPassword $password `
        -Enabled $true `
        -Path "OU=Users,DC=$domain,DC=$domain_suffix"
    
    Write-Host "Created user: $displayName"
}