# PowerShell Script: Setup CitizenDevs Group, Admin Users, Folder Permissions, and Security Hardening
# For Citizen Gaming Network - Secure, Repeatable Setup

# CONFIGURABLE SETTINGS
$devGroup = "CitizenDevs"
$testGroup = "CitizenTesters"
$allGroups = @($devGroup, $testGroup)

$users = @(
    @{ Name = "Citizen_Admin"; Password = "C!tizenNet2025!"; Group = $devGroup },
    @{ Name = "GTAKING2300"; Password = "TempPass123!"; Group = $devGroup },
    @{ Name = "chrisvegas"; Password = "VegasTemp!"; Group = $testGroup }
)

$devRoot = "C:\CitizenGaming"
$logFile = "$devRoot\setup_log.txt"

function Log-Write {
    param([string]$message)
    $logDir = Split-Path $logFile
    if (-not (Test-Path $logDir)) {
        New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    }
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $entry = "$timestamp`t$message"
    Add-Content -Path $logFile -Value $entry
    Write-Host $message
}

Log-Write "=== Setup started ==="

try {
    foreach ($g in $allGroups) {
        if (-not (Get-LocalGroup -Name $g -ErrorAction SilentlyContinue)) {
            New-LocalGroup -Name $g -Description "Citizen Gaming $g group" | Out-Null
            Log-Write "[+] Group '$g' created."
        } else {
            Log-Write "[=] Group '$g' already exists."
        }
    }

    foreach ($u in $users) {
        $name = $u.Name
        $pw = ConvertTo-SecureString $u.Password -AsPlainText -Force
        $group = $u.Group

        if (-not (Get-LocalUser -Name $name -ErrorAction SilentlyContinue)) {
            New-LocalUser -Name $name -Password $pw -PasswordNeverExpires -Description "$group Member" | Out-Null
            Log-Write "[+] Created user '$name'."
        } else {
            Log-Write "[=] User '$name' already exists. Updating password."
            Set-LocalUser -Name $name -Password $pw -PasswordNeverExpires $true
        }

        Add-LocalGroupMember -Group $group -Member $name -ErrorAction SilentlyContinue
        Add-LocalGroupMember -Group "Administrators" -Member $name -ErrorAction SilentlyContinue

        if ($name -eq "GTAKING2300") {
            net user GTAKING2300 /logonpasswordchg:yes | Out-Null
            Log-Write "[~] Forced password change at next login for $name."
        }

        try {
            $sid = (Get-LocalUser $name).SID.Value
            $basePath = "Registry::HKEY_USERS\$sid"
            $regPath = "$basePath\Software\Policies\Microsoft\Windows\System"

            if (Test-Path $basePath) {
                New-Item -Path $regPath -Force | Out-Null
                New-ItemProperty -Path $regPath -Name "DisableCMD" -Value 1 -PropertyType DWord -Force | Out-Null
                Log-Write "[~] Hardened '$name' by disabling CMD."
            } else {
                Log-Write "[~] Skipped CMD hardening for $name (not logged in yet)."
            }
        } catch {
            $err = $_.Exception.Message
            Log-Write "[!] Failed to harden ${name}: $err"
        }
    }

    if (-not (Test-Path $devRoot)) {
        New-Item -Path $devRoot -ItemType Directory -Force | Out-Null
        Log-Write "[+] Created dev root folder at $devRoot."
    } else {
        Log-Write "[=] Dev root folder already exists: $devRoot."
    }

    $acl = Get-Acl $devRoot
    $acl.SetAccessRuleProtection($true, $false)
    $acl.Access | ForEach-Object { $acl.RemoveAccessRule($_) }

    $owner = [System.Security.Principal.NTAccount]::new("$env:USERDOMAIN\$env:USERNAME")
    $ruleOwner = New-Object System.Security.AccessControl.FileSystemAccessRule($owner, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
    $acl.AddAccessRule($ruleOwner)

    $ruleDev = New-Object System.Security.AccessControl.FileSystemAccessRule($devGroup, "Modify", "ContainerInherit,ObjectInherit", "None", "Allow")
    $acl.AddAccessRule($ruleDev)

    $ruleTester = New-Object System.Security.AccessControl.FileSystemAccessRule($testGroup, "Write,Modify,ExecuteFile,Delete", "ContainerInherit,ObjectInherit", "None", "Allow")
    $acl.AddAccessRule($ruleTester)

    Set-Acl -Path $devRoot -AclObject $acl
    Log-Write "[✓] Applied strict ACLs to '$devRoot' for groups."

    Log-Write "=== Setup complete ==="
} catch {
    $err = $_.Exception.Message
    Log-Write "[!] Script failed unexpectedly: $err"
}
