# Security

This document describes the security model, practices, and considerations
for the linux-setup-script repository.

## Overview

The repository follows a defense-in-depth approach with multiple security
layers: code, configuration, runtime, and operational.

## Threat Model

### Assets

| Asset | Sensitivity | Protection |
|-------|-------------|------------|
| System configuration | High | Root access required |
| User configuration | Medium | User access required |
| SSH/GPG keys | Critical | Encrypted, never logged |
| GitHub tokens | Critical | Environment variables only |
| Package sources | Medium | Verified repositories |

### Threats

| Threat | Likelihood | Impact | Mitigation |
|--------|------------|--------|------------|
| Malicious package | Low | High | Verified repos, signature check |
| Config injection | Medium | High | No templating, validation |
| Privilege escalation | Low | Critical | Least privilege, run_as_su |
| Secret exposure | Medium | Critical | No secrets in code, masking |
| Supply chain | Low | High | Pinned versions, checksums |

## Security Principles

### 1. Least Privilege

```bash
# Only elevate when necessary
run_as_su() {
    if [ "${HAS_SU_PRIVILEGES}" = "true" ]; then
        if command_exists sudo; then
            sudo "$@"
        elif command_exists su; then
            su -c "$*"
        else
            log_error "No privilege escalation available"
            return 1
        fi
    else
        log_error "Insufficient privileges"
        return 1
    fi
}
```

### 2. No Secrets in Code

```bash
# Secrets from environment only
github_auth() {
    local token="${GITHUB_TOKEN:-}"

    if [ -z "${token}" ]; then
        log_warn "GITHUB_TOKEN not set, skipping GitHub auth"
        return 0
    fi

    echo "${token}" | gh auth login --with-token
}
```

### 3. Input Validation

```bash
# Validate all external input
validate_path() {
    local path="$1"
    local base="${2:-/}"

    # Resolve absolute path
    local resolved=$(realpath "${path}" 2>/dev/null)

    # Check within base
    if [[ "${resolved}" != "${base}"* ]]; then
        log_error "Path traversal attempt: ${path}"
        return 1
    fi

    echo "${resolved}"
}
```

### 4. Command Injection Prevention

```bash
# Never use eval with user input
# BAD: eval "command $user_input"
# GOOD: command "$user_input"

# Use arrays for commands
run_command() {
    local cmd=("$@")
    "${cmd[@]}"
}
```

## Secure Coding Practices

### 1. File Operations

```bash
# Safe file write
safe_write() {
    local path="$1"
    local content="$2"
    local mode="${3:-644}"

    # Validate path
    validate_path "${path}" "/etc" || return 1

    # Write to temp file first
    local temp=$(mktemp)
    echo "${content}" > "${temp}"
    chmod "${mode}" "${temp}"

    # Atomic move
    run_as_su mv "${temp}" "${path}"
}
```

### 2. Temporary Files

```bash
# Secure temporary files
secure_temp() {
    local prefix="${1:-linux-setup}"
    local temp=$(mktemp -t "${prefix}.XXXXXX")
    chmod 600 "${temp}"
    echo "${temp}"
}

# Cleanup on exit
cleanup_temp() {
    rm -f "${TEMP_FILES[@]}"
}
trap cleanup_temp EXIT
```

### 3. Network Operations

```bash
# Verify downloads
verify_download() {
    local file="$1"
    local expected_sha256="$2"

    local actual=$(sha256sum "${file}" | cut -d' ' -f1)

    if [ "${actual}" != "${expected_sha256}" ]; then
        log_error "Checksum mismatch for ${file}"
        return 1
    fi
}
```

### 4. Process Execution

```bash
# Safe command execution
safe_exec() {
    local cmd=("$@")

    # Log command (without secrets)
    local logged_cmd=("${cmd[@]}")
    for i in "${!logged_cmd[@]}"; do
        if [[ "${logged_cmd[i]}" =~ ^(password|token|key|secret)= ]]; then
            logged_cmd[i]="****"
        fi
    done
    log_debug "Executing: ${logged_cmd[*]}"

    # Execute
    "${cmd[@]}"
}
```

## Configuration Security

### 1. SSH Hardening

