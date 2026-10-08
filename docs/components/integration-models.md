# Integration Models Component

This document provides a deep dive into the integration models component,
which handles external service integrations, API clients, and platform-specific
integrations.

## Overview

**Location**: `scripts/common/github.sh`, `scripts/git/setup-gpg-key.sh`,
`scripts/git/setup-ssh-key.sh`, `scripts/configure-repositories.sh`

**Purpose**: GitHub integration, Git configuration, SSH/GPG key management,
and repository management.

**Consumers**: `run.sh` (Phase 4), `configure-repositories.sh`,
`update-repositories.sh`, `git/setup-gpg-key.sh`, `git/setup-ssh-key.sh`

## Core Functions

### 1. GitHub Integration

```bash
# Configure GitHub CLI
configure_github_cli

# Authenticate with GitHub
github_auth <token>

# Create repository
github_create_repo <name> [description] [private]

# Clone repository
github_clone_repo <owner> <repo> [destination]

# Fork repository
github_fork_repo <owner> <repo>

# Create pull request
github_create_pr <title> <body> <head> <base>

# List repositories
github_list_repos [owner]

# Get repository info
github_get_repo <owner> <repo>
```

### 2. Git Configuration

```bash
# Configure Git
configure_git

# Set Git user
set_git_user <name> <email>

# Set Git editor
set_git_editor <editor>

# Set Git signing key
set_git_signing_key <key_id>

# Configure Git aliases
configure_git_aliases

# Configure Git hooks
configure_git_hooks
```

### 3. SSH Key Management

```bash
# Generate SSH key
generate_ssh_key <email> [key_type] [key_path]

# Add SSH key to agent (auto-detects best available agent)
add_ssh_key_to_agent <key_path>

# Copy SSH key to clipboard
copy_ssh_key_to_clipboard <key_path>

# Test SSH connection
test_ssh_connection <host>

# Configure SSH config
configure_ssh_config <host> <user> <key_path>
```

**Agent Selection Priority:**
1. **GCR ssh-agent** (GNOME Keyring) — `/run/user/$(id -u)/gcr/.ssh` — Keys persist across logins
2. **systemd ssh-agent.socket** — `/run/user/$(id -u)/ssh-agent.socket` — Keys persist while session active
3. **File-based agent** — `~/.cache/ssh-agent.env` — Fallback for non-systemd systems

### 4. GPG Key Management

```bash
# Generate GPG key
generate_gpg_key <name> <email> [key_type]

# Export GPG public key
export_gpg_public_key <key_id>

# Export GPG private key
export_gpg_private_key <key_id>

# Import GPG key
import_gpg_key <key_file>

# Configure GPG for Git
configure_gpg_for_git <key_id>

# Test GPG signing
test_gpg_signing
```

### 5. Repository Management

```bash
# Add repository
add_repository <name> <url> [branch]

# Remove repository
remove_repository <name>

# Update repository
update_repository <name>

# List repositories
list_repositories

# Sync repositories
sync_repositories
```

## Integration Patterns

### Pattern 1: GitHub CLI Configuration

```bash
#!/bin/bash
source "scripts/common/common.sh"
source "scripts/common/github.sh"

# Check if GitHub CLI is installed
if command_exists gh; then
    # Authenticate if token available
    if [ -n "${GITHUB_TOKEN}" ]; then
        github_auth "${GITHUB_TOKEN}"
    fi
    
    # Configure GitHub CLI
    configure_github_cli
    
    # Set default protocol
    gh config set git_protocol ssh
    
    # Set default editor
    gh config set editor "code --wait"
fi
```

### Pattern 2: Git Configuration

```bash
#!/bin/bash
source "scripts/common/common.sh"
source "scripts/common/config.sh"

# Set Git user
set_git_user "John Doe" "john@example.com"

# Set Git editor
set_git_editor "code --wait"

# Configure Git aliases
configure_git_aliases

# Configure Git hooks
configure_git_hooks

# Set Git signing key if GPG available
if command_exists gpg; then
    local key_id=$(gpg --list-secret-keys --keyid-format=long | grep sec | head -1 | awk '{print $2}' | cut -d'/' -f2)
    if [ -n "${key_id}" ]; then
        set_git_signing_key "${key_id}"
    fi
fi
```

### Pattern 3: SSH Key Setup

