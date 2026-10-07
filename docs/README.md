# Linux Setup Script — Documentation Index

This directory contains the comprehensive technical documentation for the
`linux-setup-script` repository. The documentation is intended to serve as a
persistent knowledge base for future coding agents, eliminating the need to
repeatedly reverse-engineer the repository from source.

## Documentation Files

| File | Description |
|------|-------------|
| [01-repository-overview.md](01-repository-overview.md) | Repository purpose, scope, supported platforms, and high-level architecture |
| [02-execution-model.md](02-execution-model.md) | Entry points, execution flow, privilege model, and environment detection |
| [03-foundation-layer.md](03-foundation-layer.md) | Core utilities: filesystem paths, system-info detection, config helpers, package management |
| [04-configuration-management.md](04-configuration-management.md) | Configuration variables, themes, fonts, terminal settings, and their derivation |
| [05-script-inventory.md](05-script-inventory.md) | Complete inventory of all scripts and their responsibilities |
| [06-data-and-resources.md](06-data-and-resources.md) | Data files, resource templates, and their roles |
| [07-platform-integrations.md](07-platform-integrations.md) | Package managers, display servers, desktop environments, and hardware integrations |
| [08-security-and-privileges.md](08-security-and-privileges.md) | Privilege escalation, SSH/GPG setup, Flatpak permissions, and security hardening |
| [09-boot-and-system-services.md](09-boot-and-system-services.md) | GRUB configuration, systemd services, and system-level service management |
| [10-known-limitations-and-invariants.md](10-known-limitations-and-invariants.md) | Design invariants, edge cases, and known limitations |

## How to Use This Documentation

Each documentation file follows a consistent structure:

1. **Purpose** — Why the component exists
2. **Scope** — What it owns
3. **Boundary** — What it deliberately does not own
4. **Location** — Where it is implemented
5. **Entry** — How it is invoked
6. **Execution** — What precisely happens
7. **Data** — What information enters, changes, and exits
8. **State** — What state is read or mutated
9. **Dependencies** — What it depends upon
10. **Dependents** — What depends upon it
11. **Configuration** — What modifies its behaviour
12. **Failures** — What can fail and what happens then
13. **Invariants** — What must remain true
14. **Tests** — Where and how behaviour is verified
15. **Integration** — How it contributes to larger processes
16. **Modification impact** — What else may require modification if it changes