```bash
# scripts/configure-system.sh

# SSH configuration
set_config_value "/etc/ssh/sshd_config" "PermitRootLogin" "no"
set_config_value "/etc/ssh/sshd_config" "PasswordAuthentication" "no"
set_config_value "/etc/ssh/sshd_config" "PubkeyAuthentication" "yes"
set_config_value "/etc/ssh/sshd_config" "PermitEmptyPasswords" "no"
set_config_value "/etc/ssh/sshd_config" "MaxAuthTries" "3"
set_config_value "/etc/ssh/sshd_config" "ClientAliveInterval" "300"
set_config_value "/etc/ssh/sshd_config" "ClientAliveCountMax" "2"
set_config_value "/etc/ssh/sshd_config" "LoginGraceTime" "60"
set_config_value "/etc/ssh/sshd_config" "X11Forwarding" "no"
set_config_value "/etc/ssh/sshd_config" "AllowAgentForwarding" "no"
set_config_value "/etc/ssh/sshd_config" "AllowTcpForwarding" "no"
```

### 2. Kernel Hardening

```bash
# Sysctl security settings
set_config_values /etc/sysctl.d/99-security.conf \
    "kernel.dmesg_restrict" "1" \
    "kernel.kptr_restrict" "2" \
    "kernel.perf_event_paranoid" "3" \
    "kernel.yama.ptrace_scope" "1" \
    "vm.mmap_rnd_bits" "32" \
    "vm.mmap_rnd_compat_bits" "16" \
    "net.ipv4.conf.all.rp_filter" "1" \
    "net.ipv4.conf.default.rp_filter" "1" \
    "net.ipv4.conf.all.accept_redirects" "0" \
    "net.ipv4.conf.default.accept_redirects" "0" \
    "net.ipv4.conf.all.send_redirects" "0" \
    "net.ipv4.conf.default.send_redirects" "0" \
    "net.ipv4.icmp_echo_ignore_broadcasts" "1" \
    "net.ipv4.icmp_ignore_bogus_error_responses" "1" \
    "net.ipv4.tcp_syncookies" "1"
```

### 3. Filesystem Hardening

```bash
# Mount options in /etc/fstab
# /dev/nvme0n1p2  /  ext4  defaults,noatime,nodev,nosuid  0 1
# /dev/nvme0n1p1  /boot  vfat  defaults,noatime,nodev,nosuid,noexec  0 2
# tmpfs  /tmp  tmpfs  defaults,noatime,nodev,nosuid,noexec,size=2G  0 0
```

### 4. Service Hardening

```bash
# Disable unnecessary services
disable_and_stop_service "cups"
disable_and_stop_service "bluetooth"
disable_and_stop_service "avahi-daemon"
disable_and_stop_service "ModemManager"
disable_and_stop_service "smb"
disable_and_stop_service "nfs-server"
```

## Runtime Security

### 1. Audit Logging

```bash
# Audit critical operations
audit_log() {
    local action="$1"
    local target="$2"
    local result="$3"

    logger -t linux-setup-script \
        "user=${USER} action=${action} target=${target} result=${result}"
}
```

### 2. Integrity Verification

```bash
# Verify critical files
verify_integrity() {
    local files=(
        "/etc/passwd"
        "/etc/shadow"
        "/etc/group"
        "/etc/gshadow"
        "/etc/ssh/sshd_config"
        "/etc/sudoers"
    )

    for file in "${files[@]}"; do
        if [ -f "${file}" ]; then
            # Check permissions
            local perms=$(stat -c %a "${file}")
            case "${file}" in
                /etc/shadow|/etc/gshadow)
                    [ "${perms}" = "640" ] || log_warn "${file} has weak permissions: ${perms}"
                    ;;
                /etc/ssh/sshd_config)
                    [ "${perms}" = "644" ] || log_warn "${file} has weak permissions: ${perms}"
                    ;;
                /etc/sudoers)
                    [ "${perms}" = "440" ] || log_warn "${file} has weak permissions: ${perms}"
                    ;;
            esac
        fi
    done
}
```

## Secret Management

### 1. Environment Variables

```bash
# Required secrets (set before run)
export GITHUB_TOKEN="ghp_xxx"
export GPG_PASSPHRASE="xxx"
export SSH_KEY_PASSPHRASE="xxx"

# Optional secrets
export DOCKER_HUB_TOKEN="xxx"
export AWS_ACCESS_KEY_ID="xxx"
```

### 2. Secret Masking in Logs

```bash
# Mask secrets in all log output
mask_secrets() {
    local message="$1"

    # Common secret patterns
    message=$(echo "${message}" | sed -E 's/(password|token|key|secret|passphrase)=[^ ]*/\1=****/gi')
    message=$(echo "${message}" | sed -E 's/(Authorization: Bearer )[^ ]*/\1****/gi')
    message=$(echo "${message}" | sed -E 's/(ssh-rsa|ssh-ed25519) [^ ]*/\1 ****/gi')

    echo "${message}"
}
```

