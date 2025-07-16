# Citizen Gaming VM Builder Script

$VBoxManage = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"

$vmName = "CitizenWinVM"
$vmIsoPath = "C:\ISOs\Win10_22H2_English_x64.iso"
$sharedFolderName = "CitizenShared"
$sharedFolderHostPath = "C:\CitizenGaming\Shared"
$vmDiskPath = "C:\CitizenGaming\VMs\$vmName\$vmName.vdi"
$rdpHostPort = 3390
$windowsKeyPath = "keys\windows_key.txt"

if (Test-Path $windowsKeyPath) {
    $windowsKey = Get-Content $windowsKeyPath -ErrorAction Stop
} else {
    Write-Error "? Windows product key file not found at $windowsKeyPath"
    exit 1
}

if (-not (Test-Path -Path (Split-Path $vmIsoPath))) {
    New-Item -ItemType Directory -Path (Split-Path $vmIsoPath) | Out-Null
}
if (-not (Test-Path -Path $vmIsoPath)) {
    Write-Error "? ISO file not found at $vmIsoPath"
    exit 1
} else {
    Write-Output "[=] ISO found at $vmIsoPath"
}

if (-not (Test-Path -Path $sharedFolderHostPath)) {
    New-Item -ItemType Directory -Path $sharedFolderHostPath | Out-Null
} else {
    Write-Output "[=] Shared folder exists at $sharedFolderHostPath"
}

$vms = & "$VBoxManage" list vms
$vmExists = $vms | Where-Object { $_ -like "*`"$vmName`"*"}
if (-not $vmExists) {
    Write-Output "[+] Creating VM '$vmName'"
    & "$VBoxManage" createvm --name $vmName --ostype Windows10_64 --register | Out-Null
} else {
    Write-Output "[=] VM '$vmName' already exists"
}

$vmInfo = & "$VBoxManage" showvminfo $vmName --machinereadable
$vmState = ($vmInfo | Where-Object { $_ -match '^VMState="(.+)"' }) -replace '^VMState="(.+)"','$1'
Write-Output "[=] VM state is '$vmState'"

& "$VBoxManage" modifyvm $vmName --memory 4096 --cpus 2 --vram 128 --nic1 nat --audio-driver none --boot1 dvd --boot2 disk --vrde on --vrdemulticon on | Out-Null
Write-Output "[+] VM hardware configured"

if (-not (Test-Path $vmDiskPath)) {
    & "$VBoxManage" createmedium disk --filename $vmDiskPath --size 50000 --format VDI | Out-Null
    Write-Output "[+] Created virtual disk"
} else {
    Write-Output "[=] Disk already exists"
}

try {
    & "$VBoxManage" storagectl $vmName --name "SATA Controller" --remove | Out-Null
} catch {}
& "$VBoxManage" storagectl $vmName --name "SATA Controller" --add sata --controller IntelAhci | Out-Null
& "$VBoxManage" storageattach $vmName --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium $vmDiskPath | Out-Null
Write-Output "[+] SATA disk attached"

$hasIDE = $vmInfo | Where-Object { $_ -match '^storagecontrollername\d+="IDE Controller"' }
if (-not $hasIDE) {
    & "$VBoxManage" storagectl $vmName --name "IDE Controller" --add ide | Out-Null
    Write-Output "[+] IDE controller created"
}
& "$VBoxManage" storageattach $vmName --storagectl "IDE Controller" --port 0 --device 0 --type dvddrive --medium $vmIsoPath | Out-Null
Write-Output "[+] Windows ISO attached"

$guestAdditionsIso = "C:\Program Files\Oracle\VirtualBox\VBoxGuestAdditions.iso"
if (Test-Path $guestAdditionsIso) {
    & "$VBoxManage" storageattach $vmName --storagectl "IDE Controller" --port 1 --device 0 --type dvddrive --medium $guestAdditionsIso | Out-Null
    Write-Output "[+] Guest Additions attached"
}

$hasShared = $vmInfo | Where-Object { $_ -like 'SharedFolderNameMachine=*' } | Where-Object { $_ -match ('"' + [Regex]::Escape($sharedFolderName) + '"') }
if (-not $hasShared) {
    & "$VBoxManage" sharedfolder add $vmName --name $sharedFolderName --hostpath $sharedFolderHostPath --automount --transient | Out-Null
    Write-Output "[+] Shared folder added"
} else {
    Write-Output "[=] Shared folder already exists"
}

$natRules = & "$VBoxManage" showvminfo $vmName --machinereadable | Where-Object { $_ -like "Forwarding*" }
if (-not ($natRules -match 'name="rdp"')) {
    & "$VBoxManage" modifyvm $vmName --natpf1 "rdp,tcp,,$rdpHostPort,,3389" | Out-Null
    Write-Output "[+] RDP NAT rule added"
}

Write-Output "[~] Starting unattended Windows install"
& "$VBoxManage" unattended install $vmName `
    --iso=$vmIsoPath `
    --user="CitizenAdmin" `
    --password="Secure1234" `
    --full-user-name="Admin User" `
    --key=$windowsKey `
    --install-additions `
    --time-zone="America/Chicago" `
    --post-install-command="shutdown -r -t 0" | Out-Null

Write-Output "? Unattended install started. VM '$vmName' is ready. You can start it via GUI or RDP on port $rdpHostPort."