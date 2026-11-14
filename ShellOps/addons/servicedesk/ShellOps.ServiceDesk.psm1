# ShellOps optional ServiceDesk Plus v3 read-only API module
# Credentials are stored as a PSCredential protected by Windows DPAPI for the current Windows user.

$script:ShellOpsServiceDeskBaseUrlEnvironmentVariable = "SHELLOPS_SERVICEDESK_BASE_URL"
$script:ShellOpsServiceDeskCredentialPath = Join-Path $env:LOCALAPPDATA "ShellOps\servicedesk.cred"

# ShellOps targets PowerShell 7.2+ on Windows. The endpoint is supplied by the user at runtime.

function Get-ShellOpsServiceDeskBaseUrl {
    $baseUrl = [Environment]::GetEnvironmentVariable($script:ShellOpsServiceDeskBaseUrlEnvironmentVariable, 'Process')
    if ([string]::IsNullOrWhiteSpace($baseUrl)) {
        throw "ServiceDesk integration is not configured. Set the $($script:ShellOpsServiceDeskBaseUrlEnvironmentVariable) environment variable to your ServiceDesk API v3 base URL (for example, https://servicedesk.example.com/api/v3)."
    }

    $baseUrl = $baseUrl.Trim().TrimEnd('/')
    $parsedUri = $null
    if (-not [Uri]::TryCreate($baseUrl, [UriKind]::Absolute, [ref]$parsedUri) -or $parsedUri.Scheme -ne 'https') {
        throw "The $($script:ShellOpsServiceDeskBaseUrlEnvironmentVariable) value must be an absolute HTTPS URL."
    }
    return $baseUrl
}

function Save-ShellOpsServiceDeskCredential {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Security.SecureString]$SecureKey
    )

    if ($null -eq $SecureKey -or $SecureKey.Length -eq 0) {
        throw "The API key was empty. No credential was saved."
    }

    $directory = Split-Path -Parent $script:ShellOpsServiceDeskCredentialPath
    if (-not (Test-Path -LiteralPath $directory)) {
        New-Item -ItemType Directory -Path $directory -Force -ErrorAction Stop | Out-Null
    }

    $credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @("ShellOps-ServiceDesk", $SecureKey)
    $credential | Export-Clixml -LiteralPath $script:ShellOpsServiceDeskCredentialPath -Force -ErrorAction Stop
    return $script:ShellOpsServiceDeskCredentialPath
}

function Remove-ShellOpsServiceDeskCredential {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param()

    if (-not (Test-Path -LiteralPath $script:ShellOpsServiceDeskCredentialPath)) {
        return $false
    }

    if ($PSCmdlet.ShouldProcess($script:ShellOpsServiceDeskCredentialPath, 'Delete saved ServiceDesk credential')) {
        Remove-Item -LiteralPath $script:ShellOpsServiceDeskCredentialPath -Force -ErrorAction Stop
        return $true
    }
    return $false
}

function Test-ShellOpsServiceDeskCredentialExists {
    [CmdletBinding()]
    param()
    return (Test-Path -LiteralPath $script:ShellOpsServiceDeskCredentialPath -PathType Leaf)
}

function Get-ShellOpsServiceDeskCredential {
    if (-not (Test-Path -LiteralPath $script:ShellOpsServiceDeskCredentialPath)) {
        throw "ServiceDesk credential not found. Run Save-ShellOpsServiceDeskCredential first. Expected path: $($script:ShellOpsServiceDeskCredentialPath)"
    }

    try {
        $credential = Import-Clixml -LiteralPath $script:ShellOpsServiceDeskCredentialPath -ErrorAction Stop
        if ($credential -isnot [System.Management.Automation.PSCredential]) {
            throw "Stored credential is not a PSCredential."
        }
        $key = $credential.GetNetworkCredential().Password
    }
    catch {
        throw "Could not read the saved ServiceDesk credential for this Windows user. Run Save-ShellOpsServiceDeskCredential again. $($_.Exception.Message)"
    }

    if ([string]::IsNullOrWhiteSpace($key)) { throw "The saved ServiceDesk API key is empty." }
    return $key
}

function Get-ShellOpsServiceDeskErrorResponse {
    param($ErrorRecord)

    # PowerShell 7 commonly exposes the response body through ErrorDetails.
    if ($ErrorRecord.ErrorDetails -and -not [string]::IsNullOrWhiteSpace($ErrorRecord.ErrorDetails.Message)) {
        return $ErrorRecord.ErrorDetails.Message
    }

    $response = $ErrorRecord.Exception.Response
    if ($null -eq $response) { return $null }

    # HttpResponseMessage (PowerShell 7 / newer HTTP stack).
    if ($response.Content -and $response.Content.PSObject.Methods['ReadAsStringAsync']) {
        try { return $response.Content.ReadAsStringAsync().GetAwaiter().GetResult() } catch {}
    }

    # WebResponse (Windows PowerShell 5.1 legacy HTTP stack).
    if ($response.PSObject.Methods['GetResponseStream']) {
        try {
            $stream = $response.GetResponseStream()
            if ($stream) {
                $reader = New-Object System.IO.StreamReader($stream)
                try { return $reader.ReadToEnd() }
                finally { $reader.Dispose() }
            }
        } catch {}
    }
    return $null
}

