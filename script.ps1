# Pfad zur snmpwalk.exe
$snmpWalkPath = "C:\Users\aaron\Downloads\SnmpWalk\snmpwalk.exe"

# IP-Adresse des Switches
$SwitchIP = "10.0.0.85"

# SNMP Community
$Community = "public"

# SNMP OIDs
$OID_dot1dStpPortState = "1.3.6.1.2.1.17.2.15.1.3"  # STP Port Status
$EndOID_dot1dStpPortState = "1.3.6.1.2.1.17.2.15.1.4"  # End OID for STP Port Status

# OID für Fehlerzustände
$OID_portErrors = "1.3.6.1.2.1.2.2.1.12"  # Fehler bei empfangenen Paketen
$EndOID_portErrors = "1.3.6.1.2.1.2.2.1.13"  # Ende für Port Error OID (einen Schritt nach der Fehler-OID)

# Funktion zur Abfrage von SNMP-Daten
function Get-SNMPData {
    param (
        [string]$SwitchIP,
        [string]$Community,
        [string]$OID,
        [string]$EndOID
    )

    $command = "$snmpWalkPath -r:$SwitchIP -c:$Community -os:$OID -op:$EndOID"
    Write-Host "Auszuführender Befehl: $command"
    $result = Invoke-Expression $command
    return $result
}

# Abfrage des STP-Portzustands
$stpPortStateResult = Get-SNMPData -SwitchIP $SwitchIP -Community $Community -OID $OID_dot1dStpPortState -EndOID $EndOID_dot1dStpPortState

# Abfrage des Fehlerzustands der Ports
$portErrorResult = Get-SNMPData -SwitchIP $SwitchIP -Community $Community -OID $OID_portErrors -EndOID $EndOID_portErrors

# Ergebnisse parsen und in ein Dictionary speichern
$stpPortStateDict = @{}
$portErrorDict = @{}

$stpPortStateResult -split "`n" | ForEach-Object {
    if ($_ -match "OID=.*1\.3\.6\.1\.2\.1\.17\.2\.15\.1\.3\.(\d+),.*Value=(\d+)") {
        $port = $matches[1]
        $state = $matches[2]
        $stpPortStateDict[$port] = $state
    }
}

$portErrorResult -split "`n" | ForEach-Object {
    if ($_ -match "OID=.*1\.3\.6\.1\.2\.1\.2\.2\.1\.12\.(\d+),.*Value=(\d+)") {
        $port = $matches[1]
        $errorCount = $matches[2]
        $portErrorDict[$port] = $errorCount
    }
}

# Ergebnisse ausgeben
Write-Host "Port-Status-Ergebnisse (Formatiert):"

# Portnummern sortieren
$sortedPorts = $stpPortStateDict.Keys | Sort-Object { [int]$_ }

foreach ($port in $sortedPorts) {
    $stpStateCode = $stpPortStateDict[$port]
    $errorCount = $portErrorDict[$port]

    # Statuscode zu Text zuordnen
    $stpStateText = switch ($stpStateCode) {
        1 { "disabled" }
        2 { "blocking" }
        3 { "listening" }
        4 { "learning" }
        5 { "forwarding" }
        6 { "broken" }
        default { "unknown" }
    }

    # Fehlerstatus basierend auf empfangenen Fehlern
    $errorStateText = if ($errorCount -gt 0) { "error-disable" } else { "no error" }

    Write-Host "Port ${port}: State=${stpStateText}, Errors=${errorCount}, Error State=${errorStateText}"
}
