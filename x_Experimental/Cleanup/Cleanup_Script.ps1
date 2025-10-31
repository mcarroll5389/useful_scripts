# Cleanup_Script.ps1

# Function to display folder content as a tree
function Show-FolderTree {
    param (
        [string]$Path
    )
    Write-Host "Contents of $Path :" -ForegroundColor Cyan
    Get-ChildItem -Path $Path -Recurse | ForEach-Object {
        $indent = (' ' * ($_.FullName.Split('\').Count - $Path.Split('\').Count))
        Write-Host "$indent $_"
    }
}

# Prompt for folder name to search
$folderName = Read-Host "Enter the name of the folder to search for (only in C:\)"

# Search for folders with the specified name
$folders = Get-ChildItem -Path "C:\" -Recurse -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $folderName }

if ($folders.Count -ne 0 -or $folders.Count -ne $null) {
    foreach ($folder in $folders) {
        Show-FolderTree -Path $folder.FullName
        $remove = Read-Host "Do you want to remove the folder '$($folder.FullName)' and its contents? (yes/no)"
        if ($remove -eq "yes") {
            Remove-Item -Path $folder.FullName -Recurse -Force
            Write-Host "Folder '$($folder.FullName)' has been removed." -ForegroundColor Green
        } else {
            Write-Host "Folder '$($folder.FullName)' was not removed." -ForegroundColor Yellow
        }
    }
    } else {
    Write-Host "No folders named '$folderName' were found." -ForegroundColor Yellow
}

# Prompt to clear RDP data
$clearRDP = Read-Host "Do you want to clear RDP data? (yes/no)"
if ($clearRDP -eq "yes") {
    Remove-Item -Path "HKCU:\Software\Microsoft\Terminal Server Client\Default" -Recurse -ErrorAction SilentlyContinue
    Remove-Item -Path "HKCU:\Software\Microsoft\Terminal Server Client\Servers" -Recurse -ErrorAction SilentlyContinue
    Write-Host "RDP data has been cleared." -ForegroundColor Green
} else {
    Write-Host "RDP data was not cleared." -ForegroundColor Yellow
}

# Prompt to clear PowerShell history
$clearPSHistory = Read-Host "Do you want to clear PowerShell history? (yes/no)"
if ($clearPSHistory -eq "yes") {
    Clear-History
    Write-Host "PowerShell history has been cleared." -ForegroundColor Green
} else {
    Write-Host "PowerShell history was not cleared." -ForegroundColor Yellow
}

# Prompt for username to search in Active Directory
$username = Read-Host "Enter the username to search in Active Directory"

# Search for the user in Active Directory
try {
    $user = Get-ADUser -Filter "Name -like '$username'"
    if ($user) {
        Write-Host "User '$username' found in Active Directory." -ForegroundColor Green
        $deleteUser = Read-Host "Do you want to delete the user '$username'? (yes/no)"
        if ($deleteUser -eq "yes") {
            Remove-ADUser -Identity $user.SamAccountName -Confirm:$false
            Write-Host "User '$username' has been deleted." -ForegroundColor Green
        } else {
            Write-Host "User '$username' was not deleted." -ForegroundColor Yellow
        }
    }
} catch {
    Write-Host "User '$username' was not found in Active Directory." -ForegroundColor Yellow
}