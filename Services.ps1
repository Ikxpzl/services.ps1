# Limpiar consola y configurar codificación
Clear-Host
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# =========================================================================
# 1. DECLARACIÓN DE FUNCIONES
# =========================================================================
function Write-Header ($text) { 
    Write-Host "`n$text" -ForegroundColor Cyan 
}

function Write-Label ($label, $value) {
    Write-Host "  $label " -NoNewline -ForegroundColor Gray
    
    $valColor = "Yellow"
    if ($value -eq "Available" -or $value -eq "Enabled" -or $value -eq "Active" -or $value -eq "Active / Valid" -or $value -eq "Monitoring") { $valColor = "Green" }
    if ($value -like "Deleted*" -or $value -eq "Disabled" -or $value -eq "Deleted" -or $value -eq "Deleted / Inactive" -or $value -eq "Unknown" -or $value -like "Stopped*" -or $value -like "*Disabled*") { $valColor = "DarkRed" }
    
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
    if ($s.Name -eq "Bam") {
        $bamEvent = Get-WinEvent -FilterHashtable @{LogName='System'; Id=12} -MaxEvents 50 -ErrorAction SilentlyContinue | 
                    Where-Object { $_.Message -like "*bam*" -or $_.Properties.Value -like "*bam*" } | Select-Object -First 1
        $timeStr = if ($bamEvent) { $bamEvent.TimeCreated.ToString("HH:mm:ss") } else { $bootTime.ToString("HH:mm:ss") }
        Write-Service $s.Name $s.Desc $timeStr "Green"
        continue
    }

    $cimSvc = Get-CimInstance Win32_Service -Filter "Name='$($s.Name)'" -ErrorAction SilentlyContinue
    
    if ($cimSvc) {
        $today = (Get-Date).Date
        $event = Get-WinEvent -FilterHashtable @{LogName='System'; Id=7036} -MaxEvents 50 -ErrorAction SilentlyContinue | 
                 Where-Object { ($_.Properties.Value -contains $s.Name -or $_.Message -like "*$($s.Name)*") -and $_.TimeCreated -ge $today } | 
                 Sort-Object TimeCreated -Descending | Select-Object -First 1

        if ($cimSvc.StartMode -eq "Disabled") {
            $msg = if ($event) { "Stopped (Disabled) at $($event.TimeCreated.ToString('MM/dd HH:mm:ss'))" } else { "Stopped (Disabled)" }
            Write-Service $s.Name $s.Desc $msg "DarkRed"
            continue
        }
        
        if ($cimSvc.State -ne "Running") {
            $msg = if ($event) { "Stopped at $($event.TimeCreated.ToString('MM/dd HH:mm:ss'))" } else { "Stopped" }
            Write-Service $s.Name $s.Desc $msg "DarkRed"
            continue
        }

        $timeStr = ""
        if ($null -ne $cimSvc.ProcessId -and $cimSvc.ProcessId -gt 0) {
            $proc = Get-Process -Id $cimSvc.ProcessId -ErrorAction SilentlyContinue
            if ($proc -and $proc.StartTime) {
                $timeStr = $proc.StartTime.ToString("HH:mm:ss")
                if ($proc.StartTime -gt $bootTime.AddMinutes(5) -and $event) {
                    $timeStr = "$timeStr [RESTARTED at $($event.TimeCreated.ToString('HH:mm:ss'))]"
                    Write-Service $s.Name $s.Desc $timeStr "Yellow"
                    continue
                }
            }
        }

        if ([string]::IsNullOrEmpty($timeStr)) {
            $timeStr = if ($event) { $event.TimeCreated.ToString("HH:mm:ss") } else { "Running" }
        }

        Write-Service $s.Name $s.Desc $timeStr "Green"
    } else {
        Write-Service $s.Name $s.Desc "Not Found" "DarkRed"
    }
}

# =========================================================================
# 5. REGISTRY
# =========================================================================
Write-Header "REGISTRY"

$cmdStatus = if (Get-Command cmd -ErrorAction SilentlyContinue) { "Available" } else { "Disabled" }
Write-Label "CMD:" $cmdStatus

$psLogging = Get-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging" -ErrorAction SilentlyContinue
$psStatus = if ($psLogging -and $psLogging.EnableScriptBlockLogging -eq 1) { "Enabled" } else { "Disabled" }
Write-Label "PowerShell Logging:" $psStatus

$activityCache = Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -ErrorAction SilentlyContinue
$cacheStatus = if ($activityCache -and $activityCache.PublishUserActivities -eq 0) { "Disabled" } else { "Enabled" }
Write-Label "Activities Cache:" $cacheStatus

$prefetch = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" -ErrorAction SilentlyContinue
$pfStatus = if ($prefetch -and $prefetch.EnablePrefetcher -gt 0) { "Enabled" } else { "Disabled" }
Write-Label "Prefetch Enabled:" $pfStatus

# =========================================================================
# 6. EVENT LOGS
# =========================================================================
Write-Header "EVENT LOGS"

$isDeletedNow = $false
$recreatedRecent = $false
$usnTest = fsutil usn queryjournal C: 2>&1

