# ServiceDesk Plus add-on

This separately distributed add-on provides an optional, read-only integration for ManageEngine ServiceDesk Plus API v3. It is not required to use ShellOps core and does not integrate with its graphical interface.

## Configure the endpoint

Set `SHELLOPS_SERVICEDESK_BASE_URL` to the HTTPS API v3 base URL for your own ServiceDesk tenant before importing the add-on module:

```powershell
$env:SHELLOPS_SERVICEDESK_BASE_URL = 'https://your-servicedesk.example.com/api/v3'
Import-Module .\addons\servicedesk\ShellOps.ServiceDesk.psm1
```

The endpoint must be an absolute HTTPS URL and should include the correct API version path. The project intentionally contains no default tenant URL.

The variable above is process-scoped. It is inherited by the ShellOps process launched from that PowerShell session. To persist configuration, use your organization's approved environment-variable or endpoint-management method. Do not write a real tenant URL into tracked source files.

## API key handling

Use `Test-ShellOpsServiceDeskConnection` to validate a supplied API key with a read-only request before saving it with `Save-ShellOpsServiceDeskCredential`. The module stores the secure credential using `Export-Clixml` under:

```text
%LOCALAPPDATA%\ShellOps\servicedesk.cred
```

On Windows, the secure string is protected by DPAPI for the current Windows user and machine. Treat the file as sensitive anyway. Do not copy it into backups or source control unless your organization's security policy explicitly permits it.

## Permissions and behavior

- The current module uses HTTP GET requests for connection testing, request listing and request lookup.
- Use a dedicated API key with the minimum read permissions required.
- The module does not create, update, assign, close, or delete requests.
- Removing the locally stored credential does not revoke the API key on the ServiceDesk server. Revoke or rotate the key through the ServiceDesk administration interface if it is exposed.

## Troubleshooting

- **Integration not configured:** set `SHELLOPS_SERVICEDESK_BASE_URL` before calling an add-on command.
- **URL rejected:** use an absolute HTTPS URL and verify the `/api/v3` path for your tenant.
- **Authentication failure:** verify the API key and its read permissions; re-enter it through the credential manager.
- **Credential cannot be read:** re-save it as the same Windows user on the same machine. DPAPI-protected credentials are not portable.
- **HTTP errors:** inspect the sanitized status and response details. Remove API keys, requester details and ticket contents before sharing logs or screenshots.


## Separation from ShellOps core

This module is not imported by `src/ShellOps.ps1` and does not add a ServiceDesk page to the ShellOps interface. Import and use it explicitly as a standalone PowerShell module. The core application remains fully usable without this add-on.

## Basic standalone use

After importing the module and configuring the endpoint, the exported commands include:

- `Test-ShellOpsServiceDeskConnection`
- `Save-ShellOpsServiceDeskCredential`
- `Get-ShellOpsServiceDeskRequests`
- `Get-ShellOpsServiceDeskRequest`
- `Get-ShellOpsServiceDeskCredential`
- `Remove-ShellOpsServiceDeskCredential`

Example request listing (after saving a credential):

```powershell
Get-ShellOpsServiceDeskRequests -StartIndex 1 -RowCount 25
Get-ShellOpsServiceDeskRequest -RequestId '12345'
```

The module is a PowerShell add-on, not a graphical plugin. A future UI adapter would need to be designed and installed separately.
