<#
By Martin Carroll
Version 0.1- Tested, working on lab.
#>

Write-Host "------------------------------------------------------------"
Write-Host "Please read the Powershell Script comments before you use this script"
Write-Host "Pay close attention to the 'UPN' comment, as this must be unique in a forst, and may need to be edited for a child/new domain"
Write-Host "This script exports all ADUsers and some of their properties to a suitable CSV. It creates multiple csvs with different purposes" 
Write-Host "You can add additional properties to extract if required, as per Get-ADUser cmdlet - but may not work with custom attributes"
Write-Host "'Path' (used for import) is not created automatically - the script will attempt to make this using the DistinguishedName and regex"
Write-Host "It'll attempt to make it in the format of: OU=Users,DN=domain,DN=local"
Write-Host "------------------------------------------------------------"

Read-Host "Press Enter to continue..."
<#
Customise this script as required as per the options available in the Get-ADUser cmdlet.

NOTE that the UPN is unique within a FOREST, and the SamAccountName is unique within a DOMAIN. 
That means that you can use the same SamAccountName/Name etc, but you CAN'T set the UserPrincipalName as something else within the domain.
For example, if you have a domain.local domain, and a gb.domain.local child domain. If you're exporting from domain.local and importing into gb.domain.local, you'll need to change the UPN to have the @gb.domain.local UPN ending, as it wouldn't be unique in the forest.
The Name, SAM, and everything else can be a duplicate.

Important:
- Ensure files are UTF8 for multi-language characters. (Export-CSV -Path x -Encoding UTF8)
- You won't be able to import values which aren't found in the Add-ADUser cmdlet, as far as I am aware. This needs to be tested at some point for unique/custom attributes, but there is likely a better way to do this.
#>

#Variables
$script_path = ($pwd).path

# Get all users data
$allusers = Get-ADUser -Filter * -Properties *

# Export all users to a csv (all data)
$allusers | Export-Csv -Path "$script_path\4-AD_ExportADUsers_all_ADUsers_all_Data.csv" -Encoding UTF8

#Select only enabled users.
$enabledUsers = $allusers | Where-Object { $_.Enabled -eq $true}

# Export enabled users to a csv (all data)
$enabledUsers | Export-Csv -Path "$script_path\3-AD_ExportADUsers_Enabled_all_Data.csv" -Encoding UTF8

# Import FilteredUsers to a CSV variable, copy the DN value into a Path column, 
# then change the Path values into suitable path values ready for the Add-ADUser cmdlet arguements.

$filteredUsers_csv = Import-Csv -Path "$script_path\3-AD_ExportADUsers_Enabled_all_Data.csv" | Select-Object *,"Path"


# Iterate through the csv and match the value in the Path column to the Regex Pattern. If it matches, replace the 
# value of Path with the new value, which is stored in $matches[0] (this seems wrong, need to test).

# Iterate through the csv and set the Path value to the DistinguishedName value.
$filteredUsers_csv | ForEach-Object {
    $_.Path = $_.DistinguishedName
}

# Iterate through the csv and match the value in the Path column to the Regex Pattern.
foreach ($entry in $filteredUsers_csv) {
    Write-Host "Before: $($entry.Path)"
    $entry.Path = $entry.Path -replace '^.*?OU=', 'OU='
    Write-Host "After: $($entry.Path)"
}

#Output all data, but with the path variable added.
$filteredUsers_csv | Export-Csv -Path "$script_path\2-AD_ExportADUsers_Enabled_for_Import_allData.csv" -Encoding UTF8

#Filter users based on importable objects.
$filteredUsers_csv_small = $filteredUsers_csv | Select-Object -Property AccountExpirationDate, AccountDelegated, Country, Description, DisplayName, EmailAddress, EmployeeID, GivenName, Initials, Name, Path, SamAccountName, ScriptPath, Surname, UserPrincipalName
$filteredUsers_csv_small | Export-Csv -Path "$script_path\1-AD_ExportADUsers_Enabled_for_Import_filteredData.csv" -Encoding UTF8

Write-Host "Output files to $script_path."
Write-Host "Completed."

Read-Host "Press Enter to continue"