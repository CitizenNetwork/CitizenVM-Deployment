# CitizenVM Deployment Kit

### 🎮 Citizen Gaming Network • Secure Development Environment Installer

This repository contains a fully automated setup system for creating **isolated Windows development VMs** on any VirtualBox-compatible machine — designed for **Citizen Network developers, testers, and staff**.

It ensures a secure, repeatable, and beginner-friendly setup process for:
- Creating restricted local user accounts
- Hardening system permissions
- Installing essential dev tools
- Automatically provisioning a Windows VM with your product key

---

## 📁 What's Inside?

| File / Folder                | Description |
|-----------------------------|-------------|
| `setup_citizenDevs.ps1`     | Creates local user accounts, groups, and applies folder ACLs & security policies. |
| `step1_env_setup.ps1`       | Sets up environment variables, Git defaults, PowerShell profiles, and startup tasks. |
| `step2_tool_setup.ps1`      | Installs Chocolatey, Python, Node.js, and adds them to system PATH. |
| `Citizen_VM_Builder.ps1`    | Fully automates creating and configuring a Windows 10 VM using VirtualBox. |
| `windows_key.txt` (ignored) | **Store your Windows product key here.** This file is excluded from GitHub. |
| `.gitignore`                | Prevents sensitive files (like your product key) from being uploaded. |
| `README.md`                 | This file — an overview and guide. |

---

## ✅ Requirements

Before running any scripts, make sure your system has:

- **Windows 10/11 with Admin Access**
- [**PowerShell 5+**](https://docs.microsoft.com/en-us/powershell/)
- [**VirtualBox**](https://www.virtualbox.org/wiki/Downloads)
- A valid **Windows 10 ISO** in `C:\ISOs\Win10_22H2_English_x64.iso`
- A valid **Windows 10 Product Key** stored securely in:


If keyboard/mouse don't work inside the VM, install VirtualBox Guest Additions

Make sure VirtualBox is not open when running the scripts

Always run scripts as Administrator
