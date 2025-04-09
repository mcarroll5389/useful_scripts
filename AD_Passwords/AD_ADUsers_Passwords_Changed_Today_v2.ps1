<#
By Martin Carroll
Version 2

# Version 2: Added reset on login flag export.
# Untested - may need to be tweaked.
#>

# Ensure the Active Directory module is loaded
Import-Module ActiveDirectory -ErrorAction Stop

$outputPath = ($pwd).Path
# Define today's date at midnight
$today = (Get-Date).Date.AddDays(-1)

# Retrieve all users and check if their password has been changed today
$allUsers = Get-ADUser -Filter * -Properties *

# Filter users into 3 lists.
# PasswordLastSet is null if the "Reset Password on Next Login" is set to True.
$usersChangedToday = $allUsers | Where-Object { $_.PasswordLastSet -ge $today -or $_.PasswordLastSet -eq $null }

$usersWithResetOnLogon = $allUsers | Where-Object { $_.ChangePasswordAtLogon -eq $true }

$usersNotChangedToday = $allUsers | Where-Object { $_.PasswordLastSet -lt $today -and $_.PasswordLastSet -ne $null }

# Output all lists to CSV files
$usersChangedTodayPath = "$outputPath\ADUsers_ChangedPasswordToday.csv"
$usersChangedToday | Select-Object SamAccountName, Name, PasswordLastSet, Enabled | 
    Export-Csv -Path "$usersChangedTodayPath" -NoTypeInformation -Encoding UTF8

$usersWithResetOnLogonPath = "$outputPath\ADUsers_UsersWithResetOnLogonSet.csv"
$usersWithResetOnLogon | Select-Object SamAccountName, Name, PasswordLastSet, Enabled | 
    Export-Csv -Path "$usersWithResetOnLogonPath" -NoTypeInformation -Encoding UTF8

$usersNotChangedTodayPath = "$outputPath\ADUsers_UsersNotChangedPasswordToday.csv"
$usersNotChangedToday | Select-Object SamAccountName, Name, PasswordLastSet, Enabled | 
    Export-Csv -Path "$usersNotChangedTodayPath" -NoTypeInformation -Encoding UTF8

Write-Output "CSV files generated:"
Write-Output "$usersChangedTodayPath"
Write-Output "$usersWithResetOnLogonPath"
Write-Output "$usersNotChangedTodayPath"

WRite-Host "Note that the ResetOnLogon flag can be intermittent and may not return values"
