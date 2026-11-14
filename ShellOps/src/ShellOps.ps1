# ShellOps v0.1.1 — Helpdesk Tools
# Windows PowerShell 7.2+ desktop toolkit for helpdesk and IT operations.
# Review docs/TESTING.md before production use; the public rebrand requires workstation validation.

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Native Windows placeholder for the target field.
if (-not ("ShellOpsCueBanner" -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public static class ShellOpsCueBanner
{
    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    private static extern IntPtr SendMessage(
        IntPtr hWnd, int msg, IntPtr wParam, string lParam);

    public static void SetCueBanner(IntPtr hWnd, string text)
    {
        SendMessage(hWnd, 0x1501, new IntPtr(1), text);
    }
}
'@
}

# Native window helpers used to host MMC inside the ShellOps workspace.
if (-not ("ShellOpsNativeWindow" -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public static class ShellOpsNativeWindow
{
    public const int GWL_STYLE = -16;
    public const long WS_CHILD = 0x40000000L;
    public const long WS_POPUP = unchecked((long)0x80000000L);
    public const long WS_CAPTION = 0x00C00000L;
    public const long WS_THICKFRAME = 0x00040000L;
    public const long WS_SYSMENU = 0x00080000L;
    public const long WS_MINIMIZEBOX = 0x00020000L;
    public const long WS_MAXIMIZEBOX = 0x00010000L;
    public const uint SWP_NOZORDER = 0x0004;
    public const uint SWP_NOACTIVATE = 0x0010;
    public const uint SWP_FRAMECHANGED = 0x0020;
    public const int SW_SHOW = 5;

    private delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

    [DllImport("user32.dll", SetLastError=true)]
    private static extern bool EnumWindows(EnumWindowsProc callback, IntPtr lParam);
    [DllImport("user32.dll", SetLastError=true)]
    private static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint processId);
    [DllImport("user32.dll")]
    public static extern bool IsWindowVisible(IntPtr hWnd);
    [DllImport("user32.dll")]
    public static extern IntPtr GetParent(IntPtr hWnd);
    [DllImport("user32.dll", SetLastError=true)]
    private static extern IntPtr SetParent(IntPtr hWndChild, IntPtr hWndNewParent);

    public static IntPtr SetParentChecked(IntPtr child, IntPtr parent, out int error)
    {
        // Clear the cached last P/Invoke error so a successful SetParent call
        // is not misreported because of an unrelated earlier Windows API call.
        Marshal.SetLastPInvokeError(0);
        IntPtr previousParent = SetParent(child, parent);
        error = Marshal.GetLastWin32Error();
        return previousParent;
    }

    public static IntPtr FindTopLevelWindowForProcess(int targetProcessId)
    {
        IntPtr found = IntPtr.Zero;
        EnumWindows(delegate(IntPtr hWnd, IntPtr lParam) {
            uint processId;
            GetWindowThreadProcessId(hWnd, out processId);
            if (processId == (uint)targetProcessId && IsWindowVisible(hWnd) && GetParent(hWnd) == IntPtr.Zero) {
                found = hWnd;
                return false;
            }
            return true;
        }, IntPtr.Zero);
        return found;
    }

    [DllImport("user32.dll", SetLastError=true)]
    public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter,
        int X, int Y, int cx, int cy, uint uFlags);
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll", EntryPoint="GetWindowLongPtrW", SetLastError=true)]
    private static extern IntPtr GetWindowLongPtr64(IntPtr hWnd, int nIndex);
    [DllImport("user32.dll", EntryPoint="GetWindowLongW", SetLastError=true)]
    private static extern IntPtr GetWindowLong32(IntPtr hWnd, int nIndex);
    [DllImport("user32.dll", EntryPoint="SetWindowLongPtrW", SetLastError=true)]
    private static extern IntPtr SetWindowLongPtr64(IntPtr hWnd, int nIndex, IntPtr dwNewLong);
    [DllImport("user32.dll", EntryPoint="SetWindowLongW", SetLastError=true)]
    private static extern IntPtr SetWindowLong32(IntPtr hWnd, int nIndex, IntPtr dwNewLong);

    public static long GetStyle(IntPtr hWnd) {
        return IntPtr.Size == 8 ? GetWindowLongPtr64(hWnd, GWL_STYLE).ToInt64()
                                : GetWindowLong32(hWnd, GWL_STYLE).ToInt64();
    }
    public static void SetStyle(IntPtr hWnd, long style) {
        IntPtr value = new IntPtr(style);
        if (IntPtr.Size == 8) SetWindowLongPtr64(hWnd, GWL_STYLE, value);
        else SetWindowLong32(hWnd, GWL_STYLE, value);
    }
}
'@
}

[System.Windows.Forms.Application]::EnableVisualStyles()

# Main window
$form = New-Object System.Windows.Forms.Form
$form.Text = "ShellOps Toolkit"
$form.Size = New-Object System.Drawing.Size(1120, 740)
$form.MinimumSize = New-Object System.Drawing.Size(920, 620)
$form.StartPosition = "CenterScreen"
$form.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Dpi
$form.BackColor = [System.Drawing.Color]::FromArgb(243, 246, 250)
$form.Font = New-Object System.Drawing.Font("Segoe UI", 10)

# Header
$header = New-Object System.Windows.Forms.Panel
$header.Dock = "Top"
$header.Height = 78
$header.BackColor = [System.Drawing.Color]::FromArgb(23, 34, 53)
$form.Controls.Add($header)

$title = New-Object System.Windows.Forms.Label
$title.Text = "ShellOps Toolkit"
$title.ForeColor = [System.Drawing.Color]::White
$title.Font = New-Object System.Drawing.Font(
    "Segoe UI Semibold", 18, [System.Drawing.FontStyle]::Bold)
$title.Location = New-Object System.Drawing.Point(26, 12)
$title.AutoSize = $true
$header.Controls.Add($title)

$subtitle = New-Object System.Windows.Forms.Label
$subtitle.Text = "IT OPERATIONS WORKSPACE  |  Version 0.1.0  |  LOCAL TOOLS + OPTIONAL ADD-ONS"
$subtitle.ForeColor = [System.Drawing.Color]::FromArgb(190, 205, 220)
$subtitle.Location = New-Object System.Drawing.Point(29, 48)
$subtitle.AutoSize = $true
$header.Controls.Add($subtitle)

# Navigation panel
$nav = New-Object System.Windows.Forms.Panel
$nav.Dock = "Left"
$nav.Width = 205
$nav.BackColor = [System.Drawing.Color]::FromArgb(23, 34, 53)
$form.Controls.Add($nav)

# Main content panel
$content = New-Object System.Windows.Forms.Panel
$content.Dock = "Fill"
$content.Padding = New-Object System.Windows.Forms.Padding(28, 24, 28, 20)
$form.Controls.Add($content)
$form.Controls.SetChildIndex($content, 0)

$heading = New-Object System.Windows.Forms.Label
$heading.Text = "Dashboard"
$heading.Font = New-Object System.Drawing.Font(
    "Segoe UI Semibold", 21, [System.Drawing.FontStyle]::Bold)
$heading.Location = New-Object System.Drawing.Point(28, 22)
$heading.AutoSize = $true
$content.Controls.Add($heading)