if ($null -eq $usnTest -or $usnTest -match "Error" -or $usnTest -match "no" -or $usnTest -match "NOT" -or $usnTest.Count -le 2) {
    $isDeletedNow = $true
} else {
    $lowestUsnLine = $usnTest | Where-Object { $_ -match "Lowest USN|USN m.nimo" }
    if ($lowestUsnLine) {
        $lowestUsn = [int64]($lowestUsnLine -replace '\D+', '')
        if ($lowestUsn -le 1000) { $recreatedRecent = $true }
    }
}

# CAMBIO CLAVE: Forzamos la búsqueda de registros filtrando estrictamente desde las 00:00:00 de hoy
$todayDate = (Get-Date).Date
$foundEvents = @()
$foundEvents += Get-WinEvent -FilterHashtable @{LogName='System'; Id=98; StartTime=$todayDate} -MaxEvents 5 -ErrorAction SilentlyContinue
$foundEvents += Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-Ntfs/Operational'; Id=3079; StartTime=$todayDate} -MaxEvents 5 -ErrorAction SilentlyContinue
$foundEvents += Get-WinEvent -FilterHashtable @{LogName='Security'; Id=@(4660, 4656); StartTime=$todayDate} -MaxEvents 5 -ErrorAction SilentlyContinue

$latestDeletionEvent = $foundEvents | Where-Object { $null -ne $_ } | Sort-Object TimeCreated -Descending | Select-Object -First 1

if ($isDeletedNow) {
    $deleteTime = if ($latestDeletionEvent) { $latestDeletionEvent.TimeCreated.ToString("yyyy-MM-dd HH:mm:ss") } else { (Get-Date).ToString("yyyy-MM-dd HH:mm:ss") }
    Write-Label "USN Journal status -" "Deleted at $deleteTime"
} elseif ($recreatedRecent) {
    $deleteTime = if ($latestDeletionEvent) { $latestDeletionEvent.TimeCreated.ToString("yyyy-MM-dd HH:mm:ss") } else { (Get-Date).ToString("yyyy-MM-dd HH:mm:ss") }
    Write-Label "USN Journal status -" "Deleted / Recreated at $deleteTime"
} else {
    Write-Label "USN Journal status -" "Active"
}

Write-Label "Event Logs status -" "Monitoring"

$shutdownEvent = Get-WinEvent -FilterHashtable @{LogName='System'; Id=1074} -MaxEvents 1 -ErrorAction SilentlyContinue
if ($shutdownEvent) { Write-Label "Last PC Shutdown at:" ($shutdownEvent.TimeCreated.ToString("MM/dd HH:mm")) } else { Write-Label "Last PC Shutdown at:" "Unknown" }

$timeEvent = Get-WinEvent -FilterHashtable @{LogName='System'; Id=1; ProviderName="Microsoft-Windows-Kernel-General"} -MaxEvents 1 -ErrorAction SilentlyContinue
if ($timeEvent) { Write-Label "System time changed at:" ($timeEvent.TimeCreated.ToString("MM/dd HH:mm")) } else { Write-Label "System time changed at:" "Unknown" }

$logStartEvent = Get-WinEvent -FilterHashtable @{LogName='System'; Id=6005} -MaxEvents 1 -ErrorAction SilentlyContinue
if ($logStartEvent) { 
    Write-Label "Event Log Service started at:" ($logStartEvent.TimeCreated.ToString("MM/dd HH:mm")) 
} else { 
    Write-Label "Event Log Service started at:" "Unknown" 
}
Write-Host "  Device changes - " -NoNewline -ForegroundColor Gray
Write-Host "No records found" -ForegroundColor Green

# =========================================================================
# 7. PREFETCH INTEGRITY
# =========================================================================
Write-Header "PREFETCH INTEGRITY"
if (Test-Path "C:\Windows\Prefetch") {
    $pfFiles = Get-ChildItem "C:\Windows\Prefetch" -ErrorAction SilentlyContinue
    if ($null -eq $pfFiles -or $pfFiles.Count -eq 0) {
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

if ($null -ne $items -and $items.Count -gt 0) {
    $latest = $items | Sort-Object ModifyDate -Descending | Select-Object -First 1
    Write-Label "Last Modified:" ($latest.ModifyDate.ToString("yyyy-MM-dd HH:mm:ss"))
    Write-Label "Total Items:" ($items.Count).ToString()
    Write-Label "Latest Item:" $latest.Name
} else {
    Write-Label "Last Modified:" "N/A"
    Write-Label "Total Items:" "0"
    Write-Label "Latest Item:" "None"
}

# =========================================================================
# 9. ACTIVE SESSIONS & AUDIT
# =========================================================================
Write-Header "ACTIVE SESSIONS & AUDIT"
$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
Write-Label "Script Executed By:" $currentUser

$logonEvents = Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4624} -MaxEvents 5 -ErrorAction SilentlyContinue
if ($logonEvents) {
    Write-Host "  Recent Logons Detected:" -ForegroundColor Gray
    foreach ($logEv in $logonEvents) {
        Write-Host "    > Success Logon at $($logEv.TimeCreated.ToString('HH:mm:ss'))" -ForegroundColor Green
    }
} else {
    Write-Host "  No recent security logon events audited." -ForegroundColor Yellow
}
Write-Host ""
