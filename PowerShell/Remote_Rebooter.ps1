# Iterates through a CSV file containing computer names or IPs,
# tests connectivity, and issues a remote reboot command if reachable.
# Useful for mass GPO deployment.

# Prompt for CSV file path
$csvPath = Read-Host "Enter the full path to the CSV file"

# Validate CSV file
if (-not (Test-Path $csvPath)) {
    Write-Host "CSV file not found at path: $csvPath" -ForegroundColor Red
    exit
}

# Timestamp for log files
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$successLog = "Reboot_Success_$timestamp.txt"
$failureLog = "Reboot_Failure_$timestamp.txt"

# Read each line as a computer name (no header expected)
$computers = Get-Content $csvPath

foreach ($ComputerName in $computers) {
    Write-Host "Testing $ComputerName..."

    if (Test-Connection -ComputerName $ComputerName -Count 2 -Quiet) {
        Write-Host "Success - Sending Reboot to $ComputerName..."

        # shutdown /m \\$ComputerName /r /t 10 /c "Automated reboot initiated."
        shutdown /m \\$ComputerName /r /t 1
        # Start-Sleep -Seconds 30  # Allow time for shutdown to begin

        # Wait for machine to go offline
        while (Test-Connection -ComputerName $ComputerName -Count 1 -Quiet) {
            Start-Sleep -Seconds 5
        }

        # Wait for machine to come back online
        while (-not (Test-Connection -ComputerName $ComputerName -Count 1 -Quiet)) {
            Start-Sleep -Seconds 5
        }

        Write-Host "Reboot Completed for $ComputerName."
        Add-Content -Path $successLog -Value "$ComputerName rebooted successfully at $(Get-Date)"
    }
    else {
        Write-Host "Failed - $ComputerName is not reachable." -ForegroundColor Yellow
        Add-Content -Path $failureLog -Value "$ComputerName unreachable at $(Get-Date)"
    }
}

Write-Host "`nScript completed."
Write-Host "Success log: $successLog"
Write-Host "Failure log: $failureLog"