
$script_path = ($pwd).path

$allOUdata = Get-ADOrganizationalUnit -Filter * -Properties *
$allOUdata | Export-Csv -Path "$script_path\AD_ExportADOU_AllData.csv" -NoTypeInformation -Encoding UTF8

$OUdata_filtered = $allOUdata | Select-Object Name, DistinguishedName
$OUdata_filtered | Export-Csv -Path "$script_path\AD_ExportADOU_FilteredData.csv" -NoTypeInformation -Encoding UTF8

$pathOU = Import-Csv -Path "$script_path\AD_ExportADOU_filteredData.csv"

foreach ($entry in $pathOU) {
    Write-Host "Before: $($entry.DistinguishedName)"
    $entry.DistinguishedName = $entry.DistinguishedName -replace '^OU=[^,]+,', ''
    Write-Host "After: $($entry.DistinguishedName)"
}
Write-Host "Replaced the DN value to be used as -Path for ADImportOU. Removed anything before the first OU=."

$pathOU | Export-Csv -Path "$script_path\AD_ExportADOU_for_Import.csv" -NoTypeInformation -Encoding UTF8

Write-Host "Output files to $script_path."
Write-Host "Completed exporting AD OUs."
