# Untested, please test before use.
$path = ($pwd).path
# Import the Active Directory module
Import-Module ActiveDirectory

# Define the output file path
$outputFile = "$path\AD_ExportADUser_SAM.csv"

# Get all user accounts from Active Directory
$allUsers = Get-ADUser -Filter * -Properties SamAccountName

# Extract just the usernames and export to a text file
$allUsers | Select-Object -ExpandProperty SamAccountName | Set-Content -Path $outputFile -Encoding UTF8

Write-Host "Usernames have been exported to $outputFile"