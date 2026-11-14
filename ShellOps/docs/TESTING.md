# Verification checklist

The ShellOps-branded build needs a Windows workstation verification pass before a public release. The original internal baseline was reported as tested, but the rebrand and public packaging still need to be rechecked.

## Environment record

Record these details with every test run:

- Windows edition, version and build.
- PowerShell version (`$PSVersionTable` output).
- Process architecture (`[Environment]::Is64BitProcess`).
- Installed RSAT / MMC components.
- Whether Dameware MRC is installed and its version.

## Launch and dashboard

- [ ] Launch `src\ShellOps.ps1` using PowerShell 7.2+ on Windows.
- [ ] Confirm the window title and header say ShellOps / Helpdesk Tools.
- [ ] Confirm dashboard fields populate and no previous-company or internal product labels remain.
- [ ] Confirm navigation contains only Dashboard, IT Utilities and Admin Consoles.
- [ ] Resize the main window and navigate between all pages.

## IT Utilities

- [ ] Run ping against a reachable host and an unreachable host.
- [ ] Verify reply address, time and TTL display.
- [ ] Verify packet count and continuous mode start/stop behavior.
- [ ] Verify late ping callbacks do not overwrite a later run's results.
- [ ] Run DNS lookup for a valid hostname and an invalid hostname.
- [ ] Verify System Info and Network Info output.
- [ ] Verify Copy Results and Clear.
- [ ] If Dameware is installed, open MRC with no target and with a target; verify target is copied to clipboard.

## Admin Consoles

For each installed console:

- [ ] Open DHCP (`dhcpmgmt.msc`).
- [ ] Open Active Directory Users and Computers (`dsa.msc`).
- [ ] Open Print Management (`printmanagement.msc`).
- [ ] Confirm the console is hosted in the ShellOps workspace.
- [ ] Switch between consoles and navigate away/back.
- [ ] Close ShellOps and confirm its launched MMC process is cleaned up as intended.
- [ ] Test on the Windows versions the project intends to support. MMC embedding is best-effort and may vary by snap-in/build.

## Core/add-on separation

- [ ] Launch the core when the `addons` directory is absent.
- [ ] Confirm the core makes no ServiceDesk or Horizon connections.
- [ ] Confirm no ServiceDesk or Horizon page, navigation entry, or placeholder is present.
- [ ] Confirm add-on modules are not imported or executed automatically.
- [ ] Test an add-on separately using its own documentation and test tenant.

## Public-source hygiene

- [ ] Search the entire repository for previous company/product names, internal hostnames, internal IPs, user names, tenant URLs, API keys and customer information.
- [ ] Confirm `.gitignore` excludes local settings, logs, credential exports and backups.
- [ ] Run the GitHub Actions static-analysis workflow.
- [ ] Select and add an open-source license before calling the repository open source.