$description = New-Object System.Windows.Forms.Label
$description.Text = "Your local helpdesk toolbox. One useful feature at a time."
$description.Location = New-Object System.Drawing.Point(31, 66)
$description.AutoSize = $true
$content.Controls.Add($description)

# IT Utilities workspace
$utilityPanel = New-Object System.Windows.Forms.Panel
$utilityPanel.Location = New-Object System.Drawing.Point(24, 110)
$utilityPanel.Size = New-Object System.Drawing.Size(620, 370)
$utilityPanel.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor
    [System.Windows.Forms.AnchorStyles]::Bottom -bor
    [System.Windows.Forms.AnchorStyles]::Left -bor
    [System.Windows.Forms.AnchorStyles]::Right
$utilityPanel.Visible = $false
$content.Controls.Add($utilityPanel)

# Shared hostname/IP field
$pingInput = New-Object System.Windows.Forms.TextBox
$pingInput.Location = New-Object System.Drawing.Point(0, 0)
$pingInput.Size = New-Object System.Drawing.Size(220, 30)
$pingInput.Text = ""
$utilityPanel.Controls.Add($pingInput)

$form.Add_Shown({
    [ShellOpsCueBanner]::SetCueBanner(
        $pingInput.Handle, "Enter hostname or IP")
})

# Ping button
$pingButton = New-Object System.Windows.Forms.Button
$pingButton.Text = "Ping"
$pingButton.Location = New-Object System.Drawing.Point(230, 0)
$pingButton.Size = New-Object System.Drawing.Size(70, 32)
$utilityPanel.Controls.Add($pingButton)

# DNS Lookup button
$dnsButton = New-Object System.Windows.Forms.Button
$dnsButton.Text = "DNS Lookup"
$dnsButton.Location = New-Object System.Drawing.Point(310, 0)
$dnsButton.Size = New-Object System.Drawing.Size(90, 32)
$utilityPanel.Controls.Add($dnsButton)

# Dameware MRC launcher
$mrcButton = New-Object System.Windows.Forms.Button
$mrcButton.Text = "Open MRC"
$mrcButton.Location = New-Object System.Drawing.Point(410, 0)
$mrcButton.Size = New-Object System.Drawing.Size(75, 32)
$utilityPanel.Controls.Add($mrcButton)

# Copy Results button
$copyButton = New-Object System.Windows.Forms.Button
$copyButton.Text = "Copy Results"
$copyButton.Location = New-Object System.Drawing.Point(495, 0)
$copyButton.Size = New-Object System.Drawing.Size(115, 32)
$utilityPanel.Controls.Add($copyButton)

# Secondary local-machine information actions
$clearButton = New-Object System.Windows.Forms.Button
$clearButton.Text = "Clear"
$clearButton.Location = New-Object System.Drawing.Point(196, 328)
$clearButton.Size = New-Object System.Drawing.Size(120, 32)
$clearButton.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor
    [System.Windows.Forms.AnchorStyles]::Right
$utilityPanel.Controls.Add($clearButton)

$systemButton = New-Object System.Windows.Forms.Button
$systemButton.Text = "System Info"
$systemButton.Location = New-Object System.Drawing.Point(330, 328)
$systemButton.Size = New-Object System.Drawing.Size(130, 32)
$systemButton.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor
    [System.Windows.Forms.AnchorStyles]::Right
$utilityPanel.Controls.Add($systemButton)

$networkButton = New-Object System.Windows.Forms.Button
$networkButton.Text = "Network Info"
$networkButton.Location = New-Object System.Drawing.Point(470, 328)
$networkButton.Size = New-Object System.Drawing.Size(140, 32)
$networkButton.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor
    [System.Windows.Forms.AnchorStyles]::Right
$utilityPanel.Controls.Add($networkButton)

# Results area
$outputBox = New-Object System.Windows.Forms.TextBox
$outputBox.Location = New-Object System.Drawing.Point(0, 124)
$outputBox.Size = New-Object System.Drawing.Size(600, 190)
$outputBox.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor
    [System.Windows.Forms.AnchorStyles]::Bottom -bor
    [System.Windows.Forms.AnchorStyles]::Left -bor
    [System.Windows.Forms.AnchorStyles]::Right
$outputBox.Multiline = $true
$outputBox.ReadOnly = $true
$outputBox.ScrollBars = "Vertical"
$outputBox.WordWrap = $false
$outputBox.Font = New-Object System.Drawing.Font("Consolas", 10)
$utilityPanel.Controls.Add($outputBox)

# Status display
$status = New-Object System.Windows.Forms.Label
$status.Text = "Ready | Local mode"
$status.Dock = "Bottom"
$status.Height = 28
$status.TextAlign = "MiddleLeft"
$status.Padding = New-Object System.Windows.Forms.Padding(10, 0, 0, 0)
$status.BackColor = [System.Drawing.Color]::FromArgb(220, 226, 234)
$form.Controls.Add($status)

# Dashboard workspace. All displayed values are read locally; no remote monitoring is implied.
$dashboardPanel = New-Object System.Windows.Forms.Panel
$dashboardPanel.Location = New-Object System.Drawing.Point(24, 108)
$dashboardPanel.Size = New-Object System.Drawing.Size(700, 470)
$dashboardPanel.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor
    [System.Windows.Forms.AnchorStyles]::Bottom -bor
    [System.Windows.Forms.AnchorStyles]::Left -bor
    [System.Windows.Forms.AnchorStyles]::Right
$dashboardPanel.BackColor = [System.Drawing.Color]::Transparent
$content.Controls.Add($dashboardPanel)

function New-DashboardCard {
    param([string]$Title, [string]$Value, [int]$X, [int]$Y, [int]$Width, [int]$Height = 112)
    $card = New-Object System.Windows.Forms.Panel
    $card.Location = New-Object System.Drawing.Point($X, $Y)
    $card.Size = New-Object System.Drawing.Size($Width, $Height)
    $card.BackColor = [System.Drawing.Color]::White
    $card.Tag = [int]($X / 286)
    $card.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle

    $cap = New-Object System.Windows.Forms.Label
    $cap.Text = $Title.ToUpperInvariant()
    $cap.Location = New-Object System.Drawing.Point(16, 13)
    $cap.AutoSize = $true
    $cap.ForeColor = [System.Drawing.Color]::FromArgb(105, 119, 139)
    $cap.Font = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Bold)
    $card.Controls.Add($cap)

    $val = New-Object System.Windows.Forms.Label
    $val.Text = $Value
    $val.Location = New-Object System.Drawing.Point(16, 43)
    $val.Size = New-Object System.Drawing.Size(($Width - 32), 48)
    $val.AutoEllipsis = $true
    $val.ForeColor = [System.Drawing.Color]::FromArgb(31, 45, 66)
    $val.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 15, [System.Drawing.FontStyle]::Bold)
    $card.Controls.Add($val)
    $dashboardPanel.Controls.Add($card)
    return $val
}

[void](New-DashboardCard -Title "Workstation" -Value $env:COMPUTERNAME -X 0 -Y 0 -Width 270)
[void](New-DashboardCard -Title "Signed-in user" -Value $env:USERNAME -X 286 -Y 0 -Width 270)
[void](New-DashboardCard -Title "Domain / Workgroup" -Value ($env:USERDOMAIN) -X 572 -Y 0 -Width 270)
$dashOsValue = New-DashboardCard -Title "Operating system" -Value "Loading local system details..." -X 0 -Y 128 -Width 420
$dashPowerShellValue = New-DashboardCard -Title "PowerShell" -Value ($PSVersionTable.PSVersion.ToString()) -X 436 -Y 128 -Width 220

