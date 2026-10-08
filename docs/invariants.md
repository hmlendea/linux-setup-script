# Invariants

This document describes the system invariants, guarantees, and contracts
that the linux-setup-script repository maintains.

## Overview

Invariants are properties that must always hold true throughout the
execution of the setup scripts. They ensure correctness, idempotency,
and predictability.

## Core Invariants

### 1. Idempotency Invariant

**Statement**: Running any script multiple times produces the same result as running it once.

**Guarantee**:
- All file writes use `update_file_if_distinct` (content comparison)
- All package operations check `is_package_installed` first
- All service operations check `is_service_enabled` / `is_service_running` first
- All configuration operations check current state before applying

**Verification**:
```bash
# Test idempotency
./run.sh --dry-run
./run.sh --dry-run  # Should produce identical output
```

### 2. Privilege Separation Invariant

**Statement**: System-level operations always use `run_as_su`; user-level operations never do.

**Guarantee**:
- `/etc/`, `/usr/`, `/boot/`, `/var/` modifications via `run_as_su`
- `$HOME/`, `$XDG_CONFIG_HOME/`, `$XDG_DATA_HOME/` modifications direct
- No `sudo`/`su` in user-level scripts
- `HAS_SU_PRIVILEGES` checked before system operations

**Verification**:
```bash
# Check for direct sudo usage in user scripts
grep -r "sudo " scripts/ --include="*.sh" | grep -v "run_as_su"
# Should return empty
```

### 3. Platform Abstraction Invariant

**Statement**: All platform-specific logic is encapsulated in `system-info.sh` and `package-management.sh`.

**Guarantee**:
- Scripts use `DISTRO_FAMILY`, `PACKAGE_MANAGER`, `SERVICE_MANAGER` variables
- No direct `pacman`/`apt`/`systemctl` calls in configuration scripts
- Platform detection runs once at startup
- Graceful degradation for unsupported platforms

**Verification**:
```bash
# Check for direct package manager calls
grep -r "pacman\|apt-get\|apk " scripts/ --include="*.sh" | grep -v "package-management.sh"
# Should only be in package-management.sh
```

### 4. Configuration Source Invariant

**Statement**: Each configuration value has exactly one authoritative source.

**Guarantee**:
- Theme settings: `configure-system.sh` → `system-info.sh` constants
- Package lists: `install-packages.sh` arrays
- Service lists: `configure-services-*.sh` arrays
- No duplicate definitions across scripts

**Verification**:
```bash
# Check for duplicate constant definitions
grep -r "GTK_THEME\|ICON_THEME" scripts/ --include="*.sh"
# Should only be defined in configure-system.sh
```

### 5. No Runtime Templating Invariant

**Statement**: Configuration files are deployed verbatim; no variable interpolation at runtime.

**Guarantee**:
- RC files in `rc/` deployed as-is via `update_file_if_distinct`
- No `sed`/`envsubst`/`eval` on config files
- Template files don't exist; only final configs
- Variables resolved at author time, not deploy time

**Verification**:
```bash
# Check for templating operations
grep -r "envsubst\|sed.*\${" scripts/ --include="*.sh"
# Should return empty
```

### 6. Declarative Configuration Invariant

**Statement**: All configuration is declarative (desired state), not imperative (steps).

**Guarantee**:
- Scripts declare desired state: "package X installed", "service Y enabled"
- Implementation details hidden in foundation modules
- No procedural "do X then Y then Z" in configuration scripts
- Order independence within phases

### 7. Single Source of Truth Invariant

**Statement**: Each piece of knowledge exists in exactly one place.

**Guarantee**:
- Package names: `install-packages.sh` only
- Service names: `configure-services-*.sh` only
- Theme names: `configure-system.sh` only
- Path constants: `filesystem.sh` only
- Detection logic: `system-info.sh` only

### 8. Graceful Degradation Invariant

**Statement**: Missing optional components don't break the setup.

**Guarantee**:
- Optional packages: `is_package_installed` check before config
- Optional services: `is_service_enabled` check before config
- Optional tools: `command_exists` check before use
- Optional hardware: `GPU_FAMILY` check before config

### 9. Atomic File Operations Invariant

**Statement**: File operations are atomic or leave system in consistent state.

**Guarantee**:
- `update_file_if_distinct` uses `cp` (atomic on same filesystem)
- No partial writes visible
- Backup before destructive operations
- Rollback on failure where possible

### 10. Deterministic Execution Invariant

**Statement**: Same inputs always produce same outputs.

