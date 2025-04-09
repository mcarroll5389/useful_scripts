Import-Module ActiveDirectory -ErrorAction Stop

Write-Host "------------------------------------------------------------"
Write-Host "UNTESTED SCRIPT, USE WITH CAUTION"
Write-Host "------------------------------------------------------------"
Write-Host "Please read the powershell script before you use this script so you understand it."
Write-Host "This script exports all ADGroups and creates suitable CSVs.. It creates multiple csvs with different purposes" 
Write-Host "You can add additional properties to extract if required, as per Add-ADGroup cmdlet - but may not work with custom attributes"
Write-Host "Path (used for import) is not created automatically - the script will attempt to make this using the DistinguishedName and regex"
Write-Host "It'll attempt to make it in the format of: OU=Users,DN=domain,DN=local"
Write-Host "------------------------------------------------------------"



Read-Host "Press Enter to continue..."

$script_path = ($PWD).path

$all_ADGroup_Data = Get-ADGroup -Filter * -Properties *
$all_ADGroup_Data | Export-Csv -Path "$script_path\AD_ExportADGroups_All_Data.csv" -NoTypeInformation -Encoding UTF8

$filtered_ADGroup_Data = $all_ADGroup_Data | Select-Object Description, DisplayName, DistinguishedName, GroupCategory, GroupScope, Instance, Name, SamAccountName
$filtered_ADGroup_Data | Export-Csv -Path "$script_path\AD_ExportADGroups_Filtered.csv" -NoTypeInformation -Encoding UTF8

$path_ADGroups = Import-Csv -Path "$script_path\AD_ExportADGroups_All_Data.csv" | Select-Object *,"Path"


$path_ADGroups | ForEach-Object {
    $_.Path = $_.DistinguishedName
}

# Iterate through the csv and match the value in the Path column to the Regex Pattern.
foreach ($entry in $path_ADGroups) {
    Write-Host "Before: $($entry.Path)"
    $entry.Path = $entry.Path -replace '^.*?OU=', 'OU='
    Write-Host "After: $($entry.Path)"
}


$path_ADGroups_filtered = $path_ADGroups | Select-Object -Property Description, DisplayName, DistinguishedName, GroupCategory, GroupScope, Instance, Name, Path, SamAccountName
$path_ADGroups_filtered | Export-Csv -Path "$script_path\AD_ExportADGroups_for_Import.csv" -NoTypeInformation -Encoding UTF8

Write-Host "Output files to $script_path."
Write-Host "Completed."