$quickLabel = New-Object System.Windows.Forms.Label
$quickLabel.Text = "QUICK ACCESS"
$quickLabel.Location = New-Object System.Drawing.Point(2, 270)
$quickLabel.AutoSize = $true
$quickLabel.ForeColor = [System.Drawing.Color]::FromArgb(90, 106, 128)
$quickLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$dashboardPanel.Controls.Add($quickLabel)

$dashUtilityButton = New-Object System.Windows.Forms.Button
$dashUtilityButton.Text = "Open IT Utilities"
$dashUtilityButton.Location = New-Object System.Drawing.Point(0, 300)
$dashUtilityButton.Size = New-Object System.Drawing.Size(190, 42)
$dashboardPanel.Controls.Add($dashUtilityButton)

$dashAdminButton = New-Object System.Windows.Forms.Button
$dashAdminButton.Text = "Open Admin Consoles"
$dashAdminButton.Location = New-Object System.Drawing.Point(202, 300)
$dashAdminButton.Size = New-Object System.Drawing.Size(205, 42)
$dashboardPanel.Controls.Add($dashAdminButton)

$dashboardNote = New-Object System.Windows.Forms.Label
$dashboardNote.Text = "Local workspace ready. Remote actions are only performed when you launch a specific tool."
$dashboardNote.Location = New-Object System.Drawing.Point(2, 365)
$dashboardNote.Size = New-Object System.Drawing.Size(760, 36)
$dashboardNote.ForeColor = [System.Drawing.Color]::FromArgb(105, 119, 139)
$dashboardPanel.Controls.Add($dashboardNote)

try {
    $localOS = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
    $dashOsValue.Text = $localOS.Caption
} catch {
    $dashOsValue.Text = "Unavailable"
}

# Shared Active Target Profile. This is local UI state only; it does not connect to targets.
$script:targetProfile = @{
    OriginalTarget = ""
    Addresses = @()
    DnsStatus = "Not resolved"
    PingStatus = "Not tested"
}

$targetProfileLabel = New-Object System.Windows.Forms.Label
$targetProfileLabel.Location = New-Object System.Drawing.Point(0, 78)
$targetProfileLabel.Size = New-Object System.Drawing.Size(600, 20)
$targetProfileLabel.AutoEllipsis = $true
$targetProfileLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$targetProfileLabel.Text = "TARGET: No target selected"
$utilityPanel.Controls.Add($targetProfileLabel)

$targetDetailsLabel = New-Object System.Windows.Forms.Label
$targetDetailsLabel.Location = New-Object System.Drawing.Point(0, 99)
$targetDetailsLabel.Size = New-Object System.Drawing.Size(600, 20)
$targetDetailsLabel.AutoEllipsis = $true
$targetDetailsLabel.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$targetDetailsLabel.Text = "DNS: Not resolved | Addresses: none | Ping: Not tested"
$utilityPanel.Controls.Add($targetDetailsLabel)

function Update-TargetProfile {
    $profileTarget = $script:targetProfile.OriginalTarget
    if ([string]::IsNullOrWhiteSpace($profileTarget)) {
        $profileTarget = "No target selected"
    }

    $addressText = if ($script:targetProfile.Addresses -and $script:targetProfile.Addresses.Count -gt 0) {
        $script:targetProfile.Addresses -join ", "
    } else {
        "none"
    }

    $targetProfileLabel.Text = "TARGET: $profileTarget"
    $targetDetailsLabel.Text = "DNS: $($script:targetProfile.DnsStatus) | Addresses: $addressText | Ping: $($script:targetProfile.PingStatus)"
}

# Changing the target resets results belonging to the previous target.
$pingInput.Add_TextChanged({
    $script:targetProfile.OriginalTarget = $pingInput.Text.Trim()
    $script:targetProfile.Addresses = @()
    $script:targetProfile.DnsStatus = "Not resolved"
    $script:targetProfile.PingStatus = "Not tested"
    Update-TargetProfile
})

