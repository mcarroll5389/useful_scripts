<#
By Martin Carroll
Version 0.1 - UNTESTED
#>

Write-Host "UNTESTED SCRIPT, USE WITH CAUTION"
Write-Host "Please read the powershell script before you use this script"
Write-Host "Pay close attention to the UPN comment, as this must be unique in a forst, and may need to be edited for a child/new domain"
Write-Host "This script exports all ADUsers and some of their properties to suitable CSV. It creates multiple csvs with different purposes" 
Write-Host "You can add additional properties to extract if required, as per Get-ADUser cmdlet - but may not work with custom attributes"
Write-Host "Path (used for import) is not created automatically - the script will attempt to make this using the DistinguishedName and regex"
Write-Host " It'll attempt to make it in the format of: OU=Users,DN=domain,DN=local"

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
$path = ($pwd).path
$pattern = "(?<=OU=)(.*)"

# Get all users data
$allusers = Get-ADUser -Filter * -Properties *

# Export all users to a csv (all data)
$allusers | Export-Csv -Path "$path\AD_ExportADUsers_all_ADUsers_all_Data.csv" -Encoding UTF8

#Select only enabled users.
$enabledUsers = $allusers | Where-Object { $._Enabled -eq $true}

# Export enabled users to a csv (all data)
$enabledUsers | Export-Csv -Path "$path\AD_ExportADUsers_Enabled_all_Data.csv" -Encoding UTF8

# Import FilteredUsers to a CSV variable, copy the DN value into a Path column, 
# then change the Path values into suitable path values ready for the Add-ADUser cmdlet arguements.

$filteredUsers_csv = Import-Csv -Path "$path\AD_ExportADUsers_Enabled_all_Data.csv" | Select-Object *,"Path"

# Iterate through the csv and set the Path value to the DistinguishedName value.
$filteredUsers_csv | ForEach-Object {
    $_.Path = $_.DistinguishedName }


# Iterate through the csv and match the value in the Path column to the Regex Pattern. If it matches, replace the 
# value of Path with the new value, which is stored in $matches[0] (this seems wrong, need to test).
foreach ($entry in $filteredUsers_csv) {
    if ($entry.Path -match $pattern) {
        $entry.Path = $matches[0]
    }
}


# Filter users based on importable objects.
$filteredUsers_for_Import = $filteredUsers_csv | Select-Object -Property AccountExpirationDate, AccountDelegated, Country, Description, DisplayName,
EmailAddress, EmployeeID, GivenName, Initials, Name, Path, SamAccountName, ScriptPath, Surname, UserPrincipalName
$filteredUsers_for_Import | Export-Csv -Path "$path\AD_ExportADUsers_Enabled_for_Import.csv" -Encoding UTF8

