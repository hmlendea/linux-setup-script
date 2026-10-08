# Change Guide

This document provides guidelines for safely modifying the linux-setup-script repository.

## General Principles

- **Idempotency**: All changes must be idempotent. Scripts should produce the same result when run multiple times.
- **Safety**: Always test changes on non-production systems first.
- **Documentation**: Update documentation for any changes that affect behavior or configuration.
- **Versioning**: Follow semantic versioning for public APIs and interfaces.

## Modifying Foundation Layer

### Files in `scripts/common/`

The foundation layer contains shared utilities used by all scripts. Changes here affect the entire system.

**Safe to modify:**
- `common.sh` - Execution primitives, logging
- `filesystem.sh` - Path operations, file manipulation
- `system-info.sh` - Environment detection

**High risk:**
- `package-management.sh` - Package operations affect system state
- `config.sh` - Configuration file manipulation
- `service-management.sh` - Service control

### Modification Process

1. **Backup**: Always backup the original file before modification
2. **Test**: Test changes in a controlled environment
3. **Validate**: Ensure idempotency by running multiple times
4. **Document**: Update relevant documentation

## Modifying Script Components

### Files in `scripts/`

Each script in the scripts directory performs a specific task. Changes should be made with care.

**Low risk:**
- `update-grub.sh` - GRUB configuration
- `configure-time.sh` - Time configuration
- `configure-locale.sh` - Locale configuration

**High risk:**
- `configure-system.sh` - System-wide configuration
- `install-packages.sh` - Package installation
- `uninstall-packages.sh` - Package removal

## Configuration Management

### RC Files

RC files are deployed to `~/.config/` and `~/.local/` directories. When modifying:

1. **Check format**: Ensure the format matches existing files
2. **Test deployment**: Use `update_file_if_distinct` to verify changes
3. **Backup**: Keep backup of original configuration

### Resources

Resources are deployed to `~/.local/share/` and `~/.local/bin/`. When modifying:

1. **Check permissions**: Ensure executable permissions where needed
2. **Test deployment**: Verify resource availability
3. **Update dependencies**: Check for any resource dependencies

## Profile Scripts

Profile scripts are deployed to `~/.config/linux-setup-script/profiles/`. When modifying:

1. **Test sourcing**: Ensure profiles can be sourced without errors
2. **Test execution**: Run profiles in a controlled environment
3. **Document changes**: Update profile documentation

## Git Integration

### GPG and SSH Keys

When modifying key generation or management:

1. **Test key generation**: Verify keys can be generated and used
2. **Test signing**: Verify keys can sign commits
3. **Test SSH**: Verify SSH keys work for authentication

### Git Hooks

Git hooks are installed in `.git/hooks/`. When modifying:

1. **Test hooks**: Ensure hooks work correctly
2. **Backup**: Keep backup of original hooks
3. **Document**: Document hook behavior and requirements

## Testing and Validation

### Manual Testing

1. **Run scripts**: Execute scripts in a test environment
2. **Check results**: Verify expected changes were made
3. **Rollback**: Ensure you can rollback changes if needed

### Automated Testing

1. **Unit tests**: Test individual functions
2. **Integration tests**: Test script interactions
3. **End-to-end tests**: Test complete workflows

## Common Pitfalls

### Privilege Escalation

- **Problem**: Scripts may fail when run without sufficient privileges
- **Solution**: Always check `HAS_SU_PRIVILEGES` before attempting privileged operations
- **Test**: Test both with and without privileges

### File System Operations

- **Problem**: File operations may fail due to permissions or disk space
- **Solution**: Check for errors and handle them appropriately
- **Test**: Test with different file systems and permissions

### Package Management

- **Problem**: Package operations may fail due to network issues or package availability
- **Solution**: Check for errors and handle them appropriately
- **Test**: Test with different package managers

## References

- [components/foundation-layer.md](./components/foundation-layer.md)
- [components/package-management.md](./components/package-management.md)
- [components/configuration-management.md](./components/configuration-management.md)
- [security.md](./security.md)