### 3. Key Management

```bash
# SSH key generation with secure defaults
generate_ssh_key() {
    local email="$1"
    local type="${2:-ed25519}"
    local path="${3:-${HOME}/.ssh/id_${type}}"

    # Generate with strong KDF
    ssh-keygen -t "${type}" -a 100 -C "${email}" -f "${path}" -N ""

    # Set restrictive permissions
    chmod 600 "${path}"
    chmod 644 "${path}.pub"
}

# Add SSH key to agent (auto-detects best available agent)
add_ssh_key_to_agent() {
    local key_path="$1"

    # Prefer GCR ssh-agent (GNOME Keyring) if available
    if [[ -S "/run/user/$(id -u)/gcr/.ssh" ]]; then
        export SSH_AUTH_SOCK="/run/user/$(id -u)/gcr/.ssh"
    # Fall back to systemd ssh-agent socket if available
    elif [[ -S "${XDG_RUNTIME_DIR}/ssh-agent.socket" ]] || [[ -S "/run/user/$(id -u)/ssh-agent.socket" ]]; then
        export SSH_AUTH_SOCK="${XDG_RUNTIME_DIR}/ssh-agent.socket"
        [[ ! -S "${SSH_AUTH_SOCK}" ]] && export SSH_AUTH_SOCK="/run/user/$(id -u)/ssh-agent.socket"
    else
        eval "$(ssh-agent -s)"
    fi

    ssh-add "${key_path}"
}

# GPG key generation with secure defaults
generate_gpg_key() {
    local name="$1"
    local email="$2"
    local type="${3:-ed25519}"

    cat > /tmp/gpg-batch <<EOF
Key-Type: ${type}
Key-Curve: ed25519
Subkey-Type: ${type}
Subkey-Curve: cv25519
Name-Real: ${name}
Name-Email: ${email}
Expire-Date: 2y
%no-protection
%commit
EOF

    gpg --batch --generate-key /tmp/gpg-batch
    rm /tmp/gpg-batch
}
```

## Compliance

### 1. CIS Benchmarks

The repository aims to comply with CIS Benchmarks for:
- Linux (various distributions)
- Docker
- Kubernetes

### 2. STIG

Security Technical Implementation Guides considered for:
- RHEL/CentOS
- Ubuntu
- Debian

## Security Testing

### 1. Static Analysis

```bash
# ShellCheck for security issues
shellcheck --severity=error scripts/**/*.sh

# Check for common vulnerabilities
grep -r "eval\|exec\|source.*\$" scripts/ --include="*.sh"
```

### 2. Dynamic Analysis

```bash
# Run with shellcheck in CI
# Run with bats tests
# Run in isolated container
```

### 3. Dependency Scanning

```bash
# Check for vulnerable packages
# (Would integrate with osv-scanner, grype, etc.)
```

## Incident Response

### 1. Compromise Detection

```bash
# Check for unexpected changes
detect_changes() {
    local baseline="/var/lib/linux-setup-script/baseline"

    if [ -f "${baseline}" ]; then
        # Compare current state to baseline
        aide --check || log_warn "AIDE detected changes"
    fi
}
```

### 2. Recovery

```bash
# Restore from backup
restore_config() {
    local backup_dir="/var/backups/linux-setup-script"

    if [ -d "${backup_dir}" ]; then
        log_info "Restoring from backup..."
        rsync -av "${backup_dir}/" /
        log_success "Restore complete"
    else
        log_error "No backup found"
        return 1
    fi
}
```

## Security Checklist

### Development
- [ ] No secrets in code
- [ ] Input validation on all external data
- [ ] No command injection vulnerabilities
- [ ] Least privilege enforced
- [ ] Secure defaults for all configurations
- [ ] Audit logging for critical operations

### Deployment
- [ ] Signed releases
- [ ] Checksums published
- [ ] Verified package sources
- [ ] Minimal attack surface
- [ ] Rollback capability

### Operations
- [ ] Regular security updates
- [ ] Monitoring for anomalies
- [ ] Incident response plan
- [ ] Backup and recovery tested

## Future Enhancements

1. **Signed commits** — GPG-signed git commits
2. **Reproducible builds** — Bit-for-bit identical artifacts
3. **SBOM** — Software Bill of Materials
4. **Policy engine** — OPA/Rego for configuration validation
5. **Runtime monitoring** — Falco/auditd integration
6. **Zero-trust** — Mutual TLS for all communications