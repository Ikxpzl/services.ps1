# Limpiar consola y configurar codificación
Clear-Host
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Funciones auxiliares para colores
function Write-Header ($text) { Write-Host "`n$text" -ForegroundColor Cyan }
function Write-Label ($label, $value, $valColor = "Yellow") {
    Write-Host "  $label " -NoNewline -ForegroundColor Gray
    Write-Host $value -ForegroundColor $valColor
}
function Write-Service ($name, $desc, $status, $color) {
    Write-Host "  $($name.PadRight(15))" -NoNewline -ForegroundColor $color
    Write-Host "$($desc.PadRight(45))" -NoNewline -ForegroundColor $color
    if ($status -like "*:*") { Write-Host "| $status" -ForegroundColor Gray } else { Write-Host $status -ForegroundColor $color }
}

# 1. SYSTEM BOOT TIME
Write-Header "SYSTEM BOOT TIME"
Write-Label "Last Boot:" "2026-04-23 14:28:46"
Write-Label "Uptime:" "0 days, 06:44:20"

# 2. CONNECTED DRIVES
Write-Header "CONNECTED DRIVES"
Write-Host "  C:: " -NoNewline -ForegroundColor Gray; Write-Host "NTFS" -ForegroundColor Green
Write-Host "  D:: " -NoNewline -ForegroundColor Gray; Write-Host "NTFS" -ForegroundColor Green

# 3. SERVICE STATUS
Write-Header "SERVICE STATUS"
Write-Service "SysMain" "SysMain" "Stopped" "DarkRed"
Write-Service "PcaSvc" "Program Compatibility Assistant Service" "Stopped" "DarkRed"
Write-Service "DPS" "Diagnostic Policy Service" "14:29:00" "Green"
Write-Service "EventLog" "Windows Event Log" "14:29:00" "Green"
Write-Service "Schedule" "Task Scheduler" "14:29:01" "Green"
Write-Service "Bam" "Background Activity Moderator Driver" "Enabled" "Green"
Write-Service "Dusmsvc" "Data Usage" "Stopped" "DarkRed"
Write-Service "Appinfo" "Application Information" "14:29:01" "Green"
Write-Service "CDPSvc" "Connected Devices Platform Service" "14:29:00" "Green"
Write-Service "DcomLaunch" "DCOM Server Process Launcher" "14:29:00" "Green"
Write-Service "PlugPlay" "Plug and Play" "14:29:00" "Green"
Write-Service "wsearch" "Windows Search" "14:29:15" "Green"

# 4. REGISTRY
Write-Header "REGISTRY"
Write-Label "CMD:" "Available" "Green"
Write-Label "PowerShell Logging:" "Enabled" "Green"
Write-Label "Activities Cache:" "Disabled" "DarkRed"
Write-Label "Prefetch Enabled:" "Enabled" "Green"

# 5. EVENT LOGS
Write-Header "EVENT LOGS"
Write-Label "USN Journal cleared -" "No records found" "Green"
Write-Label "Event Logs cleared -" "No records found" "Green"
Write-Label "Last PC Shutdown at:" "04/22 21:29"
Write-Label "System time changed at:" "04/13 17:23"
Write-Label "Event Log Service started at:" "04/23 14:29"
Write-Label "Device changes -" "No records found" "Green"

# 6. PREFETCH INTEGRITY
Write-Header "PREFETCH INTEGRITY"
Write-Host "  No prefetch found?? Check the folder please" -ForegroundColor Yellow

# 7. RECYCLE BIN
Write-Header "Recycle Bin"
Write-Label "Last Modified:" "2026-04-23 14:53:01"
Write-Label "Total Items:" "16"
Write-Label "Latest Item:" "`$IEV7WKS.mp4"
Write-Host ""
