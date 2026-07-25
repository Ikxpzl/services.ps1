Clear-Host

$Host.UI.RawUI.WindowTitle = "IKXPZ Windows Toolkit"

function Pause-Script {
    Read-Host "`nPulsa ENTER para continuar..."
}

function Show-Header {
    Clear-Host

    Write-Host ""
    Write-Host "=================================================" -ForegroundColor Cyan
    Write-Host "               IKXPZ WINDOWS TOOLKIT" -ForegroundColor White
    Write-Host "=================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Optimize-Windows {
    Show-Header

    Write-Host "[+] Desactivando SysMain..."
    Stop-Service SysMain -ErrorAction SilentlyContinue
    Set-Service SysMain -StartupType Disabled

    Write-Host "[+] Desactivando DiagTrack..."
    Stop-Service DiagTrack -ErrorAction SilentlyContinue
    Set-Service DiagTrack -StartupType Disabled

    Write-Host "[+] Desactivando hibernación..."
    powercfg -h off

    Write-Host ""
    Write-Host "Optimización completada." -ForegroundColor Green

    Pause-Script
}

function Clean-System {
    Show-Header

    Write-Host "[+] Limpiando archivos temporales..."

    Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue

    Write-Host ""
    Write-Host "Limpieza completada." -ForegroundColor Green

    Pause-Script
}

function Install-Apps {
    Show-Header

    $Apps = @(
        "Google.Chrome",
        "Mozilla.Firefox",
        "7zip.7zip",
        "Discord.Discord",
        "VideoLAN.VLC",
        "Microsoft.VisualStudioCode"
    )

    foreach ($App in $Apps) {
        winget install --id $App --accept-package-agreements --accept-source-agreements
    }

    Pause-Script
}

function System-Information {
    Show-Header

    Get-ComputerInfo |
    Select-Object `
        WindowsProductName,
        WindowsVersion,
        OsArchitecture,
        CsManufacturer,
        CsModel,
        BiosSMBIOSBIOSVersion

    Pause-Script
}

function MainMenu {

    while ($true) {

        Show-Header

        Write-Host "[1] Optimizar Windows"
        Write-Host "[2] Limpiar archivos temporales"
        Write-Host "[3] Instalar aplicaciones"
        Write-Host "[4] Información del sistema"
        Write-Host "[0] Salir"

        Write-Host ""

        $Option = Read-Host "Selecciona una opción"

        switch ($Option) {

            "1" { Optimize-Windows }

            "2" { Clean-System }

            "3" { Install-Apps }

            "4" { System-Information }

            "0" { break }

            Default {
                Write-Host ""
                Write-Host "Opción inválida." -ForegroundColor Red
                Start-Sleep 1
            }

        }

    }

}

MainMenu
