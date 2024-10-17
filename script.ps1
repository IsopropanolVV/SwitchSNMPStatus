﻿# Pfad zur snmpwalk.exe
$snmpWalkPath = "C:\Users\aaron\Downloads\SnmpWalk\snmpwalk.exe"

# IP-Adresse des Switches
$SwitchIP = "10.0.0.85"

# SNMP Community
$Community = "public"

# SNMP OIDs für den Admin- und Oper-Status (MIB-2)
$OID_ifAdminStatus = "1.3.6.1.2.1.2.2.1.7"
$EndOID_ifAdminStatus = "1.3.6.1.2.1.2.2.1.8" # Ende nach ifAdminStatus

$OID_ifOperStatus = "1.3.6.1.2.1.2.2.1.8"
$EndOID_ifOperStatus = "1.3.6.1.2.1.2.2.1.9" # Ende nach ifOperStatus

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

# Abfrage des Admin-Status
$adminStatusResult = Get-SNMPData -SwitchIP $SwitchIP -Community $Community -OID $OID_ifAdminStatus -EndOID $EndOID_ifAdminStatus

# Abfrage des Oper-Status
$operStatusResult = Get-SNMPData -SwitchIP $SwitchIP -Community $Community -OID $OID_ifOperStatus -EndOID $EndOID_ifOperStatus

# Ergebnisse parsen und in Dictionaries speichern
$adminStatusDict = @{}
$adminStatusResult -split "`n" | ForEach-Object {
    if ($_ -match "OID=.*1\.3\.6\.1\.2\.1\.2\.2\.1\.7\.(\d+),.*Value=(\d+)") {
        $port = $matches[1]
        $status = $matches[2]
        $adminStatusDict[$port] = $status
    }
}

$operStatusDict = @{}
$operStatusResult -split "`n" | ForEach-Object {
    if ($_ -match "OID=.*1\.3\.6\.1\.2\.1\.2\.2\.1\.8\.(\d+),.*Value=(\d+)") {
        $port = $matches[1]
        $status = $matches[2]
        $operStatusDict[$port] = $status
    }
}

# Ergebnisse kombinieren und ausgeben
Write-Host "Port-Status-Ergebnisse (Formatiert):"
foreach ($port in $adminStatusDict.Keys) {
    $adminStatusCode = $adminStatusDict[$port]
    $operStatusCode = $operStatusDict[$port]

    # Statuscodes zu Texten zuordnen
    $adminStatusText = switch ($adminStatusCode) {
        1 { "up" }
        2 { "down" }
        3 { "testing" }
        default { "unknown" }
    }

    $operStatusText = switch ($operStatusCode) {
        1 { "up" }
        2 { "down" }
        3 { "testing" }
        4 { "unknown" }
        5 { "dormant" }
        6 { "notPresent" }
        7 { "lowerLayerDown" }
        default { "unknown" }
    }

    Write-Host "Port ${port}: AdminStatus=${adminStatusText}, OperStatus=${operStatusText}"
}
