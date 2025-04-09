<#
By Martin Carroll
Version 0.1 - tested and working.
#>

Import-Module ActiveDirectory -ErrorAction Stop

Write-Host "------------------------------------------------------------"
Write-Host "Please read the Powershell Script comments before you use this script"
Write-Host "Used to import the Groups from AD."
Write-Host "NOTE: This does NOT add users into the respective groups when copied - it is only used to create the groups, not assign members."
Write-Host "To be used in conjuction with 'AD_ExportADGroups_vX.X.ps1'"
Write-Host "You'll likely want to use the exported data with a '1-' at the start'"
Write-Host "------------------------------------------------------------"
Read-Host "Press Enter to continue"

$import = Read-Host "Please enter the path to the CSV file you want to import (e.g., C:\path\to\your\file.csv)"
$import = $import -replace '"',''
$new_server_fqdn = Read-Host "Please enter the FQDN of the new server (such as server.domain.local)"
Read-Host "Are you sure you want to import the groups from $import to $new_server_fqdn ? Press Enter to continue or Ctrl+C to cancel."

$all_groups = Import-Csv -Path $import -Encoding UTF8

foreach ($group in $all_groups)
{
    $Description = $group.Description
    $DisplayName = $group.DisplayName
    $groupCategory = $group.GroupCategory
    $groupScope = $group.GroupScope 
    $homepage = $group.HomePage
    $instance = $group.Instance
    $managedBy = $group.ManagedBy
    $Name = $group.Name
    $Path = $group.Path
    $SAM = $group.SamAccountName
    $server = $new_server_fqdn

    New-ADGroup -Description $Description -DisplayName $DisplayName -GroupCategory $groupCategory -GroupScope $groupScope -HomePage $homepage -Instance $instance -ManagedBy $managedBy -Name $Name -Path $Path -SamAccountName $SAM -Server $server -ErrorAction SilentlyContinue
    if ($?) {
        Write-Host "Group $DisplayName created successfully."
    } else {
        Write-Host "Failed to create group $DisplayName . It may already exist or there was an error."
    }
}

Write-Host "Script finished."
Read-Host "Press Enter to continue"