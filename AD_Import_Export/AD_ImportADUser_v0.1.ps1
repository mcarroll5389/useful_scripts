<#
By Martin Carroll
Version 0.1 - tested and working.
#>

Write-Host "Please read the powershell script before you use this script"
Write-Host "This sets imported users to Enabled = True, and AccountDelegated to False" 
Write-Host "This script is designed to be used with the headers of a output from: Get-ADUser -Filter * -Properties * | export-CSV -Path x -Encoding UTF8, header values have to match what is in the script"
Write-Host "Path needs to set MANUALLY, not from an export, to the OU schema such as: OU=Users,DN=domain,DN=local - this will automatically then add them into the required OU. Ensure the OU exists first."
Write-Host "You will need to run a bulk password reset on the users created for this script, as the password is hard coded into the script to create the user."


<#
Customise this script as required as per the options available in the New-ADUser cmdlet, you'll need to add the array within the foreach look, then add it to the New-ADUser command.

NOTE that the UPN is unique within a FOREST, and the SamAccountName is unique within a DOMAIN. 
That means that you can use the same SamAccountName/Name etc, but you CAN'T set the UserPrincipalName as something else within the domain.
For example, if you have a domain.local domain, and a gb.domain.local child domain. If you're exporting from domain.local and importing into gb.domain.local, you'll need to change the UPN to have the @gb.domain.local UPN ending, as it wouldn't be unique in the forest.
The Name, SAM, and everything else can be a duplicate.

Important:
- Ensure files are UTF8 for multi-language characters. (Export-CSV -Path x -Encoding UTF8)
- You won't be able to import values which aren't found in the Add-ADUser cmdlet, as far as I am aware. This needs to be tested at some point for unique attributes, but there is likely a better way to do this.
- Path needs to be set and edited MANUALLY to place them into the correct OUs, and if you're using a new domain name, they also need to be edited (such as DN). You can use the DistinguishedName to basically make this for you, by removing the first reference to the object

#>

Import-Module ActiveDirectory -ErrorAction Stop

Write-Host "Note that Expiry will not be defined, Account Delegated will be set to False, and Enabled set to True."
$input_path = Read-Host "Please enter a full path to import the required CSV (C:\users.csv): "
$input_path = $input_path -replace '"',''
$aduser = Import-Csv $input_path -Encoding UTF8

foreach ($row in $aduser)
{
    $accountdelegated = $False
    $country = $row.Country
    $Description = $row.Description
    $DisplayName = $row.DisplayName
    $Email = $row.EmailAddress
    $EmployeeID = $row.EmployeeID
    $Enabled = $True
    $GivenName = $row.GivenName
    $Initials = $row.Initials
    $Name = $row.Name
    $Path = $row.Path
    $SAM = $row.SamAccountName
    $scriptPath = $row.ScriptPath
    $surname = $row.Surname
    $UPN = $row.UserPrincipalName
    New-ADUser -AccountNotDelegated $accountdelegated -Country $country -Description $Description -DisplayName $DisplayName -EmailAddress $Email -EmployeeID $EmployeeID -Enabled $Enabled -GivenName $GivenName -Initials $Initials -Name $Name -Path $Path -SamAccountName $SAM -ScriptPath $scriptPath -Surname $surname -UserPrincipalName $UPN -AccountPassword (ConvertTo-SecureString -AsPlainText "DhshdnDlkau8DpoapdmA@!FasdVac" -Force)
    if ($?) {
        Write-Host "User $SAM created successfully."
    } else {
        Write-Host "Failed to create user $SAM. It may already exist or there was an error."
    }
    
    }
