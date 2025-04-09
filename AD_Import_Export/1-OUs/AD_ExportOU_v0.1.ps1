<#
By Martin Carroll
Version 0.1 - tested and working.
#>


Write-Host "------------------------------------------------------------"
Write-Host "Please read the Powershell Script comments before you use this script"
Write-Host "Used to export the OUs from AD."
Write-Host "To be used in conjuction with 'AD_ImportOU_vX.X.ps1'"
Write-Host "------------------------------------------------------------"
Read-Host "Press Enter to continue"



$script_path = ($pwd).path

$allOUdata = Get-ADOrganizationalUnit -Filter * -Properties *
$allOUdata | Export-Csv -Path "$script_path\3-AD_ExportADOU_AllData.csv" -NoTypeInformation -Encoding UTF8

$OUdata_filtered = $allOUdata | Select-Object Name, DistinguishedName
$OUdata_filtered | Export-Csv -Path "$script_path\2-AD_ExportADOU_FilteredData.csv" -NoTypeInformation -Encoding UTF8

$pathOU = Import-Csv -Path "$script_path\2-AD_ExportADOU_filteredData.csv"

foreach ($entry in $pathOU) {
    Write-Host "Before: $($entry.DistinguishedName)"
    $entry.DistinguishedName = $entry.DistinguishedName -replace '^OU=[^,]+,', ''
    Write-Host "After: $($entry.DistinguishedName)"
}
Write-Host "Replaced the DN value to be used as -Path for ADImportOU. Removed anything before the first OU=."

$pathOU | Export-Csv -Path "$script_path\1-AD_ExportADOU_for_Import.csv" -NoTypeInformation -Encoding UTF8

Write-Host "Output files to $script_path."
Write-Host "Completed exporting AD OUs."

Read-Host "Press Enter to continue"
