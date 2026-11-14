# ShellOps — Helpdesk Tools

**ShellOps** is a Windows helpdesk and IT operations toolbox built with PowerShell and Windows Forms. The core release focuses on local workstation diagnostics, Windows administration consoles and a remote-support launcher. External integrations are kept out of the core application and may be installed separately as optional add-ons.

> **Public preview:** 0.1.1. The ShellOps-branded build has not yet been validated on a clean Windows workstation. Review the compatibility notes and manual test checklist before production use.

## Core features

- **Dashboard:** local workstation, signed-in user, domain/workgroup, operating-system and PowerShell information.
- **IT Utilities:** asynchronous ping with reply details including TTL, configurable packet count and continuous mode, DNS lookup, local system information, network information, output copy/clear, and a Dameware Mini Remote Control (MRC) launcher.
- **Admin Consoles:** embedded MMC workspaces for DHCP, Active Directory Users and Computers, and Print Management when the corresponding Windows tools are installed.

The core does not connect to ticketing systems, VDI brokers or remote management services. Network checks run only when the operator starts them. Administrative consoles use the current Windows user's permissions; ShellOps does not elevate privileges automatically.

## Requirements

- Windows 10 or Windows 11.
- PowerShell **7.2 or later**, running on Windows. A current supported PowerShell 7 release is recommended.
- The .NET Windows Desktop Runtime matching the installed PowerShell runtime, providing Windows Forms assemblies.
- Optional: SolarWinds Dameware Mini Remote Control installed locally for the MRC launcher.
- Optional: Windows RSAT / management components for the MMC consoles: DHCP management tools (`dhcpmgmt.msc`), Active Directory Users and Computers (`dsa.msc`), and Print Management (`printmanagement.msc`).

Windows PowerShell 5.1 is **not a supported runtime** for this release. The native MMC helper uses .NET APIs available in .NET 6 and later.

## Quick start

1. Download or clone this repository.
2. Open PowerShell 7 on Windows.
3. From the repository root, run:

   ```powershell
   .\src\ShellOps.ps1
   ```

Follow your organization's execution-policy rules; do not weaken machine-wide policy just to run this tool.

## Optional add-ons

Add-ons are separate from the core application. They are not imported or executed automatically by ShellOps, and installing one does not change the core navigation or grant it additional permissions. Review each add-on's own documentation, dependencies, network behavior and security model before using it.

### Available add-ons

- **ServiceDesk Plus:** an optional, standalone read-only API module. It is not loaded by the core application. See [the add-on guide](addons/servicedesk/README.md).
- **Horizon:** no Horizon add-on is included in this release. The previous placeholder page has been removed from the core; a future Horizon integration must be developed, reviewed and distributed as a separate add-on.

## Repository layout

```text
ShellOps/
├── .github/                 # Issue templates, PR template and CI workflow
├── addons/                  # Separately installed integrations
│   └── servicedesk/         # Optional standalone ServiceDesk module
├── docs/                    # Core installation, architecture and test docs
├── src/
│   └── ShellOps.ps1         # Core Windows Forms application
├── tests/                   # Test notes
├── .editorconfig
├── .gitignore
├── CHANGELOG.md
├── CODE_OF_CONDUCT.md
├── CONTRIBUTING.md
├── README.md
├── SECURITY.md
└── SUPPORT.md
```

## Safety and operational notes

- MMC consoles can make changes to infrastructure using the current user's permissions. ShellOps does not prevent changes made inside those Microsoft consoles.
- Embedded MMC hosting is best-effort window integration. If a snap-in fails to embed on a particular Windows build, report the Windows version, PowerShell version, snap-in name and sanitized error details.
- The MRC launcher checks common 32-bit and 64-bit installation paths. It opens MRC even when no target is entered; when a target is present, it copies the target to the clipboard for manual pasting.
- Add-ons are independent code. Do not install or import an add-on unless you have reviewed its source and trust its publisher.

## Testing status

The original internal baseline corresponding to this source was reported by its maintainer as tested across the existing toolkit functions, including the refreshed MMC helper. The ShellOps rebrand and public packaging still require workstation validation. See [TESTING.md](docs/TESTING.md) for the required verification pass.

## License

No open-source license has been selected yet. Until a license is added, all rights remain with the copyright holder and reuse, redistribution, and modification are not granted. See [LICENSING.md](docs/LICENSING.md).

## Contributing

Read [CONTRIBUTING.md](CONTRIBUTING.md) before opening an issue or pull request. Never include credentials, customer records, internal hostnames, private IP plans, or screenshots containing sensitive data.
