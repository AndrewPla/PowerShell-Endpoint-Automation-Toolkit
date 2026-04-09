
    [CmdletBinding()]
    param(
        [int]$MinimumFreeSpaceGB = 5
    )

    function Test-IsAdministrator {
        try {
            $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
            $principal = New-Object Security.Principal.WindowsPrincipal($identity)
            return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        }
        catch {
            return $false
        }
    }

    function Test-PendingReboot {
        $paths = @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending",
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired"
        )

        foreach ($path in $paths) {
            if (Test-Path $path) {
                return $true
            }
        }

        return $false
    }

    try {
        $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
        $msiService = Get-Service -Name msiserver -ErrorAction SilentlyContinue

        [PSCustomObject]@{
            Timestamp             = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            ComputerName          = $env:COMPUTERNAME
            PowerShellVersion     = $PSVersionTable.PSVersion.ToString()
            IsAdministrator       = Test-IsAdministrator
            DiskFreeGB            = if ($disk) { [math]::Round($disk.FreeSpace / 1GB, 2) } else { $null }
            MeetsFreeSpaceTarget  = if ($disk) { (($disk.FreeSpace / 1GB) -ge $MinimumFreeSpaceGB) } else { $false }
            MSIServiceStatus      = if ($msiService) { $msiService.Status } else { "NotFound" }
            PendingReboot         = Test-PendingReboot
        }
    }
    catch {
        Write-Error $_.Exception.Message
        exit 1
    }