```bash
#!/bin/bash
source "scripts/common/common.sh"
source "scripts/common/filesystem.sh"

# Generate SSH key if not exists
if [ ! -f "${HOME}/.ssh/id_ed25519" ]; then
    generate_ssh_key "john@example.com" "ed25519" "${HOME}/.ssh/id_ed25519"
fi

# Add to SSH agent
add_ssh_key_to_agent "${HOME}/.ssh/id_ed25519"

# Configure SSH config
configure_ssh_config "github.com" "git" "${HOME}/.ssh/id_ed25519"
configure_ssh_config "gitlab.com" "git" "${HOME}/.ssh/id_ed25519"

# Test connections
test_ssh_connection "github.com"
test_ssh_connection "gitlab.com"
```

### Pattern 4: GPG Key Setup

```bash
#!/bin/bash
source "scripts/common/common.sh"
source "scripts/common/filesystem.sh"

# Generate GPG key if not exists
if ! gpg --list-secret-keys --keyid-format=long | grep -q "sec"; then
    generate_gpg_key "John Doe" "john@example.com" "ed25519"
fi

# Get key ID
local key_id=$(gpg --list-secret-keys --keyid-format=long | grep sec | head -1 | awk '{print $2}' | cut -d'/' -f2)

# Configure GPG for Git
configure_gpg_for_git "${key_id}"

# Export public key for GitHub
export_gpg_public_key "${key_id}" > "${HOME}/.gnupg/public.key"
```

### Pattern 5: Repository Management

```bash
#!/bin/bash
source "scripts/common/common.sh"
source "scripts/common/github.sh"

# Add personal repositories
add_repository "dotfiles" "git@github.com:user/dotfiles.git" "main"
add_repository "scripts" "git@github.com:user/scripts.git" "main"
add_repository "projects" "git@github.com:user/projects.git" "main"

# Sync all repositories
sync_repositories
```

## Integration Models Invariants

1. **Idempotency** — All config writes use `update_file_if_distinct`
2. **Credential safety** — Keys never logged, tokens from environment
3. **Platform awareness** — Different configs for different platforms
4. **Privilege separation** — System config via `run_as_su`, user config directly
5. **No runtime templating** — Config files deployed verbatim
6. **Single source of truth** — Each setting derived in exactly one place

## Error Handling

| Operation | Failure Mode | Handling |
|-----------|--------------|----------|
| `github_auth` | Invalid token | Error message, returns 1 |
| `generate_ssh_key` | Key exists | Prompts for overwrite |
| `generate_gpg_key` | Key exists | Prompts for overwrite |
| `test_ssh_connection` | Connection failed | Error message, returns 1 |
| `configure_gpg_for_git` | GPG not available | Error message, returns 1 |

## Performance Considerations

- **Batch operations** — Multiple repos synced in parallel
- **Key caching** — SSH/GPG keys cached in agent
- **Minimal API calls** — GitHub CLI caches responses
- **Conditional setup** — Only configure if tools available

## Security Considerations

- **Key protection** — Private keys never exposed in logs
- **Token handling** — Tokens from environment variables only
- **Agent forwarding** — SSH agent forwarding disabled by default
- **Key rotation** — Support for key rotation workflows
- **Privilege separation** — System config via `run_as_su`

## Testing

### Unit Tests

```bash
function test_generate_ssh_key() {
    local temp_dir=$(mktemp -d)
    local key_path="${temp_dir}/id_test"
    
    generate_ssh_key "test@example.com" "ed25519" "${key_path}"
    assertTrue "SSH key generated" "[ -f ${key_path} ]"
    assertTrue "SSH public key generated" "[ -f ${key_path}.pub ]"
    
    rm -rf "${temp_dir}"
}

function test_set_git_user() {
    set_git_user "Test User" "test@example.com"
    assertEquals "user.name" "Test User" "$(git config --global user.name)"
    assertEquals "user.email" "test@example.com" "$(git config --global user.email)"
}
```

### Integration Tests

```bash
function test_github_integration() {
    if command_exists gh; then
        github_auth "${GITHUB_TOKEN}"
        assertTrue "GitHub authenticated" "gh auth status"
    fi
}

function test_git_configuration() {
    configure_git
    assertNotNull "user.name" "$(git config --global user.name)"
    assertNotNull "user.email" "$(git config --global user.email)"
}
```

## Future Enhancements

1. **Multi-account support** — Multiple GitHub/GitLab accounts
2. **SSH certificate auth** — SSH certificate-based authentication
3. **GPG key rotation** — Automated GPG key rotation
4. **Repository templates** — Repository creation from templates
5. **CI/CD integration** — GitHub Actions/GitLab CI integration
6. **Secret management** — Integration with secret managers