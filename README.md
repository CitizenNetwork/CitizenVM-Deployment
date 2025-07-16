# CitizenVM-Deployment
A complete, automated VM deployment and developer onboarding system for the Citizen Gaming Network. This toolkit sets up secure development environments, builds Windows VMs with auto-activation and shared folders, and installs required tools for new employees or contributors — all with one-click scripts.

# CitizenGaming Dev VM Setup

## Overview

This repository contains PowerShell scripts to:

- Setup user groups and permissions for Citizen Gaming Network
- Configure dev environment with Git, Node, Python, Chocolatey, etc.
- Create and build a VirtualBox Windows 10 VM with unattended install

## Setup Instructions

1. Clone the repo.

2. Place your Windows ISO into the `ISOs` folder (not committed).

3. Create a `keys` folder and add your Windows product key in `windows_key.txt`.

4. Run the setup scripts in order from an elevated PowerShell prompt inside the `scripts` folder:

```powershell
.\setup_citizenDevs.ps1
.\citizen_env_phase1.ps1
.\citizen_env_phase2.ps1
.\citizen_vm_builder.ps1