**Guarantee**:
- No random values in configuration
- No time-dependent logic (except explicit scheduling)
- No interactive prompts in automated runs
- Fixed package versions where possible

## Phase Invariants

### Phase 0: Pre-flight
- Repository structure validated
- Required tools available
- Privileges detected
- Platform identified

### Phase 1: Foundation
- All common modules loaded exactly once
- No circular dependencies
- All functions available

### Phase 2: System Configuration
- Repositories configured before package installs
- Packages installed before service config
- Services configured before hardware integration
- GRUB updated last

### Phase 3: User Configuration
- Packages installed before app config
- Default apps configured before launchers
- Launchers configured before autostart
- RC files deployed last

### Phase 4: Post-setup
- Cleanup runs after all config
- Verification runs after cleanup
- Summary generated last

## Data Invariants

### 1. Data File Integrity
- `data/steam-names.txt`: One entry per line, no duplicates
- `data/steam-wmclasses.txt`: One entry per line, no duplicates
- Both files UTF-8 encoded

### 2. Resource File Integrity
- `resources/firefox/containers.json`: Valid JSON
- `resources/firefox/userChrome.css`: Valid CSS
- `resources/neofetch/ascii-*`: Valid ASCII art
- All logos: Valid image files

### 3. RC File Integrity
- All files in `rc/`: Valid syntax for target format
- No absolute paths (use `$HOME`, `$XDG_CONFIG_HOME`)
- No hardcoded usernames

### 4. Profile Script Integrity
- `profiles/*.sh`: Sourceable, no side effects on source
- Export variables, don't execute commands
- Idempotent to source multiple times

## Error Handling Invariants

### 1. Error Propagation
- Functions return non-zero on failure
- Errors bubble up unless explicitly handled
- `set -euo pipefail` in all scripts

### 2. Error Context
- Error messages include script, function, line
- Failed operation identified
- Recovery hint provided where possible

### 3. No Silent Failures
- All failures logged at ERROR level
- Warnings for recoverable issues
- Success logged for critical operations

## Security Invariants

### 1. No Secrets in Code
- No passwords, tokens, keys in repository
- Secrets from environment variables only
- `.gitignore` excludes secret files

### 2. Least Privilege
- `run_as_su` only for system paths
- User operations never elevate
- Temporary files in `$TMPDIR` with restrictive permissions

### 3. Input Validation
- All external input validated
- Path traversal prevented
- Command injection prevented

## Testing Invariants

### 1. Test Isolation
- Tests don't modify system state
- Tests use temporary directories
- Tests clean up after themselves

### 2. Test Determinism
- Same test always produces same result
- No flaky tests
- No external dependencies in unit tests

### 3. Test Coverage
- All foundation modules have unit tests
- All configuration scripts have integration tests
- Critical paths have end-to-end tests

## Documentation Invariants

### 1. Documentation Currency
- Documentation updated with code changes
- `docs/` reflects current implementation
- No stale examples

### 2. Link Validity
- All internal links resolve
- All external links accessible
- No broken references

## Verification Checklist

### Pre-commit
- [ ] ShellCheck passes
- [ ] shfmt formatting correct
- [ ] Unit tests pass
- [ ] No direct sudo in user scripts
- [ ] No hardcoded paths
- [ ] No secrets in code

### Pre-release
- [ ] Integration tests pass
- [ ] Idempotency verified
- [ ] All platforms tested
- [ ] Documentation updated
- [ ] Changelog updated

### Post-release
- [ ] Smoke test on clean VM
- [ ] Upgrade test from previous version
- [ ] Rollback test

## Invariant Violations

### Detection
```bash
# Check for common violations
./scripts/verify-invariants.sh
```

### Common Violations

| Invariant | Violation Example | Fix |
|-----------|-------------------|-----|
| Idempotency | `echo "config" >> file` | Use `update_file_if_distinct` |
| Privilege Separation | `sudo cp file /etc/` | Use `run_as_su update_file_if_distinct` |
| Platform Abstraction | `pacman -S package` | Use `install_package` |
| Config Source | `GTK_THEME="Adwaita"` in two files | Centralise in `configure-system.sh` |
| Runtime Templating | `sed "s/VAR/$VAL/" file` | Deploy final config from `rc/` |
| Single Source | Package list in two scripts | Consolidate in `install-packages.sh` |

## Future Invariants

1. **Reproducibility** — Bit-for-bit identical results on same platform
2. **Rollback Safety** — Every change reversible
3. **Audit Trail** — Every change logged with context
4. **Compliance** — Meets security baselines (CIS, STIG)
5. **Observability** — Metrics for every operation