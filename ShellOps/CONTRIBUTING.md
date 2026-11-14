# Contributing to ShellOps

Thanks for helping improve ShellOps. Keep changes focused and preserve working behavior.

## Before opening an issue

- Search existing issues first.
- Use a supported Windows and PowerShell version.
- Include sanitized reproduction steps and exact error text.
- Never attach credentials, customer records, private service URLs, internal hostnames or sensitive screenshots.

## Pull requests

1. Explain the user problem and the smallest change that solves it.
2. Identify affected features and optional dependencies.
3. Update documentation when behavior, prerequisites or configuration changes.
4. Add or update a manual test checklist for Windows-only behavior.
5. Run the static-analysis workflow where possible.
6. State clearly what you tested and what you could not test.

## Code guidelines

- Target PowerShell 7.2+ on Windows.
- Keep integrations outside the core and require explicit user action before loading add-ons.
- Never hardcode a real tenant URL, API key, username, internal address or organization name.
- Do not silently elevate privileges or weaken execution policy.
- Avoid broad refactors in the main UI script when a focused change will do.
- Keep native helper type names unique and account for PowerShell's process-wide .NET type loading.
