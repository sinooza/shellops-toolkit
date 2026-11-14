# Installation and first launch

## Supported environment

- Windows 10/11.
- PowerShell 7.2+ on Windows. Prefer a currently supported release.
- The .NET Windows Desktop Runtime matching the installed PowerShell runtime, so Windows Forms assemblies are available.
- A user account with the permissions needed for the specific console or support task.

This application uses Windows Forms and native Windows window APIs. It is not intended for Linux, macOS, PowerShell 5.1, or unattended server execution.

## Download

Clone the repository or download its source archive from GitHub. The core application is `src/ShellOps.ps1`; no add-on files are required to launch it.

## Launch

From the repository root in PowerShell 7:

```powershell
pwsh
Set-Location 'C:\path\to\ShellOps'
.\src\ShellOps.ps1
```

If your local execution policy blocks scripts, consult your administrator. For a temporary current-process test only, you can use:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

Do not change LocalMachine policy or disable endpoint protection to run ShellOps.

## Optional Windows components

Install only the management tools you need. Availability depends on the Windows edition and organization policy.

- DHCP Server Tools / RSAT DHCP tools for `dhcpmgmt.msc`.
- Active Directory Domain Services and Lightweight Directory Services Tools for `dsa.msc`.
- Print and Document Services tools for `printmanagement.msc`.
- Dameware Mini Remote Control for the MRC launcher.

ShellOps reports when an MMC file is missing. It does not install RSAT components or Dameware for you.

## Add-ons

Add-ons are optional and installed separately. Follow the README in each add-on directory. The core app does not load them automatically.
