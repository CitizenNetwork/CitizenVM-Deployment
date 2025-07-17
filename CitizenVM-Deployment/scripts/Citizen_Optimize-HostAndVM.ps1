# Citizen_Optimize-HostAndVM.ps1
# Host + VM Performance Optimizer for Citizen Gaming Dev Environments
# Timestamp: 2025-07-16 23:55:09

$logPath = "$PSScriptRoot\optimize_log.txt"
function Log {
    param([string]$msg)
    $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "$time`t$msg"
    Add-Content $logPath -Value $entry
    Write-Host $entry
}

Log "=== Starting Host and VM Optimization ==="

# ------------------------------
# HOST SYSTEM OPTIMIZATION
# ------------------------------
Log "[+] Disabling Windows animations on host..."
try {
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "UserPreferencesMask" -Value ([byte[]](0x9e,0x1e,0x07,0x80,0x12,0x00,0x00,0x00))
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop\WindowMetrics" -Name "MinAnimate" -Value "0"
    Log "[✓] Host visual performance tweaks applied."
} catch {
    Log "[!] Failed to apply visual tweaks on host: $_"
}

Log "[+] Disabling Xbox, diagnostics, telemetry..."
try {
    $services = @(
        "DiagTrack", "dmwappushservice", "XblAuthManager", "XblGameSave", "XboxNetApiSvc", "WMPNetworkSvc"
    )
    foreach ($svc in $services) {
        Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
        Set-Service -Name $svc -StartupType Disabled -ErrorAction SilentlyContinue
    }
    Log "[✓] Disabled Xbox and telemetry services."
} catch {
    Log "[!] Service disable failed: $_"
}

Log "[+] Stopping unnecessary services..."
try {
    $unneeded = @("PrintSpooler", "Fax", "RemoteRegistry", "Themes")
    foreach ($svc in $unneeded) {
        Stop-Service $svc -Force -ErrorAction SilentlyContinue
        Set-Service $svc -StartupType Disabled -ErrorAction SilentlyContinue
    }
    Log "[✓] Background service optimization complete."
} catch {
    Log "[!] Background service optimization skipped: $_"
}

Log "[+] Setting High Performance power plan..."
try {
    $plan = powercfg -l | Where-Object { $_ -like "*High performance*" } | ForEach-Object { ($_ -split '\s+')[3] }
    if ($plan) {
        powercfg -setactive $plan
    } else {
        powercfg -duplicatescheme SCHEME_MIN
        powercfg -setactive SCHEME_MIN
    }
    Log "[✓] High Performance plan activated."
} catch {
    Log "[!] Failed to set power plan: $_"
}

# ------------------------------
# VIRTUALBOX VM OPTIMIZATION
# ------------------------------
$VBoxManage = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
$vmName = "CitizenWinVM"

Log "[+] Applying VirtualBox VM performance tweaks..."
try {
    & "$VBoxManage" modifyvm $vmName --cpuexecutioncap 100 --ioapic on --paravirtprovider hyperv --chipset ich9 --largepages on
    Log "[✓] VirtualBox VM performance settings applied."
} catch {
    Log "[!] VirtualBox tweak failed: $_"
}

Log "[+] Compacting VM disk (if powered off)..."
try {
    $vmState = & "$VBoxManage" showvminfo $vmName --machinereadable | Where-Object { $_ -like 'VMState=*' }
    if ($vmState -match '"poweroff"') {
        & "$VBoxManage" modifymedium disk "C:\CitizenGaming\VMs\$vmName\$vmName.vdi" --compact
        Log "[✓] VM disk compacted."
    } else {
        Log "[=] VM is running. Skipping disk compaction."
    }
} catch {
    Log "[!] Disk compaction failed: $_"
}

Log "=== Optimization complete. Please restart the host and VM for best results ==="
