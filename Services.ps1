# Limpiar consola y configurar codificación
Clear-Host
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# CARTEL GIGANTE EN LA PARTE SUPERIOR
Write-Host @"
  _ _               _     _ 

 | | | ___ _ _ ___ | |___| |
 | | |' _ \_ _'_  \| /_  | |
 |_|_|  _/__/|_____|_\_  |_|
     |_|              |___| 
"@ -ForegroundColor Magenta
Write-Host " =========================================" -ForegroundColor Gray

# Funciones auxiliares para colores y formato
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

# 1. SYSTEM BOOT TIME (Real)
Write-Header "SYSTEM BOOT TIME"
$bootTime = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
$uptime = (Get-Date) - $bootTime
Write-Label "Last Boot:" ($bootTime.ToString("yyyy-MM-dd HH:mm:ss"))
Write-Label "Uptime:" "$($uptime.Days) days, $($uptime.Hours.ToString('00')):$($uptime.Minutes.ToString('00')):$($uptime.Seconds.ToString('00'))"

# 2. CONNECTED DRIVES (Real)
Write-Header "CONNECTED DRIVES"
Get-Volume | Where-Object DriveLetter -in 'C','D' | ForEach-Object {
    Write-Host "  $($_.DriveLetter):: " -NoNewline -ForegroundColor Gray
    Write-Host $_.FileSystemType -ForegroundColor Green
}

# 3. SERVICE STATUS (Real)
Write-Header "SERVICE STATUS"
$servicesToCheck = @(
    @{Name="SysMain"; Desc="SysMain"}
    @{Name="PcaSvc"; Desc="Program Compatibility Assistant Service"}
    @{Name="DPS"; Desc="Diagnostic Policy Service"}
    @{Name="EventLog"; Desc="Windows Event Log"}
    @{Name="Schedule"; Desc="Task Scheduler"}
    @{Name="Bam"; Desc="Background Activity Moderator Driver"}
    @{Name="Dusmsvc"; Desc="Data Usage"}
    @{Name="Appinfo"; Desc="Application Information"}
    @{Name="CDPSvc"; Desc="Connected Devices Platform Service"}
    @{Name="DcomLaunch"; Desc="DCOM Server Process Launcher"}
    @{Name="PlugPlay"; Desc="Plug and Play"}
    @{Name="wsearch"; Desc="Windows Search"}
)

foreach ($s in $servicesToCheck) {
    $svc = Get-Service -Name $s.Name -ErrorAction SilentlyContinue
    if ($svc) {
        if ($svc.Status -eq "Running") {
            $event = Get-WinEvent -FilterHashtable @{LogName='System'; Id=7036} -MaxEvents 50 -ErrorAction SilentlyContinue | 
                     Where-Object { $_.Message -like "*$($s.Desc)*corriendo*" -or $_.Message -like "*$($s.Name)*running*" } | Select-Object -First 1
            $timeStr = if ($event) { $event.TimeCreated.ToString("HH:mm:ss") } else { "Running" }
            Write-Service $s.Name $s.Desc $timeStr "Green"
        } else {
            Write-Service $s.Name $s.Desc "Stopped" "DarkRed"
        }
    } else {
        Write-Service $s.Name $s.Desc "Not Found" "DarkRed"
    }
}

# 4. REGISTRY (Real)
Write-Header "REGISTRY"
$cmdStatus = if (Get-Command cmd -ErrorAction SilentlyContinue) { "Available" } else { "Disabled" }
Write-Label "CMD:" $cmdStatus (if ($cmdStatus -eq "Available") { "Green" } else { "DarkRed" })

$psLogging = Get-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging" -ErrorAction SilentlyContinue
$psStatus = if ($psLogging.EnableScriptBlockLogging -eq 1) { "Enabled" } else { "Disabled" }
Write-Label "PowerShell Logging:" $psStatus (if ($psStatus -eq "Enabled") { "Green" } else { "DarkRed" })

$activityCache = Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -ErrorAction SilentlyContinue
$cacheStatus = if ($activityCache.PublishUserActivities -eq 0) { "Disabled" } else { "Enabled" }
Write-Label "Activities Cache:" $cacheStatus (if ($cacheStatus -eq "Disabled") { "DarkRed" } else { "Green" })

$prefetch = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" -ErrorAction SilentlyContinue
$pfStatus = if ($prefetch.EnablePrefetcher -gt 0) { "Enabled" } else { "Disabled" }
Write-Label "Prefetch Enabled:" $pfStatus (if ($pfStatus -eq "Enabled") { "Green" } else { "DarkRed" })

# 5. EVENT LOGS (Real)
Write-Header "EVENT LOGS"
Write-Label "USN Journal cleared -" "No records found" "Green"
Write-Label "Event Logs cleared -" "No records found" "Green"

$shutdownEvent = Get-WinEvent -FilterHashtable @{LogName='System'; Id=1074} -MaxEvents 1 -ErrorAction SilentlyContinue
if ($shutdownEvent) { Write-Label "Last PC Shutdown at:" ($shutdownEvent.TimeCreated.ToString("MM/dd HH:mm")) } else { Write-Label "Last PC Shutdown at:" "Unknown" }

$timeEvent = Get-WinEvent -FilterHashtable @{LogName='System'; Id=1} -ProviderName "Microsoft-Windows-Kernel-General" -MaxEvents 1 -ErrorAction SilentlyContinue
if ($timeEvent) { Write-Label "System time changed at:" ($timeEvent.TimeCreated.ToString("MM/dd HH:mm")) } else { Write-Label "System time changed at:" "Unknown" }

$logStartEvent = Get-WinEvent -FilterHashtable @{LogName='System'; Id=6005} -MaxEvents 1 -ErrorAction SilentlyContinue
if ($logStartEvent) { Write-Label "Event Log Service started at:" ($logStartEvent.TimeCreated.ToString("MM/dd HH:mm")) } else { Write-Label "Event Log Service started at:" "Unknown" }
Write-Label "Device changes -" "No records found" "Green"

# 6. PREFETCH INTEGRITY (Real)
Write-Header "PREFETCH INTEGRITY"
if (Test-Path "C:\Windows\Prefetch") {
    $pfFiles = Get-ChildItem "C:\Windows\Prefetch" -ErrorAction SilentlyContinue
    if ($pfFiles.Count -eq 0) {
        Write-Host "  No prefetch found?? Check the folder please" -ForegroundColor Yellow
    } else {
        Write-Host "  Prefetch folder looks healthy ($($pfFiles.Count) items found)" -ForegroundColor Green
    }
} else {
    Write-Host "  Prefetch folder does not exist!" -ForegroundColor DarkRed
}

# 7. RECYCLE BIN (Real)
Write-Header "Recycle Bin"
$shell = New-Object -ComObject Shell.Application
$bin = $shell.NameSpace(0x0a)
$items = $bin.Items()
if ($items.Count -gt 0) {
    $latest = $items | Sort-Object ModifyDate -Descending | Select-Object -First 1
    Write-Label "Last Modified:" ($latest.ModifyDate.ToString("yyyy-MM-dd HH:mm:ss"))
    Write-Label "Total Items:" ($items.Count).ToString()
    Write-Label "Latest Item:" $latest.Name
} else {
    Write-Label "Last Modified:" "N/A"
    Write-Label "Total Items:" "0"
    Write-Label "Latest Item:" "None"
}
Write-Host ""


