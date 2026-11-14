# Core feature inventory

This document describes the features included in the ShellOps core application. Optional integrations are maintained separately under `addons/`.

| Area | Current behavior | Dependencies / limitations |
|---|---|---|
| Dashboard | Displays local workstation, user, domain/workgroup, OS and PowerShell details | Local information only; not remote monitoring |
| Ping | Asynchronous ping, reply timing/address/TTL, packet count and continuous mode | Requires network reachability and permission for ICMP in the path |
| DNS lookup | Resolves a supplied host or address and displays returned records | Uses the workstation's configured DNS/resolver behavior |
| System information | Displays local system information | Local queries only |
| Network information | Displays local network adapter/address/gateway/DNS information | Local queries only |
| Dameware MRC | Launches a locally installed MRC executable; copies entered target to clipboard | Dameware must be installed in one of the checked standard paths |
| DHCP console | Hosts `dhcpmgmt.msc` in the Admin Consoles workspace | RSAT DHCP tools and suitable permissions required |
| Active Directory console | Hosts `dsa.msc` | AD DS / LDAP RSAT tools and suitable permissions required |
| Print Management console | Hosts `printmanagement.msc` | Print Management tools and suitable permissions required |

## Explicit non-goals in the core release

- No ticket creation, modification, assignment, closure or deletion.
- No ticketing-system connection or API calls.
- No VMware Horizon connection, VDI queries or Horizon placeholder UI.
- No automatic elevation.
- No remote monitoring agent or background inventory service.
- No automatic changes to DHCP, Active Directory or print infrastructure.
- No guarantee that arbitrary MMC snap-ins can be embedded on every Windows build.
