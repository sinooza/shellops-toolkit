# Architecture overview

ShellOps core is a compact PowerShell/Windows Forms application. Integrations are deliberately excluded from the core runtime and maintained as independent add-ons.

## Entry point

`src/ShellOps.ps1` builds the Windows Forms interface, manages core page navigation, runs local diagnostic commands, launches optional local tools, and hosts the MMC consoles. It does not import add-ons or make ticketing/VDI API calls.

## Native Windows helpers

The main script compiles two small C# helper types with `Add-Type`:

- `ShellOpsCueBanner` applies a native edit-control cue banner.
- `ShellOpsNativeWindow` wraps the Win32 calls used to locate an MMC window, adjust its styles and host it inside a WinForms panel.

The native helper type names are unique to ShellOps to avoid collisions with older loaded helper types in a long-running PowerShell process. Do not rename these types casually without considering PowerShell's process-wide type loading behavior.

## Optional add-ons

Add-ons live under `addons/<name>/`. The core does not auto-discover, import, execute, or update them. Each add-on must provide its own documentation, dependency declaration, configuration guidance, security notes and tests. Users install and invoke add-ons explicitly.

The ServiceDesk Plus add-on currently contains a standalone read-only API module. It is not connected to the ShellOps graphical interface. No Horizon add-on is included; the former placeholder page has been removed.

## External tools

- MMC snap-ins are launched from Windows and hosted best-effort inside the application.
- Dameware MRC is launched as an installed external executable. ShellOps does not bundle Dameware.

## Design constraints

- Keep the core local-first and usable without add-ons.
- Avoid automatic elevation.
- Add-ons must not be loaded implicitly.
- Keep credentials and tenant-specific settings out of source and examples.
- Prefer small, isolated changes over broad UI refactors because the application is a single large script with event-driven state.
