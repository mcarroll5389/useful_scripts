<#
By Martin Carroll
Version 0.1 - tested and working.
#>

Import-Module ActiveDirectory

# Complete the path to the .csv file.

Write-Host "UNTESTED SORTING FUNCTION - USE WITH CAUTION - MANUALLY SORT INTO A HIERARCHY, OR TEST BEFORE USE."
Write-Host "READ THE POWERSHELL SCRIPT BEFORE PROGRESSING, OR YOU MAY BREAK THE OU."
Write-host "WARNING: No really, you could break it, really badly."

<#

Ensure that your OU EXPORT has been formatted correctly, you'll need a header with 'name' and 'distinguishedname'.

You can do something like this with 'Get-OrganizationalUnit -Filter * | Select-Object Name, DistinguishedName' 

You will also need to format your CSV into its hierarchical order, meaning that you must have the parent entry before you try to add a child.
To do this, format your csv via EXCEL, ensure its UTF-8, and is SORTED into an order based on the number of "," in the script.
Update: The script will attempt to this for you, if you're in prod, do this manually and review carefully as this is untested.

This can be done in Excel by:
=LEN(A1:A2)-LEN(SUBSTITUTE(A1:A2, ",", ""))

Once this is put in place, paste the values of the formula, then sort it all into an order. This will result in a hierarchical order based on its position within the DistinguishedName "OU=X,DC=X,DC=X" vs "OU=X,OU=X,DC=X,DC=X".

This will ensure that it runs the creation of the OU in order, Parent > Child > Child.

#>
Write-Host "CSV file should have headers 'Name' and 'DistinguishedName'"
$adou = Read-Host "Please provide the full path the csv file which is encoded with UTF8:"

#Import the provided csv
$adou_list = Import-Csv -Path $adou -Encoding UTF8

#Sort the OU based on its hierarchy within the AD

$sortedADOU = $adou_list | Sort-Object { ($_.DistinguishedName.Split(',').count -1) } -Descending

# Iterate through each item in the sorted ADOU CSV and find the header, then select the relevant header.

foreach ($ou in $sortedADOU)
{
    # Find the header "name"
    $name = $ou.Name
    # Find the header "distinguishedname"
    $path = $ou.DistinguishedName
    # Create those AD OUs.
    New-ADOrganizationalUnit -Name $name -Path $path
}