function Assert-ShellOpsServiceDeskResponse {
    param($Result, [string]$Operation)
    if ($null -eq $Result) { throw "ServiceDesk returned an empty response during $Operation." }
    $status = $null
    if ($Result.response_status) { $status = [string]$Result.response_status.status }
    if ($status -and $status -ne "success") {
        $code = $Result.response_status.status_code
        throw "ServiceDesk reported failure during $Operation (status: $status; code: $code)."
    }
}

function Invoke-ShellOpsServiceDeskGet {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path,
        [hashtable]$Query,
        [string]$ApiKey
    )

    $key = if (-not [string]::IsNullOrWhiteSpace($ApiKey)) { $ApiKey } else { Get-ShellOpsServiceDeskCredential }
    $headers = @{
        Accept = "application/vnd.manageengine.sdp.v3+json"
        authtoken = $key
    }

    $baseUrl = Get-ShellOpsServiceDeskBaseUrl
    $uri = "$baseUrl/$($Path.TrimStart('/'))"
    if ($Query -and $Query.Count -gt 0) {
        $pairs = foreach ($name in $Query.Keys) {
            "$([uri]::EscapeDataString([string]$name))=$([uri]::EscapeDataString([string]$Query[$name]))"
        }
        $uri += "?" + ($pairs -join "&")
    }

    try {
        return Invoke-RestMethod -Uri $uri -Method Get -Headers $headers -ErrorAction Stop
    }
    catch {
        $statusCode = $null
        try {
            if ($_.Exception.Response.StatusCode) { $statusCode = [int]$_.Exception.Response.StatusCode }
        } catch {}
        $body = Get-ShellOpsServiceDeskErrorResponse -ErrorRecord $_
        if ($statusCode) {
            if ($body) { throw "ServiceDesk API returned HTTP $statusCode. $body" }
            throw "ServiceDesk API returned HTTP $statusCode without a readable response body."
        }
        if ($body) { throw "ServiceDesk request failed. $body" }
        throw "ServiceDesk request failed: $($_.Exception.Message)"
    }
}

function Test-ShellOpsServiceDeskConnection {
    [CmdletBinding()]
    param([string]$ApiKey)

    # Test authentication and list access without depending on one hardcoded ticket ID.
    # When ApiKey is supplied, it is tested in memory and is not persisted.
    $result = Invoke-ShellOpsServiceDeskGet -Path "requests" -Query @{
        input_data = (@{ list_info = @{ start_index = 1; row_count = 1 } } | ConvertTo-Json -Depth 5 -Compress)
    } -ApiKey $ApiKey
    Assert-ShellOpsServiceDeskResponse -Result $result -Operation "connection test"
    if ($null -eq $result.PSObject.Properties['requests']) {
        throw "ServiceDesk responded, but the request-list payload was not present."
    }
    return $true
}

function Get-ShellOpsServiceDeskRequests {
    [CmdletBinding()]
    param(
        [ValidateRange(1, 100000)][int]$StartIndex = 1,
        [ValidateRange(1, 100)][int]$RowCount = 25
    )

    $inputData = @{
        list_info = @{
            start_index = $StartIndex
            row_count = $RowCount
        }
    } | ConvertTo-Json -Depth 5 -Compress

    $result = Invoke-ShellOpsServiceDeskGet -Path "requests" -Query @{ input_data = $inputData }
    Assert-ShellOpsServiceDeskResponse -Result $result -Operation "request listing"
    return $result
}

function Get-ShellOpsServiceDeskRequest {
    [CmdletBinding()]
    param([Parameter(Mandatory)][ValidatePattern('^\d+$')][string]$RequestId)

    $result = Invoke-ShellOpsServiceDeskGet -Path "requests/$RequestId"
    Assert-ShellOpsServiceDeskResponse -Result $result -Operation "request lookup"
    if ($null -eq $result.PSObject.Properties['request']) {
        throw "ServiceDesk returned no request object for ID $RequestId."
    }
    return $result
}

Export-ModuleMember -Function Save-ShellOpsServiceDeskCredential, Remove-ShellOpsServiceDeskCredential, Test-ShellOpsServiceDeskCredentialExists, Get-ShellOpsServiceDeskCredential, Test-ShellOpsServiceDeskConnection, Get-ShellOpsServiceDeskRequests, Get-ShellOpsServiceDeskRequest