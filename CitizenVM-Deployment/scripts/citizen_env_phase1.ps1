# Citizen Dev Environment: Phase One Full Setup

$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$devRoot = "C:\CitizenGaming"
$scriptsDir = "C:\Windows\System32\Scripts"
$logFile = "$devRoot\setup_log.txt"

function Log-Write {
    param ([string]$msg)
    $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "$time`t$msg"
    if (!(Test-Path (Split-Path $logFile))) {
        New-Item -ItemType Directory -Path (Split-Path $logFile) -Force | Out-Null
    }
    Add-Content -Path $logFile -Value $entry
    Write-Host $msg
}

Log-Write "=== Phase One Setup Started ==="

$pathsToAdd = @(
    "C:\Program Files\Git\cmd",
    "C:\Program Files\Git\bin",
    "C:\Program Files\Microsoft VS Code\bin",
    "C:\Program Files\nodejs",
    "C:\xampp\php",
    "C:\Python311\Scripts",
    "C:\Python311"
)

foreach ($path in $pathsToAdd) {
    $current = [Environment]::GetEnvironmentVariable("Path", "Machine")
    if ($current -notlike "*$path*") {
        [Environment]::SetEnvironmentVariable("Path", "$current;$path", "Machine")
        Log-Write "[+] Added '$path' to machine PATH."
    }
}

if (!(Test-Path $scriptsDir)) {
    New-Item -ItemType Directory -Path $scriptsDir -Force | Out-Null
}

$gitScript = "$scriptsDir\CitizenEnvSetup.ps1"
@"
# Git defaults
if (-not (git config --global user.name)) {
    git config --global user.name 'CitizenDev'
    git config --global user.email 'devs@citizennetwork.dev'
}

# Load shared PowerShell profile
\$sharedProfile = 'C:\CitizenGaming\env\global_profile.ps1'
if (Test-Path \$sharedProfile) {
    . \$sharedProfile
}
"@ | Set-Content -Path $gitScript -Encoding UTF8
Log-Write "[+] Wrote Git setup script: $gitScript"

$sharedProfileDir = "C:\CitizenGaming\env"
$sharedProfileFile = "$sharedProfileDir\global_profile.ps1"

if (!(Test-Path $sharedProfileDir)) {
    New-Item -ItemType Directory -Path $sharedProfileDir -Force | Out-Null
}
@"
Write-Host 'Citizen Dev Environment Loaded.' -ForegroundColor Cyan

# Common aliases
Set-Alias code 'C:\Program Files\Microsoft VS Code\Code.exe'
Set-Alias gs git status
Set-Alias gp git push
"@ | Set-Content -Path $sharedProfileFile -Encoding UTF8
Log-Write "[+] Created global PowerShell profile."

$taskName = "CitizenDevEnvironmentSetup"
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$gitScript`""
$trigger = New-ScheduledTaskTrigger -AtLogOn
$principal = New-ScheduledTaskPrincipal -GroupId "BUILTIN\Users" -RunLevel Highest

try {
    if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
        Log-Write "[=] Removed existing task: $taskName"
    }
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal
    Log-Write "[?] Registered Git + Profile logon task."
} catch {
    Log-Write "[!] Failed to register scheduled task: $($_.Exception.Message)"
}

Log-Write "=== Phase One Setup Complete ==="

