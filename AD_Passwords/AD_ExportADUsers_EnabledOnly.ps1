# Import the Active Directory module
Import-Module ActiveDirectory

$path = ($pwd).path
# Define the output file path
$outputFile = "$path/AD_ExportADUser_Enabled.csv"

# Define the distinguished name for the Users OU (update as necessary)

# Get all user accounts from Active Directory
$allUsers = Get-ADUser -Filter * -Properties SamAccountName, DistinguishedName, Enabled

# Filter out users that are in the specified OU
$users = $allUsers | Where-Object { $_.Enabled -eq $true }

# Extract just the usernames and export to a text file
$users | Select-Object -ExpandProperty SamAccountName | Set-Content -Path $outputFile -Encoding UTF8

Write-Host "Usernames have been exported to $outputFile "
