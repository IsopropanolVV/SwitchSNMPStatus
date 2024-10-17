
# Pfad zur snmpwalk.exe
$snmpWalkPath = "C:\Users\aaron\Downloads\SnmpWalk\snmpwalk.exe"

# IP-Adresse des Switches
$SwitchIP = "10.0.0.85"

# SNMP Community
$Community = "public"

# SNMP OID für den Port-Status (MIB-2)
$OID_PortStatus = "1.3.6.1.2.1.2.2.1.8"

# End-OID, um den Walk zu begrenzen
$EndOID = "1.3.6.1.2.1.2.2.1.9"

# Funktion zur Abfrage des Port-Status mit snmpwalk.exe
function Get-SNMPPortStatus {
    param (
        [string]$SwitchIP,
        [string]$Community,
        [string]$OID,
        [string]$EndOID
    )
    
    # Korrekte Syntax für snmpwalk.exe mit End-OID
    $command = "$snmpWalkPath -r:$SwitchIP -c:$Community -os:$OID -op:$EndOID"
    
    # Befehl anzeigen, um zu überprüfen, ob er korrekt ist
    Write-Host "Auszuführender Befehl: $command"
    
    # Den Befehl ausführen und Ergebnis zurückgeben
    $result = Invoke-Expression $command
    return $result
}

# Abfrage durchführen und Ergebnisse anzeigen
$statusResult = Get-SNMPPortStatus -SwitchIP $SwitchIP -Community $Community -OID $OID_PortStatus -EndOID $EndOID

Write-Host "Port-Status-Ergebnisse (Formatiert):"

# Formatiere die Ausgabe, um die Port-Nummern und Statuswerte zu zeigen
$statusResult -split "`n" | ForEach-Object {
    if ($_ -match "OID=.*1\.3\.6\.1\.2\.1\.2\.2\.1\.8\.(\d+),.*Value=(\d+)") {
        $port = $matches[1]
        $status = $matches[2]
        $statusText = if ($status -eq 1) { "up" } else { "down" }
        Write-Host "Port ${port}: ${statusText}"
    }
}
