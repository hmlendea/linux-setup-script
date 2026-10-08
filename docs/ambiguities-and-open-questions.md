# Ambiguities and Open Questions

This document captures known ambiguities, open questions, and TODOs for the linux-setup-script repository.

## Known Ambiguities

- **Package Manager Abstraction**: The package-management abstraction layer needs clearer definition of supported package managers across distributions. Currently supports pacman, apt, apk, pkg, Flatpak, Cargo, GitHub releases, but may need additional adapters.

- **Privilege Escalation Model**: The `run_as_su` function uses `sudo -n true` or `su -c 'true'` detection, but behavior differs between sudo and su implementations. Need to document exact detection logic.

- **File System Constants**: Path constants in `filesystem.sh` need standardization. Some constants are defined in multiple places - need to consolidate.

- **Configuration Schema**: Configuration files use different formats (INI, JSON, XML, GSettings). Need to document format precedence and validation rules.

- **Android/Termux Support**: Android support appears limited to specific package managers (apk, pkg). Need to verify compatibility with other Android package managers.

## Open Questions

1. Should we add explicit support for Snap packages in the package management abstraction?
2. How should we handle cross-distro configuration files (e.g., shared configs between Arch and Ubuntu)?
3. What is the expected behavior when running on immutable distros (e.g., Silverblue, MicroOS)?
4. Are there any edge cases with file locking during atomic writes that need special handling?
5. Should we add more comprehensive error codes for different failure scenarios?

## TODOs

- [ ] Review and document privilege escalation detection logic
- [ ] Consolidate filesystem path constants
- [ ] Add Snap package support to package management abstraction
- [ ] Document configuration format precedence rules
- [ ] Verify Android/Termux compatibility with all package managers
- [ ] Add more comprehensive error code documentation
- [ ] Review atomic write edge cases

## References

- [components/filesystem.md](./components/filesystem.md)
- [components/package-management.md](./components/package-management.md)
- [components/configuration-management.md](./components/configuration-management.md)
- [security.md](./security.md)