# Uses Invoke-Command to remotely install software.
# Devices must have a network connection, obviously.
# Deployment works by creating a Public Read-Only share from the workstation the script is deployed from.
# Script will make a Read/Write folder in the share, to write logs and test for remote PS session.
# The script then uses Invoke-Command to remotely instruct a powershell session to install the software.
# Currently will only work on 1 target machine, and will attempt to install 1 peice of software.

$target_workstation = ""
$share_location = "C:\remote_deployment\"
$auth_username = "Administrator"
$auth_password = ""

$target_workstation = Read-Host "Please enter the workstation name, or IP address of the target"
$share_location = Read-Host "Please enter the path of the share (default: C:\remote_deployment\)"
$auth_username = Read-Host "Please enter the Local Admin Level account username"
$auth_password = Read-Host "Please enter the Local Admin Level accounts password"

