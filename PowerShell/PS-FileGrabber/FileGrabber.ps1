# Note: Written with ChatGPT, some CoPilot, and me.

<#
.SYNOPSIS
    Copies files listed in a CSV (one file path per line) to an output folder,
    preserving directory structure but replacing the ':' in the drive root
    with a safe folder name (drive letter only). UNC paths are handled safely.

.PARAMETER FileList
    Path to CSV/text file containing file paths (one per line).

.PARAMETER OutputFolder
    Destination folder where files will be copied. Script creates subfolders as needed.

.EXAMPLE
    .\Copy-FilesFromList.ps1 -FileList "C:\input\files.csv" -OutputFolder "D:\collected"
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$FileList,

    [Parameter(Mandatory = $true)]
    [string]$OutputFolder
)

# Get user choice for directory structure
$user_input = Read-Host "Do you want to re-create the directory structure (Y/N)"
$user_input = $user_input.Trim().ToUpper()
if ($user_input -eq "Y" -or $user_input -eq "YES") {
    $remake_dir = $true
} elseif ($user_input -eq "N" -or $user_input -eq "NO") {
    $remake_dir = $false
} else {
    Write-Host "Invalid input. Defaulting to flat copy (N)." -ForegroundColor Yellow
    $remake_dir = $false
}

# Ensure output folder exists
if (-not (Test-Path -Path $OutputFolder)) {
    Write-Host "Creating output folder: $OutputFolder"
    New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null
}

# Validate file list exists
if (-not (Test-Path -Path $FileList)) {
    Write-Error "File list not found: $FileList"
    exit 1
}

# Read file list (supports CSV or plain text where each line is a path)
# We treat each line as a full path; ignore empty lines
$filePaths = Get-Content -Path $FileList | ForEach-Object { $_.Trim() } | Where-Object { $_ -and ($_ -ne '') }

# Prepare log
$LogFile = Join-Path $OutputFolder ("CopyLog_{0:yyyyMMdd_HHmmss}.txt" -f (Get-Date))
"Copy started: $(Get-Date -Format 'u')" | Out-File -FilePath $LogFile

foreach ($file in $filePaths) {
    try {
        
        if (-not (Test-Path -Path $file -PathType Leaf)) {
            "Missing: $file" | Out-File -FilePath $LogFile -Append
            continue
        }

        # Get root (drive or UNC root)
        $root = [System.IO.Path]::GetPathRoot($file)           # e.g. "C:\", "D:\", "\\server\share\"
        if (-not $root) {
            "Unable to determine root for: $file" | Out-File -FilePath $LogFile -Append
            continue
        }

        # Build safe top-level folder name
        if ($root -match '^[A-Za-z]:\\') {
            # Local drive like C:\ -> use just 'C'
            $driveLetter = $root.Substring(0,1).ToUpper()
            $topFolder = $driveLetter
        }
        elseif ($root -match '^\\\\') {
            # UNC path like \\server\share\ -> convert to UNC_server_share
            # Remove leading backslashes and replace remaining backslashes with underscore
            $uncSafe = $root.TrimStart('\') -replace '[\\\/]+','_'
            # remove trailing underscore if present
            $uncSafe = $uncSafe.TrimEnd('_')
            # prefix to avoid a purely numeric or ambiguous name
            $topFolder = "UNC_$uncSafe"
        }
        else {
            # Fallback: sanitize root by removing colon and backslashes
            $topFolder = ($root -replace '[:\\\/]','') 
            if (-not $topFolder) { $topFolder = "UNKNOWN_ROOT" }
        }

        # Compute relative path under the root
        $relative = $file.Substring($root.Length).TrimStart('\','/')

        # Destination full path depends on $remake_dir
        if ($remake_dir) {
            # Preserve directory structure under OutputFolder\<topFolder>
            $destRoot = Join-Path $OutputFolder $topFolder
            $destination = if ($relative) { Join-Path $destRoot $relative } else { $destRoot }
        }
        else {
            # Flat copy into OutputFolder. Keep original filename but make unique if collision.
            $fileName = Split-Path -Leaf $file
            $baseName = [System.IO.Path]::GetFileNameWithoutExtension($fileName)
            $ext = [System.IO.Path]::GetExtension($fileName)
            $destination = Join-Path $OutputFolder $fileName

            $counter = 1
            while (Test-Path -Path $destination) {
                $newName = "{0}_{1}{2}" -f $baseName, $counter, $ext
                Write-Host "Warning: File '$fileName' already exists in output folder. Renaming to '$newName'." -ForegroundColor Yellow
                "Collision: $fileName already exists. Renamed to $newName" | Out-File -FilePath $LogFile -Append
                $destination = Join-Path $OutputFolder $newName
                $counter++
            }
        }

        # Ensure destination directory exists
        $destDir = Split-Path -Parent $destination
        if (-not (Test-Path -Path $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }

        # Copy file
        Copy-Item -Path $file -Destination $destination -Force
        "Copied: $file -> $destination" | Out-File -FilePath $LogFile -Append
    }
    catch {
        "Error copying $file : $($_.Exception.Message)" | Out-File -FilePath $LogFile -Append
    }
}

"Copy complete: $(Get-Date -Format 'u')" | Out-File -FilePath $LogFile -Append
Write-Host "Done. Log file: $LogFile"