# Open MRC normally.
# Copy the target first if one is present.
# An empty target does not prevent MRC from opening.
$mrcButton.Add_Click({
    $mrcCandidates = @(
        "C:\Program Files (x86)\SolarWinds\Dameware Remote Support\DWRCC.exe",
        "C:\Program Files\SolarWinds\Dameware Remote Support\DWRCC.exe"
    )
    $mrcPath = $mrcCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
    $target = $pingInput.Text.Trim()
    $targetCopied = $false

    if (-not $mrcPath) {
        $status.Text = "Dameware MRC executable not found."

        [System.Windows.Forms.MessageBox]::Show(
            ("Could not find Dameware MRC in either of:`r`n" + ($mrcCandidates -join "`r`n")),
            "ShellOps Toolkit",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null

        return
    }

    if (-not [string]::IsNullOrWhiteSpace($target)) {
        try {
            [System.Windows.Forms.Clipboard]::SetText($target)
            $targetCopied = $true
        }
        catch {
            $status.Text = "Clipboard unavailable. Opening MRC anyway."
        }
    }

    try {
        # No host arguments, passwords, or automatic connection switches.
        Start-Process -FilePath $mrcPath -ErrorAction Stop

        if ([string]::IsNullOrWhiteSpace($target)) {
            $status.Text = "MRC opened. No target entered."
        }
        elseif ($targetCopied) {
            $status.Text = "Target copied. Paste into MRC."
        }
        else {
            $status.Text = "MRC opened, but copying the target failed."
        }
    }
    catch {
        $status.Text = "Failed to open MRC: $($_.Exception.Message)"
    }
})

# Copy output to clipboard
$copyButton.Add_Click({
    if ([string]::IsNullOrWhiteSpace($outputBox.Text)) {
        $status.Text = "Nothing to copy."
        return
    }

    try {
        [System.Windows.Forms.Clipboard]::SetText($outputBox.Text)
        $status.Text = "Results copied to clipboard."
    }
    catch {
        $status.Text = "Copy failed: $($_.Exception.Message)"
    }
})

# Clear output area
$clearButton.Add_Click({
    $outputBox.Clear()
    $status.Text = "Output cleared."
})

# System information
$systemButton.Add_Click({
    try {
        $osName = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop |
            Select-Object -ExpandProperty Caption

        $outputBox.Text = @(
            "SYSTEM INFORMATION"
            "=================="
            "Computer: $env:COMPUTERNAME"
            "User: $env:USERNAME"
            "PowerShell: $($PSVersionTable.PSVersion)"
            ""
            $osName
        ) -join "`r`n"

        $status.Text = "System information loaded."
    }
    catch {
        $outputBox.Text = "System query failed:`r`n$($_.Exception.Message)"
        $status.Text = "System query failed."
    }
})

# Network information
$networkButton.Add_Click({
    try {
        $configs = Get-NetIPConfiguration -ErrorAction Stop |
            Where-Object { $_.IPv4Address }

        $lines = @("NETWORK INFORMATION", "===================")

        foreach ($config in $configs) {
            $lines += ""
            $lines += "Adapter: $($config.InterfaceAlias)"

            $ips = $config.IPv4Address |
                ForEach-Object { $_.IPAddress }
            $lines += "IPv4 Address: $($ips -join ', ')"

            $gateways = $config.IPv4DefaultGateway |
                ForEach-Object { $_.NextHop }

            $lines += "Default Gateway: $(if ($gateways) {
                $gateways -join ', '
            } else {
                'None'
            })"

            $dns = Get-DnsClientServerAddress `
                -InterfaceIndex $config.InterfaceIndex `
                -AddressFamily IPv4 `
                -ErrorAction SilentlyContinue

            $dnsIPs = $dns.ServerAddresses
            $lines += "DNS Servers: $(if ($dnsIPs) {
                $dnsIPs -join ', '
            } else {
                'None listed'
            })"
        }

        $outputBox.Text = $lines -join "`r`n"
        $status.Text = "Network information loaded."
    }
    catch {
        $outputBox.Text = "Network query failed:`r`n$($_.Exception.Message)"
        $status.Text = "Network query failed."
    }
})

# DNS lookup
$dnsButton.Add_Click({
    $target = $pingInput.Text.Trim()

    if ([string]::IsNullOrWhiteSpace($target)) {
        $outputBox.Text = "Enter a hostname or IP address first."
        $status.Text = "DNS lookup cancelled: no target entered."
        return
    }

    $script:targetProfile.OriginalTarget = $target
    $script:targetProfile.DnsStatus = "Resolving..."
    Update-TargetProfile

    $parsedIP = $null
    $isIP = [System.Net.IPAddress]::TryParse(
        $target, [ref]$parsedIP)

    $lookupType = if ($isIP) {
        "Reverse lookup (PTR)"
    } else {
        "Forward lookup"
    }

    try {
        $entry = [System.Net.Dns]::GetHostEntry($target)

        $lines = @(
            "DNS LOOKUP"
            "==========="
            "Target: $target"
            "Lookup type: $lookupType"
            "Resolved name: $($entry.HostName)"
        )

        if ($entry.Aliases -and $entry.Aliases.Count -gt 0) {
            $lines += "Aliases: $($entry.Aliases -join ', ')"
        }

        $addresses = @(
            $entry.AddressList |
                ForEach-Object { $_.IPAddressToString } |
                Sort-Object -Unique
        )

        $script:targetProfile.OriginalTarget = $target
        $script:targetProfile.Addresses = @($addresses)
        $script:targetProfile.DnsStatus = "Resolved"
        Update-TargetProfile

        $lines += ""
        $lines += "Resolved addresses:"

        if ($addresses.Count -gt 0) {
            foreach ($address in $addresses) {
                $lines += "  $address"
            }
        }
        else {
            $lines += "  No addresses returned."
        }

        $outputBox.Text = $lines -join "`r`n"
        $status.Text = "DNS lookup completed for $target."
    }
    catch {
        $message = $_.Exception.GetBaseException().Message
        $script:targetProfile.OriginalTarget = $target
        $script:targetProfile.DnsStatus = "Failed"
        $script:targetProfile.Addresses = @()
        Update-TargetProfile

        $outputBox.Text = @(
            "DNS LOOKUP"
            "==========="
            "Target: $target"
            "Lookup type: $lookupType"
            ""
            "Lookup failed: $message"
        ) -join "`r`n"

        $status.Text = "DNS lookup failed for $target."
    }
})

# Shared ping state.
# Each Ping object belongs to one run.
$script:pingState = @{
    Active = $false
    Continuous = $false
    StopRequested = $false
    Cancelled = $false
    InFlight = $false
    Target = ""
    Requested = 0
    Sent = 0
    Received = 0
    TotalTime = 0L
    TimeCount = 0
    PendingLines = New-Object 'System.Collections.Generic.Queue[string]'
    SyncRoot = New-Object object
    PingObject = $null
}

# Ping completion callback.
# Updates state only; UI updates happen on the UI thread.
$script:pingCompletedHandler =
    [System.Net.NetworkInformation.PingCompletedEventHandler]{
    param($sourceControl, $asyncEventArgs)

    $state = $script:pingState

    # Ignore late callbacks from an earlier Ping object.
    if ($null -eq $state -or
        $null -eq $state.PingObject -or
        -not [object]::ReferenceEquals($state.PingObject, $sourceControl)) {
        return
    }

    [System.Threading.Monitor]::Enter($state.SyncRoot)
    try {
        $state.InFlight = $false

        if ($asyncEventArgs.Cancelled) {
            $state.Cancelled = $true
        }
        elseif ($asyncEventArgs.Error) {
            $state.PendingLines.Enqueue(
                "Ping error: $($asyncEventArgs.Error.Message)")
        }
        elseif ($asyncEventArgs.Reply -and
            $asyncEventArgs.Reply.Status -eq 'Success') {

            $reply = $asyncEventArgs.Reply
            $state.Received++

            $time = [int]$reply.RoundtripTime
            $ttl = if ($reply.Options) {
                $reply.Options.Ttl
            } else {
                'n/a'
            }

            $state.TotalTime += $time
            $state.TimeCount++

            $state.PendingLines.Enqueue(
                "Reply from $($reply.Address): time=${time}ms TTL=$ttl")
        }
        else {
            $replyStatus = if ($asyncEventArgs.Reply) {
                $asyncEventArgs.Reply.Status
            } else {
                'No reply'
            }

            $state.PendingLines.Enqueue(
                "Request failed: $replyStatus")
        }
    }
    finally {
        [System.Threading.Monitor]::Exit($state.SyncRoot)
    }
}

# Ping summary
function Write-PingSummary {
    param(
        [Parameter(Mandatory = $true)] $State,
        [Parameter(Mandatory = $true)]
        [ValidateSet('stopped', 'complete')]
        [string] $Verb
    )

    $lost = $State.Sent - $State.Received

    $loss = if ($State.Sent -gt 0) {
        [math]::Round(($lost / $State.Sent) * 100, 1)
    } else {
        0
    }

    $outputBox.AppendText("`r`nPING STATISTICS`r`n")
    $outputBox.AppendText(
        "Sent = $($State.Sent), Received = $($State.Received), " +
        "Lost = $lost ($loss% loss)`r`n")

    if ($State.TimeCount -gt 0) {
        $average = [math]::Round(
            ($State.TotalTime / $State.TimeCount), 2)

        $outputBox.AppendText(
            "Average response time = ${average}ms`r`n")
    }

    $outputBox.AppendText(
        "RESULT: $(if ($State.Received -gt 0) {
            'RESPONDING'
        } else {
            'NO REPLIES'
        })`r`n")

    $resultLabel = if ($State.Received -gt 0) { "RESPONDING" } else { "NO REPLIES" }
    $script:targetProfile.OriginalTarget = $State.Target
    $script:targetProfile.PingStatus = "$resultLabel ($($State.Received)/$($State.Sent))"
    Update-TargetProfile

    $status.Text = "Ping ${Verb}: $($State.Received)/$($State.Sent) replies received."
}

# Packet count
$countLabel = New-Object System.Windows.Forms.Label
$countLabel.Text = "Packets:"
$countLabel.Location = New-Object System.Drawing.Point(0, 51)
$countLabel.Size = New-Object System.Drawing.Size(65, 25)
$countLabel.TextAlign = "MiddleLeft"
$utilityPanel.Controls.Add($countLabel)

$countInput = New-Object System.Windows.Forms.NumericUpDown
$countInput.Location = New-Object System.Drawing.Point(70, 49)
$countInput.Size = New-Object System.Drawing.Size(70, 28)
$countInput.Minimum = 1
$countInput.Maximum = 100
$countInput.Value = 4
$utilityPanel.Controls.Add($countInput)

# Continuous ping toggle
$continuousCheck = New-Object System.Windows.Forms.CheckBox
$continuousCheck.Text = "Continuous"
$continuousCheck.Location = New-Object System.Drawing.Point(155, 49)
$continuousCheck.Size = New-Object System.Drawing.Size(115, 28)
$continuousCheck.Checked = $false
$utilityPanel.Controls.Add($continuousCheck)

$continuousCheck.Add_CheckedChanged({
    $countInput.Enabled = -not $continuousCheck.Checked

    # Unchecking Continuous requests a clean stop.
    if (-not $continuousCheck.Checked -and
        $script:pingState.Active -and
        $script:pingState.Continuous) {

        $script:pingState.StopRequested = $true
        $status.Text = "Stopping continuous ping..."

        if ($script:pingState.PingObject) {
            try {
                $script:pingState.PingObject.SendAsyncCancel()
            } catch {}
        }
    }
})

# Ping UI timer
$pingTimer = New-Object System.Windows.Forms.Timer
$pingTimer.Interval = 1000

$pingTimer.Add_Tick({
    $state = $script:pingState
    $newLines = @()
    $inFlight = $false
    $cancelled = $false

    [System.Threading.Monitor]::Enter($state.SyncRoot)
    try {
        while ($state.PendingLines.Count -gt 0) {
            $newLines += $state.PendingLines.Dequeue()
        }

        $inFlight = $state.InFlight
        $cancelled = $state.Cancelled
    }
    finally {
        [System.Threading.Monitor]::Exit($state.SyncRoot)
    }

    foreach ($line in $newLines) {
        $outputBox.AppendText($line + "`r`n")
    }

    # Bound visible output during continuous runs.
    if ($outputBox.Lines.Count -gt 500) {
        $outputBox.Lines = @(
            $outputBox.Lines | Select-Object -Last 500)
    }

    $outputBox.SelectionStart = $outputBox.TextLength
    $outputBox.ScrollToCaret()

    if (-not $state.Active) {
        $pingTimer.Stop()
        return
    }

    # Finish a requested stop after the outstanding request completes.
    if (($state.StopRequested -or $cancelled) -and -not $inFlight) {
        $pingTimer.Stop()
        $state.Active = $false
        $state.StopRequested = $false
        $state.Cancelled = $false
        $pingButton.Text = "Ping"

        Write-PingSummary -State $state -Verb "stopped"

        if ($state.PingObject) {
            try { $state.PingObject.Dispose() } catch {}
        }

        $state.PingObject = $null
        return
    }

    # Start the next request when the previous one is finished.
    if (-not $inFlight -and
        -not $state.StopRequested -and
        ($state.Continuous -or $state.Sent -lt $state.Requested)) {

        try {
            [System.Threading.Monitor]::Enter($state.SyncRoot)
            try {
                $state.Sent++
                $sequence = $state.Sent
                $state.InFlight = $true
            }
            finally {
                [System.Threading.Monitor]::Exit($state.SyncRoot)
            }

            $state.PingObject.SendAsync($state.Target, $sequence)
        }
        catch {
            [System.Threading.Monitor]::Enter($state.SyncRoot)
            try {
                $state.InFlight = $false
                $state.PendingLines.Enqueue(
                    "Ping error: $($_.Exception.Message)")
                $state.StopRequested = $true
            }
            finally {
                [System.Threading.Monitor]::Exit($state.SyncRoot)
            }
        }
    }
    elseif (-not $inFlight -and
        -not $state.Continuous -and
        $state.Sent -ge $state.Requested) {

        $pingTimer.Stop()
        $state.Active = $false
        $pingButton.Text = "Ping"

        Write-PingSummary -State $state -Verb "complete"

        if ($state.PingObject) {
            try { $state.PingObject.Dispose() } catch {}
        }

        $state.PingObject = $null
    }
    else {
        $status.Text = "Pinging $($state.Target): $($state.Received) replies received."
    }
})

# Ping button: starts a run or requests a stop.
$pingButton.Add_Click({
    $state = $script:pingState

    if ($state.Active) {
        $state.StopRequested = $true
        $status.Text = "Stopping ping..."

        if ($state.PingObject) {
            try { $state.PingObject.SendAsyncCancel() } catch {}
        }

        return
    }

    $target = $pingInput.Text.Trim()

    if ([string]::IsNullOrWhiteSpace($target)) {
        $outputBox.Text = "Enter a hostname or IP address first."
        $status.Text = "Ping cancelled: no target entered."
        return
    }

    $continuous = $continuousCheck.Checked
    $packetCount = if ($continuous) {
        0
    } else {
        [int]$countInput.Value
    }

    $state = @{
        Active = $true
        Continuous = $continuous
        StopRequested = $false
        Cancelled = $false
        InFlight = $false
        Target = $target
        Requested = $packetCount
        Sent = 0
        Received = 0
        TotalTime = 0L
        TimeCount = 0
        PendingLines = New-Object 'System.Collections.Generic.Queue[string]'
        SyncRoot = New-Object object
        PingObject = New-Object System.Net.NetworkInformation.Ping
    }

    $script:pingState = $state
    $state.PingObject.add_PingCompleted(
        $script:pingCompletedHandler)

    $outputBox.Clear()
    $outputBox.AppendText("PING: $target`r`n")
    $outputBox.AppendText(
        "Mode: $(if ($continuous) {
            'Continuous (unlimited)'
        } else {
            "$packetCount packets"
        })`r`n`r`n")

    $script:targetProfile.OriginalTarget = $target
    $script:targetProfile.PingStatus = "Running"
    Update-TargetProfile

    $pingButton.Text = "Stop Ping"
    $status.Text = "Pinging $target ..."

    # Send the first request immediately.
    try {
        [System.Threading.Monitor]::Enter($state.SyncRoot)
        try {
            $state.Sent = 1
            $state.InFlight = $true
        }
        finally {
            [System.Threading.Monitor]::Exit($state.SyncRoot)
        }

        $state.PingObject.SendAsync($target, 1)
        $pingTimer.Start()
    }
    catch {
        $state.Active = $false
        $pingButton.Text = "Ping"
        $script:targetProfile.PingStatus = "Failed to start"
        Update-TargetProfile

        $outputBox.AppendText(
            "Ping failed to start: $($_.Exception.Message)`r`n")

        $status.Text = "Ping failed to start."

        try { $state.PingObject.Dispose() } catch {}
        $state.PingObject = $null
    }
})

# Administration workspace: console selector, active-console context, and hosted MMC surface.
# MMC hosting remains best-effort because arbitrary MMC embedding is not officially supported.
$script:mmcProcess = $null
$script:mmcWindowHandle = [IntPtr]::Zero
$script:mmcCurrentSnapIn = $null
$script:consoleButtons = @{}

$adminPanel = New-Object System.Windows.Forms.Panel
$adminPanel.Location = New-Object System.Drawing.Point(24, 110)
$adminPanel.Size = New-Object System.Drawing.Size(800, 500)
$adminPanel.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor
    [System.Windows.Forms.AnchorStyles]::Bottom -bor
    [System.Windows.Forms.AnchorStyles]::Left -bor
    [System.Windows.Forms.AnchorStyles]::Right
$adminPanel.Visible = $false
$adminPanel.BackColor = [System.Drawing.Color]::Transparent
$content.Controls.Add($adminPanel)

$adminIntro = New-Object System.Windows.Forms.Label
$adminIntro.Text = "WINDOWS ADMINISTRATION"
$adminIntro.Location = New-Object System.Drawing.Point(0, 0)
$adminIntro.Size = New-Object System.Drawing.Size(760, 22)
$adminIntro.ForeColor = [System.Drawing.Color]::FromArgb(83, 101, 125)
$adminIntro.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$adminPanel.Controls.Add($adminIntro)

$adminHint = New-Object System.Windows.Forms.Label
$adminHint.Text = "Choose a management console. The console runs with your current Windows permissions."
$adminHint.Location = New-Object System.Drawing.Point(0, 24)
$adminHint.Size = New-Object System.Drawing.Size(760, 24)
$adminHint.ForeColor = [System.Drawing.Color]::FromArgb(105, 119, 139)
$adminHint.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$adminPanel.Controls.Add($adminHint)

$consoleBar = New-Object System.Windows.Forms.FlowLayoutPanel
$consoleBar.Location = New-Object System.Drawing.Point(0, 55)
$consoleBar.Size = New-Object System.Drawing.Size(760, 52)
$consoleBar.WrapContents = $false
$consoleBar.AutoScroll = $true
$consoleBar.BackColor = [System.Drawing.Color]::White
$consoleBar.Padding = New-Object System.Windows.Forms.Padding(10, 7, 10, 5)
$adminPanel.Controls.Add($consoleBar)

$consoleHeader = New-Object System.Windows.Forms.Panel
$consoleHeader.Location = New-Object System.Drawing.Point(0, 116)
$consoleHeader.Size = New-Object System.Drawing.Size(760, 54)
$consoleHeader.BackColor = [System.Drawing.Color]::FromArgb(255, 255, 255)
$adminPanel.Controls.Add($consoleHeader)

$activeConsoleLabel = New-Object System.Windows.Forms.Label
$activeConsoleLabel.Text = "No console selected"
$activeConsoleLabel.Location = New-Object System.Drawing.Point(16, 7)
$activeConsoleLabel.Size = New-Object System.Drawing.Size(400, 23)
$activeConsoleLabel.ForeColor = [System.Drawing.Color]::FromArgb(31, 45, 66)
$activeConsoleLabel.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 11, [System.Drawing.FontStyle]::Bold)
$consoleHeader.Controls.Add($activeConsoleLabel)

$activeConsoleDetail = New-Object System.Windows.Forms.Label
$activeConsoleDetail.Text = "Select one of the consoles above to load its management interface."
$activeConsoleDetail.Location = New-Object System.Drawing.Point(17, 30)
$activeConsoleDetail.Size = New-Object System.Drawing.Size(720, 18)
$activeConsoleDetail.ForeColor = [System.Drawing.Color]::FromArgb(105, 119, 139)
$activeConsoleDetail.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$activeConsoleDetail.AutoEllipsis = $true
$consoleHeader.Controls.Add($activeConsoleDetail)

$mmcHost = New-Object System.Windows.Forms.Panel
$mmcHost.Location = New-Object System.Drawing.Point(0, 176)
$mmcHost.Size = New-Object System.Drawing.Size(760, 270)
$mmcHost.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor
    [System.Windows.Forms.AnchorStyles]::Bottom -bor
    [System.Windows.Forms.AnchorStyles]::Left -bor
    [System.Windows.Forms.AnchorStyles]::Right
$mmcHost.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$mmcHost.BackColor = [System.Drawing.Color]::White
$adminPanel.Controls.Add($mmcHost)

$mmcPlaceholder = New-Object System.Windows.Forms.Label
$mmcPlaceholder.Text = "ADMINISTRATION CONSOLE`r`n`r`nSelect DHCP, Active Directory, or Print Management above."
$mmcPlaceholder.Dock = "Fill"
$mmcPlaceholder.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$mmcPlaceholder.ForeColor = [System.Drawing.Color]::FromArgb(135, 148, 166)
$mmcPlaceholder.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$mmcHost.Controls.Add($mmcPlaceholder)

$adminStatusPanel = New-Object System.Windows.Forms.Panel
$adminStatusPanel.Location = New-Object System.Drawing.Point(0, 454)
$adminStatusPanel.Size = New-Object System.Drawing.Size(760, 30)
$adminStatusPanel.BackColor = [System.Drawing.Color]::FromArgb(232, 238, 246)
$adminPanel.Controls.Add($adminStatusPanel)

$adminStatus = New-Object System.Windows.Forms.Label
$adminStatus.Text = "READY  |  No server changes are made automatically."
$adminStatus.Location = New-Object System.Drawing.Point(10, 0)
$adminStatus.Size = New-Object System.Drawing.Size(740, 30)
$adminStatus.TextAlign = "MiddleLeft"
$adminStatus.ForeColor = [System.Drawing.Color]::FromArgb(75, 91, 112)
$adminStatus.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
$adminStatus.AutoEllipsis = $true
$adminStatusPanel.Controls.Add($adminStatus)

$consoleItems = @(
    @{ Title = "DHCP"; SnapIn = "dhcpmgmt.msc"; Detail = "Manage DHCP servers, scopes, leases, and reservations." },
    @{ Title = "Active Directory"; SnapIn = "dsa.msc"; Detail = "Manage directory users, groups, computers, and OUs." },
    @{ Title = "Print Management"; SnapIn = "printmanagement.msc"; Detail = "Manage print servers, queues, drivers, and printers." }
)

function Set-ActiveConsoleButton {
    param([string]$SnapInName)
    foreach ($key in $script:consoleButtons.Keys) {
        $consoleButton = $script:consoleButtons[$key]
        if ($key -eq $SnapInName) {
            $consoleButton.BackColor = [System.Drawing.Color]::FromArgb(48, 105, 177)
            $consoleButton.ForeColor = [System.Drawing.Color]::White
            $consoleButton.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(48, 105, 177)
        } else {
            $consoleButton.BackColor = [System.Drawing.Color]::FromArgb(245, 247, 250)
            $consoleButton.ForeColor = [System.Drawing.Color]::FromArgb(42, 58, 80)
            $consoleButton.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(215, 223, 233)
        }
    }
}

function Stop-HostedMmc {
    if ($script:mmcProcess -and -not $script:mmcProcess.HasExited) {
        try { $script:mmcProcess.CloseMainWindow() | Out-Null } catch {}
        Start-Sleep -Milliseconds 250
        try {
            if (-not $script:mmcProcess.HasExited) { $script:mmcProcess.Kill() }
        } catch {}
    }
    $script:mmcProcess = $null
    $script:mmcWindowHandle = [IntPtr]::Zero
    $script:mmcCurrentSnapIn = $null
    try {
        $mmcHost.Controls.Clear()
        $mmcHost.Controls.Add($mmcPlaceholder)
        $mmcPlaceholder.Visible = $true
    } catch {}
}

function Set-HostedMmcBounds {
    if ($script:mmcWindowHandle -ne [IntPtr]::Zero -and $mmcHost.ClientSize.Width -gt 0 -and $mmcHost.ClientSize.Height -gt 0) {
        [void][ShellOpsNativeWindow]::SetWindowPos(
            $script:mmcWindowHandle, [IntPtr]::Zero, 0, 0,
            $mmcHost.ClientSize.Width, $mmcHost.ClientSize.Height,
            ([ShellOpsNativeWindow]::SWP_NOZORDER -bor [ShellOpsNativeWindow]::SWP_NOACTIVATE))
    }
}
$mmcHost.Add_Resize({ Set-HostedMmcBounds })


function Start-HostedMmc {
    param([Parameter(Mandatory=$true)][string]$SnapInName)

    Stop-HostedMmc

    $candidates = @(
        (Join-Path $env:WINDIR ("System32\" + $SnapInName)),
        (Join-Path $env:WINDIR ("SysWOW64\" + $SnapInName)),
        (Join-Path $env:WINDIR ("Sysnative\" + $SnapInName))
    )

    $snapInPath = $candidates |
        Where-Object { Test-Path -LiteralPath $_ } |
        Select-Object -First 1

    $mmcPath = Join-Path $env:WINDIR "System32\mmc.exe"

    if (-not $snapInPath) {
        $adminStatus.Text = "$SnapInName was not found. The matching RSAT/Windows feature may not be installed."
        return
    }

    $oldStyle = $null
    $handle = [IntPtr]::Zero

    try {
        # Ensure the WinForms host has a real HWND before launching MMC.
        $hostHandle = $mmcHost.Handle
        if ($hostHandle -eq [IntPtr]::Zero) {
            throw "The ShellOps MMC host panel does not have a valid window handle."
        }

        $proc = Start-Process `
            -FilePath $mmcPath `
            -ArgumentList @("`"$snapInPath`"") `
            -PassThru `
            -ErrorAction Stop

        $script:mmcProcess = $proc
        $script:mmcWindowHandle = [IntPtr]::Zero
        $script:mmcCurrentSnapIn = $SnapInName

        # MMC's MainWindowHandle can be late or temporarily unavailable.
        # Poll both Process.MainWindowHandle and the native top-level window list.
        $deadline = (Get-Date).AddSeconds(20)
        do {
            Start-Sleep -Milliseconds 200
            try {
                $proc.Refresh()
                $handle = $proc.MainWindowHandle
            } catch {
                $handle = [IntPtr]::Zero
            }

            if ($handle -eq [IntPtr]::Zero) {
                $handle = [ShellOpsNativeWindow]::FindTopLevelWindowForProcess($proc.Id)
            }
        } while (
            $handle -eq [IntPtr]::Zero -and
            (Get-Date) -lt $deadline -and
            -not $proc.HasExited
        )

        if ($handle -eq [IntPtr]::Zero) {
            throw "MMC started, but no visible main window was found for process ID $($proc.Id) within 20 seconds."
        }

        $script:mmcWindowHandle = $handle

        # Convert the top-level MMC window into a child of the ShellOps panel.
        $oldStyle = [ShellOpsNativeWindow]::GetStyle($handle)
        $removeStyle = [ShellOpsNativeWindow]::WS_POPUP -bor
            [ShellOpsNativeWindow]::WS_CAPTION -bor
            [ShellOpsNativeWindow]::WS_THICKFRAME -bor
            [ShellOpsNativeWindow]::WS_SYSMENU -bor
            [ShellOpsNativeWindow]::WS_MINIMIZEBOX -bor
            [ShellOpsNativeWindow]::WS_MAXIMIZEBOX
        $newStyle = ($oldStyle -band (-bnot $removeStyle)) -bor
            [ShellOpsNativeWindow]::WS_CHILD
        [ShellOpsNativeWindow]::SetStyle($handle, $newStyle)

        $parentError = 0
        [void][ShellOpsNativeWindow]::SetParentChecked($handle, $hostHandle, [ref]$parentError)
        if ($parentError -ne 0) {
            throw "Windows SetParent failed with error $parentError."
        }

        $actualParent = [ShellOpsNativeWindow]::GetParent($handle)
        if ($actualParent -ne $hostHandle) {
            throw "Windows did not assign the MMC window to the ShellOps host panel."
        }

        $positioned = [ShellOpsNativeWindow]::SetWindowPos(
            $handle,
            [IntPtr]::Zero,
            0,
            0,
            $mmcHost.ClientSize.Width,
            $mmcHost.ClientSize.Height,
            ([ShellOpsNativeWindow]::SWP_NOZORDER -bor
             [ShellOpsNativeWindow]::SWP_NOACTIVATE -bor
             [ShellOpsNativeWindow]::SWP_FRAMECHANGED)
        )

        if (-not $positioned) {
            $positionError = [Runtime.InteropServices.Marshal]::GetLastWin32Error()
            throw "Windows SetWindowPos failed with error $positionError."
        }

        [void][ShellOpsNativeWindow]::ShowWindow($handle, [ShellOpsNativeWindow]::SW_SHOW)
        Set-HostedMmcBounds

        $selectedConsole = $consoleItems |
            Where-Object { $_.SnapIn -eq $SnapInName } |
            Select-Object -First 1
        if ($selectedConsole) {
            $activeConsoleLabel.Text = $selectedConsole.Title
            $activeConsoleDetail.Text = $selectedConsole.Detail
        } else {
            $activeConsoleLabel.Text = $SnapInName
            $activeConsoleDetail.Text = "Management console loaded inside ShellOps."
        }
        $mmcHost.Controls.Remove($mmcPlaceholder)
        $adminStatus.Text = "EMBEDDED  |  $SnapInName is hosted inside ShellOps."
    }
    catch {
        # If embedding failed after changing the style, restore the normal
        # top-level appearance so the console remains usable for diagnosis.
        if ($handle -ne [IntPtr]::Zero -and $null -ne $oldStyle) {
            try {
                [ShellOpsNativeWindow]::SetStyle($handle, [long]$oldStyle)
                [void][ShellOpsNativeWindow]::SetWindowPos(
                    $handle, [IntPtr]::Zero, 0, 0, 0, 0,
                    ([ShellOpsNativeWindow]::SWP_NOZORDER -bor
                     [ShellOpsNativeWindow]::SWP_NOACTIVATE -bor
                     [ShellOpsNativeWindow]::SWP_FRAMECHANGED)
                )
                [void][ShellOpsNativeWindow]::ShowWindow($handle, [ShellOpsNativeWindow]::SW_SHOW)
            } catch {}
        }
        $mmcPlaceholder.Visible = $true
        $adminStatus.Text = "MMC embedding failed: $($_.Exception.GetBaseException().Message)"
    }
}

foreach ($item in $consoleItems) {
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = $item.Title
    $btn.Tag = $item.SnapIn
    $btn.Size = New-Object System.Drawing.Size(184, 36)
    $btn.Margin = New-Object System.Windows.Forms.Padding(0, 0, 9, 0)
    $btn.FlatStyle = "Flat"
    $btn.FlatAppearance.BorderSize = 1
    $btn.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(215, 223, 233)
    $btn.BackColor = [System.Drawing.Color]::FromArgb(245, 247, 250)
    $btn.ForeColor = [System.Drawing.Color]::FromArgb(42, 58, 80)
    $btn.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9, [System.Drawing.FontStyle]::Bold)
    $btn.Cursor = [System.Windows.Forms.Cursors]::Hand
    $btn.Add_Click({ Start-HostedMmc -SnapInName ([string]$this.Tag) })
    $script:consoleButtons[$item.SnapIn] = $btn
    $consoleBar.Controls.Add($btn)
}

# Core navigation. Integrations are distributed separately as optional add-ons.
# Navigation
$buttonNames = @(
    "Dashboard",
    "IT Utilities",
    "Admin Consoles"
)

$script:navButtons = @{}
$y = 28

$brandLabel = New-Object System.Windows.Forms.Label
$brandLabel.Text = "SHELLOPS  /  HELPDESK TOOLS"
$brandLabel.Location = New-Object System.Drawing.Point(20, 18)
$brandLabel.Size = New-Object System.Drawing.Size(170, 24)
$brandLabel.ForeColor = [System.Drawing.Color]::FromArgb(145, 164, 188)
$brandLabel.Font = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Bold)
$nav.Controls.Add($brandLabel)

$navSection = New-Object System.Windows.Forms.Label
$navSection.Text = "WORKSPACE"
$navSection.Location = New-Object System.Drawing.Point(20, 62)
$navSection.Size = New-Object System.Drawing.Size(160, 20)
$navSection.ForeColor = [System.Drawing.Color]::FromArgb(120, 140, 164)
$navSection.Font = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
$nav.Controls.Add($navSection)

$y = 92
foreach ($name in $buttonNames) {
    $button = New-Object System.Windows.Forms.Button
    $button.Text = $name
    $button.Location = New-Object System.Drawing.Point(12, $y)
    $button.Size = New-Object System.Drawing.Size(181, 44)
    $button.FlatStyle = "Flat"
    $button.FlatAppearance.BorderSize = 0
    $button.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(39, 55, 78)
    $button.TextAlign = "MiddleLeft"
    $button.Padding = New-Object System.Windows.Forms.Padding(14, 0, 0, 0)
    $button.BackColor = [System.Drawing.Color]::FromArgb(23, 34, 53)
    $button.ForeColor = [System.Drawing.Color]::FromArgb(211, 220, 232)
    $button.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
    $button.Cursor = [System.Windows.Forms.Cursors]::Hand
    $script:navButtons[$name] = $button

    $button.Add_Click({
        $selected = $this.Text
        $heading.Text = $selected
        $dashboardPanel.Visible = ($selected -eq "Dashboard")
        $utilityPanel.Visible = ($selected -eq "IT Utilities")
        $adminPanel.Visible = ($selected -eq "Admin Consoles")

        switch ($selected) {
            "Dashboard" {
                $description.Text = "Your workstation at a glance, with quick access to everyday support tools."
            }
            "IT Utilities" {
                $description.Text = "Local Windows troubleshooting tools."
            }
            "Admin Consoles" {
                $description.Text = "Windows management consoles. Remote changes are not performed automatically."
            }
        }

        foreach ($navName in $script:navButtons.Keys) {
            $navButton = $script:navButtons[$navName]
            if ($navName -eq $selected) {
                $navButton.BackColor = [System.Drawing.Color]::FromArgb(48, 105, 177)
                $navButton.ForeColor = [System.Drawing.Color]::White
                $navButton.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9.5, [System.Drawing.FontStyle]::Bold)
            } else {
                $navButton.BackColor = [System.Drawing.Color]::FromArgb(23, 34, 53)
                $navButton.ForeColor = [System.Drawing.Color]::FromArgb(211, 220, 232)
                $navButton.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
            }
        }
        $status.Text = "Workspace: $selected"
    })

    $nav.Controls.Add($button)
    $y += 52
}

# Dashboard shortcuts use the same navigation handlers as the sidebar.
$dashUtilityButton.Add_Click({ $script:navButtons["IT Utilities"].PerformClick() })
$dashAdminButton.Add_Click({ $script:navButtons["Admin Consoles"].PerformClick() })

# Consistent button styling for the utility and console workspaces.
$accent = [System.Drawing.Color]::FromArgb(48, 105, 177)
$neutralButton = [System.Drawing.Color]::FromArgb(232, 238, 246)
foreach ($control in @($pingButton, $dnsButton, $mrcButton, $copyButton, $clearButton, $systemButton, $networkButton, $dashUtilityButton, $dashAdminButton)) {
    $control.FlatStyle = "Flat"
    $control.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(213, 222, 233)
    $control.FlatAppearance.BorderSize = 1
    $control.BackColor = $neutralButton
    $control.ForeColor = [System.Drawing.Color]::FromArgb(35, 52, 75)
    $control.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $control.Cursor = [System.Windows.Forms.Cursors]::Hand
}
$pingButton.BackColor = $accent
$pingButton.ForeColor = [System.Drawing.Color]::White

# Keep the selector, active-console strip, embedded console, and status bar aligned.
$adminPanel.Add_Resize({
    $innerWidth = [Math]::Max(420, $adminPanel.ClientSize.Width)
    $innerHeight = [Math]::Max(300, $adminPanel.ClientSize.Height)
    $adminIntro.Width = $innerWidth
    $adminHint.Width = $innerWidth
    $consoleBar.Width = $innerWidth
    $consoleHeader.Width = $innerWidth
    $activeConsoleDetail.Width = [Math]::Max(200, $innerWidth - 34)
    $mmcHost.Width = $innerWidth
    $mmcHost.Height = [Math]::Max(100, $innerHeight - 210)
    $adminStatusPanel.Location = New-Object System.Drawing.Point(0, ($innerHeight - 30))
    $adminStatusPanel.Width = $innerWidth
    $adminStatus.Width = [Math]::Max(200, $innerWidth - 20)
    Set-HostedMmcBounds
})

# Select Dashboard on startup and establish the active navigation state.
$dashboardPanel.Visible = $true
$utilityPanel.Visible = $false
$adminPanel.Visible = $false
$script:navButtons["Dashboard"].PerformClick()

# Close the MMC process launched by ShellOps when the application exits.
$form.Add_FormClosing({ Stop-HostedMmc })

$dashboardPanel.Add_Resize({
    $w = $dashboardPanel.ClientSize.Width
    if ($w -gt 500) {
        $gap = 14
        $cardW = [Math]::Max(180, [int](($w - (2 * $gap)) / 3))
        foreach ($card in $dashboardPanel.Controls | Where-Object { $_ -is [System.Windows.Forms.Panel] }) {
            if ($card.Location.Y -eq 0) {
                $idx = [int]$card.Tag
                $card.Width = $cardW
                $card.Location = New-Object System.Drawing.Point(($idx * ($cardW + $gap)), 0)
            }
        }
        $dashOsValue.Parent.Width = [Math]::Max(220, [int]($w * 0.52))
        $dashPowerShellValue.Parent.Location = New-Object System.Drawing.Point(([int]($w * 0.54)), 128)
        $dashPowerShellValue.Parent.Width = [Math]::Max(180, [int]($w * 0.28))
    }
})

# Start the application
[void]$form.ShowDialog()
