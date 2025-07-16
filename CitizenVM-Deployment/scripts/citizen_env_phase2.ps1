# Citizen Dev Environment: Phase 2 Tools Setup

$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$tempDir = "$env:TEMP"
$devRoot = "C:\CitizenGaming"

function Log-Write {
    param ([string]$msg)
    $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "$time`t$msg"
}

Log-Write "=== Phase 2 Setup Started ==="

if (-not (Test-Path $devRoot)) {
    New-Item -Path $devRoot -ItemType Directory | Out-Null
    Log-Write "[+] Created dev folder at $devRoot"
} else {
    Log-Write "[=] Dev folder exists: $devRoot"
}

if (-not (Get-Command choco.exe -ErrorAction SilentlyContinue)) {
    Log-Write "[+] Installing Chocolatey..."
    Set-ExecutionPolicy Bypass -Scope Process -Force
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    Log-Write "[+] Chocolatey installed."
} else {
    Log-Write "[=] Chocolatey already installed."
}

$env:Path += ";C:\ProgramData\chocolatey\bin"

if (-not (Get-Command python.exe -ErrorAction SilentlyContinue)) {
    Log-Write "[+] Installing Python..."
    choco install python --yes --force
    Log-Write "[+] Python installed."
} else {
    Log-Write "[=] Python already installed."
}

if (-not (Get-Command node.exe -ErrorAction SilentlyContinue)) {
    Log-Write "[+] Installing Node.js LTS..."
    choco install nodejs-lts --yes --force
    Log-Write "[+] Node.js LTS installed."
} else {
    Log-Write "[=] Node.js already installed."
}

$pathsToAdd = @(
    "C:\Python311\Scripts",
    "C:\Python311",
    "C:\Program Files\nodejs"
)

$machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
foreach ($p in $pathsToAdd) {
    if (-not ($machinePath.Split(';') -contains $p)) {
        $machinePath += ";$p"
        Log-Write "[+] Added $p to machine PATH."
    } else {
        Log-Write "[=] $p already in machine PATH."
    }
}

[Environment]::SetEnvironmentVariable("Path", $machinePath, "Machine")

Log-Write "=== Phase 2 Setup Complete ==="
