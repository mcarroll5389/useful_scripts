# Large work in progress.
# Does not delete any metadata, just finds its location within the DNS records of a DC.
# DOES NOT work currently as its unable to find some records. May need to export each zone and iterate.

# Define a function to search for A, PTR, CNAME, and NS records from an input file
function Search-DnsRecordsFromFile {
    param (
        [Parameter(Mandatory=$true)]
        [string]$InputFile,

        [Parameter(Mandatory=$true)]
        [string]$OutputFile
    )

    # Get the current domain controller
    $DomainController = (Get-WmiObject -Class Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled }).DefaultIPGateway[0]

    if (-not $DomainController) {
        Write-Host "Could not determine the current domain controller. Exiting..."
        return
    }

    # Initialize an array to hold the results
    $results = @()

    # Read input file line by line
    $inputLines = Get-Content -Path $InputFile

    foreach ($line in $inputLines) {
        # Trim any whitespace from the line
        $line = $line.Trim()

        # Check if the line is empty or comment (starts with #)
        if (-not $line -or $line.StartsWith("#")) {
            continue
        }

        # Check if the line is an IP address (simple regex for IPv4)
        if ($line -match '^\d{1,3}(\.\d{1,3}){3}$') {
            Write-Host "Searching for PTR records for IP address: $line"

            # Reverse lookup - Convert IP to reverse lookup domain (e.g., 192.168.1.1 -> 1.168.192.in-addr.arpa)
            $reverseDomain = [string]$line -replace '(\d+)\.(\d+)\.(\d+)\.(\d+)', '$4.$3.$2.$1.in-addr.arpa'

            try {
                # Search for PTR records in reverse lookup zone
                $reverseDnsRecords = Resolve-DnsName -Name $reverseDomain -Type PTR -Server $DomainController -ErrorAction SilentlyContinue

                if ($reverseDnsRecords) {
                    # Loop through each PTR record found and output the details
                    foreach ($record in $reverseDnsRecords) {
                        $result = [PSCustomObject]@{
                            RecordType      = "PTR"
                            Hostname        = $record.Name
                            NameServer      = $record.NameServer
                            DomainController = $DomainController
                        }
                        $results += $result
                    }
                } else {
                    Write-Host "No PTR records found for IP '$line'."
                }
            } catch {
                Write-Warning "Error while searching for PTR records for IP '$line': $_"
            }

        } else {
            Write-Host "Searching for A, CNAME, NS records for hostname: $line"

            try {
                # Search for A (Address), CNAME (Canonical Name), and NS (Name Server) records in the forward lookup zone
                $dnsRecordsA = Resolve-DnsName -Name $line -Type "A" -Server $DomainController -ErrorAction SilentlyContinue
                $dnsRecordsCNAME = Resolve-DnsName -Name $line -Type "CNAME" -Server $DomainController -ErrorAction SilentlyContinue
                $dnsRecordsNS = Resolve-DnsName -Name $line -Type "NS" -Server $DomainController -ErrorAction SilentlyContinue

                # A records (IP addresses associated with the hostname)
                if ($dnsRecordsA) {
                    foreach ($record in $dnsRecordsA) {
                        $result = [PSCustomObject]@{
                            RecordType      = "A"
                            Hostname        = $record.Name
                            Address         = $record.IPAddress
                            DomainController = $DomainController
                        }
                        $results += $result
                    }
                }

                # CNAME records (Canonical name alias)
                if ($dnsRecordsCNAME) {
                    foreach ($record in $dnsRecordsCNAME) {
                        $result = [PSCustomObject]@{
                            RecordType      = "CNAME"
                            Hostname        = $record.Name
                            CanonicalName   = $record.CanonicalName
                            DomainController = $DomainController
                        }
                        $results += $result
                    }
                }

                # NS records (Name Servers)
                if ($dnsRecordsNS) {
                    foreach ($record in $dnsRecordsNS) {
                        $result = [PSCustomObject]@{
                            RecordType      = "NS"
                            Hostname        = $record.Name
                            NameServer      = $record.NameServer
                            DomainController = $DomainController
                        }
                        $results += $result

                        # Now also check A and CNAME records for the nameserver (if it's an NS record)
                        try {
                            $nsARecords = Resolve-DnsName -Name $record.NameServer -Type "A" -Server $DomainController -ErrorAction SilentlyContinue
                            if ($nsARecords) {
                                foreach ($nsRecord in $nsARecords) {
                                    $result = [PSCustomObject]@{
                                        RecordType      = "A"
                                        Hostname        = $record.NameServer
                                        Address         = $nsRecord.IPAddress
                                        DomainController = $DomainController
                                    }
                                    $results += $result
                                }
                            }

                            $nsCNAMERecords = Resolve-DnsName -Name $record.NameServer -Type "CNAME" -Server $DomainController -ErrorAction SilentlyContinue
                            if ($nsCNAMERecords) {
                                foreach ($nsCNAME in $nsCNAMERecords) {
                                    $result = [PSCustomObject]@{
                                        RecordType      = "CNAME"
                                        Hostname        = $record.NameServer
                                        CanonicalName   = $nsCNAME.CanonicalName
                                        DomainController = $DomainController
                                    }
                                    $results += $result
                                }
                            }
                        } catch {
                            Write-Warning "Error while checking A or CNAME records for nameserver '$record.NameServer': $_"
                        }
                    }
                }

            } catch {
                Write-Warning "Error while searching for A, CNAME, or NS records for hostname '$line': $_"
            }
        }
    }

    # Output results to the specified file
    if ($results.Count -gt 0) {
        $results | Export-Csv -Path $OutputFile -NoTypeInformation
        Write-Host "Results saved to $OutputFile"
    } else {
        Write-Host "No matching records found."
    }
}

# Get user input for input file and output file
$InputFile = Read-Host "Enter the full path of the input file (e.g., C:\input_file.txt)"
$OutputFile = Read-Host "Enter the full path of the output file (e.g., C:\dns_search_results.csv)"

# Call the function to search for A, PTR, CNAME, and NS records from the input file
Search-DnsRecordsFromFile -InputFile $InputFile -OutputFile $OutputFile
