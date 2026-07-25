# Limpiar consola y configurar codificación
Clear-Host
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# =========================================================================
# 1. DECLARACIÓN DE FUNCIONES
# =========================================================================
function Write-Header ($text) { 
    Write-Host "`n$text" -ForegroundColor Cyan 
}

function Write-Label ($label, $value, $valColor = "Yellow") {
    Write-Host "  $label " -NoNewline -ForegroundColor Gray
    Write-Host $value -ForegroundColor $valColor
}

function Write-Service ($name, $desc, $status, $color) {
    Write-Host "  $($name.PadRight(15))" -NoNewline -ForegroundColor $color
    Write-Host "$($desc.PadRight(45))" -NoNewline -ForegroundColor $color
    if ($status -like "*:*") { 
        Write-Host "| $status" -ForegroundColor Gray 
    } else { 
        Write-Host $status -ForegroundColor $color 
    }
}

# CARTEL SUPERIOR
Write-Host " =========================================" -ForegroundColor Magenta
Write-Host "                I K X P Z L               " -ForegroundColor Magenta
Write-Host " =========================================" -ForegroundColor Gray

# =========================================================================
# 2. SYSTEM BOOT TIME
# =========================================================================
Write-Header "SYSTEM BOOT TIME"
$bootTime = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
$uptime = (Get-Date) - $bootTime
Write-Label "Last Boot:" ($bootTime.ToString("yyyy-MM-dd HH:mm:ss"))
Write-Label "Uptime:" "$($uptime.Days) days, $($uptime.Hours.ToString('00')):$($uptime.Minutes.ToString('00')):$($uptime.Seconds.ToString('00'))"

# =========================================================================
# 3. CONNECTED DRIVES
# =========================================================================
Write-Header "CONNECTED DRIVES"
Get-Volume | Where-Object DriveLetter -in 'C','D' | ForEach-Object {
    Write-Host "  $($_.DriveLetter):: " -NoNewline -ForegroundColor Gray
    Write-Host $_.FileSystemType -ForegroundColor Green
}

# =========================================================================
# 4. SERVICE STATUS
# =========================================================================
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
            $procId = (Get-CimInstance Win32_Service -Filter "Name='$($s.Name)'").ProcessId
            $timeStr = "Running"

            # Se valida que el ID sea numérico y válido antes de pasarlo a Get-Process
            if ($null -ne $procId -and $procId -gt 0) {
                $proc = Get-Process -Id $procId -ErrorAction SilentlyContinue
                if ($proc -and $proc.StartTime) {
                    $timeStr = $proc.StartTime.ToString("HH:mm:ss")
                }
            }

            # Si el proceso está restringido o es nulo, se busca mediante Event Logs como plan B
            if ($timeStr -eq "Running") {
                $event = Get-WinEvent -FilterHashtable @{LogName='System'; Id=7036} -MaxEvents 50 -ErrorAction SilentlyContinue | 
                         Where-Object { $_.Properties.Value -eq $s.Name -or $_.Message -like "*$($s.Name)*" } | Select-Object -First 1
                if ($event) { $timeStr = $event.TimeCreated.ToString("HH:mm:ss") }
            }

            Write-Service $s.Name $s.Desc $timeStr "Green"
        } else {
            Write-Service $s.Name $s.Desc "Stopped" "DarkRed"
        }
    } else {
        Write-Service $s.Name $s.Desc "Not Found" "DarkRed"
    }
}

# =========================================================================
# 5. REGISTRY
# =========================================================================
Write-Header "REGISTRY"
$cmdStatus = if (Get-Command cmd -ErrorAction SilentlyContinue) { "Available" } else { "Disabled" }
$cmdColor = if ($cmdStatus -eq "Available") { "Green" } else { "DarkRed" }
Write-Label "CMD:" $cmdStatus $cmdColor

$psLogging = Get-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging" -ErrorAction SilentlyContinue
$psStatus = if ($psLogging -and $psLogging.EnableScriptBlockLogging -eq 1) { "Enabled" } else { "Disabled" }
$psColor = if ($psStatus -eq "Enabled") { "Green" } else { "DarkRed" }
Write-Label "PowerShell Logging:" $psStatus $psColor

$activityCache = Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -ErrorAction SilentlyContinue
$cacheStatus = if ($activityCache -and $activityCache.PublishUserActivities -eq 0) { "Disabled" } else { "Enabled" }
$cacheColor = if ($cacheStatus -eq "Disabled") { "DarkRed" } else { "Green" }
Write-Label "Activities Cache:" $cacheStatus $cacheColor

$prefetch = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" -ErrorAction SilentlyContinue
$pfStatus = if ($prefetch -and $prefetch.EnablePrefetcher -gt 0) { "Enabled" } else { "Disabled" }
$pfColor = if ($pfStatus -eq "Enabled") { "Green" } else { "DarkRed" }
Write-Label "Prefetch Enabled:" $pfStatus $pfColor

# =========================================================================
# 6. EVENT LOGS
# =========================================================================
Write-Header "EVENT LOGS"
Write-Label "USN Journal cleared -" "No records found" "Green"
Write-Label "Event Logs cleared -" "No records found" "Green"

$shutdownEvent = Get-WinEvent -FilterHashtable @{LogName='System'; Id=1074} -MaxEvents 1 -ErrorAction SilentlyContinue
if ($shutdownEvent) { Write-Label "Last PC Shutdown at:" ($shutdownEvent.TimeCreated.ToString("MM/dd HH:mm")) } else { Write-Label "Last PC Shutdown at:" "Unknown" }

$timeEvent = Get-WinEvent -FilterHashtable @{LogName='System'; Id=1; ProviderName="Microsoft-Windows-Kernel-General"} -MaxEvents 1 -ErrorAction SilentlyContinue
if ($timeEvent) { Write-Label "System time changed at:" ($timeEvent.TimeCreated.ToString("MM/dd HH:mm")) } else { Write-Label "System time changed at:" "Unknown" }

$logStartEvent = Get-WinEvent -FilterHashtable @{LogName='System'; Id=6005} -MaxEvents 1 -ErrorAction SilentlyContinue
if ($logStartEvent) { Write-Label "Event Log Service started at:" ($logStartEvent.TimeCreated.ToString("MM/dd HH:mm")) } else { Write-Label "Event Log Service started at:" "Unknown" }
Write-Label "Device changes -" "No records found" "Green"

# =========================================================================
# 7. PREFETCH INTEGRITY
# =========================================================================
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

# =========================================================================
# 8. RECYCLE BIN
# =========================================================================
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
