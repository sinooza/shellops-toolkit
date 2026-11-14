# Security policy

## Supported release

Security reports are accepted for the latest public release and the current default branch.

## Reporting a vulnerability

Do not disclose suspected vulnerabilities in a public issue. Use GitHub's private vulnerability reporting feature for this repository if it is enabled. If it is not enabled, contact the repository owner through a verified private contact method listed in the GitHub profile.

Include a description, impact, reproduction steps and affected version. Do not include real API keys, customer records or unrelated personal data.

## Security notes

- Optional add-ons may store credentials or contact external services. Review each add-on's security notes and use least-privilege credentials.
- MMC consoles can make privileged changes according to the current user's Windows permissions. ShellOps is not a security boundary.
- Do not run untrusted copies of the script with elevated privileges.
- Review all code before running it in a production environment.
