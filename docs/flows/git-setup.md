# Git Setup Flow

This document describes the complete git setup process including configuration, SSH/GPG key management, and GitHub integration.

## Overview

The git setup flow configures git for the user, sets up SSH and GPG keys, and integrates with GitHub. This is executed during Phase 3 (User Configuration) of the main provisioning process.

## Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    Git Setup Flow                               │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Git Configuration                          │
│  • Configure global git settings                              │
│  • Set up SSH key                                             │
│  • Set up GPG key                                             │
│  • Configure GitHub CLI                                       │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    GitHub Integration                         │
│  • Configure GitHub CLI                                       │
│  • Set up GitHub authentication                               │
│  • Configure SSH for GitHub                                   │
└─────────────────────────────────────────────────────────────────┘
```

## Git Configuration

### Script: `scripts/configure-git.sh`

```bash
#!/bin/bash
set -euo pipefail

# Load foundation
source "${REPO_DIR}/scripts/common/common.sh"
source "${REPO_DIR}/scripts/common/filesystem.sh"

configure_git() {
    log_section "Git Configuration"

    # Set git config
    configure_global_git
    configure_ssh_key
    configure_gpg_key
    configure_github_cli

    log_success "Git configuration complete"
}

configure_global_git() {
    log_subsection "Global Git Configuration"

    # Set git user
    git config --global user.name "${GIT_USER:-User}"
    git config --global user.email "${GIT_EMAIL:-user@example.com}"

    # Set core editor
    git config --global core.editor "vim"

    # Enable color output
    git config --global color.ui auto

    # Set file format
    git config --global i18n.commitencoding utf-8

    # Set default branch name
    git config --global init.defaultBranch main

    # Set credential helper
    if command_exists gnome-keyring; then
        git config --global credential.helper gnome-keyring
    elif command_exists kwalletcli; then
        git config --global credential.helper kwalletcli
    elif command_exists pass; then
        git config --global credential.helper pass
    else
        git config --global credential.helper manager-core
    fi

    # Set merge tool
    git config --global merge.tool vimdiff
    git config --global mergetool vimdiff

    # Set diff tool
    git config --global diff.tool vimdiff

    log_info "Global git configuration set"
}

configure_ssh_key() {
    log_subsection "SSH Key Management"

    local ssh_dir="${HOME}/.ssh"
    ensure_directory "${ssh_dir}"
    chmod 700 "${ssh_dir}"

    # Check if SSH key already exists
    if [ -f "${ssh_dir}/id_ed25519" ]; then
        log_info "SSH key already exists: ${ssh_dir}/id_ed25519"
        return 0
    fi

    # Generate SSH key if missing
    log_info "Generating SSH key..."
    ssh-keygen -t ed25519 -C "${GIT_EMAIL:-user@example.com}" -f "${ssh_dir}/id_ed25519" -N ""

    # Add to ssh-agent
    if command_exists ssh-agent; then
        eval "$(ssh-agent -s)"
        ssh-add "${ssh_dir}/id_ed25519"
        log_info "SSH key added to agent"
    fi

    # Display public key
    if [ -f "${ssh_dir}/id_ed25519.pub" ]; then
        log_info "Public key:"
        cat "${ssh_dir}/id_ed25519.pub"
        log_info "Add this key to your GitHub account"
    fi
}

configure_gpg_key() {
    log_subsection "GPG Key Management"

    # Check if GPG key exists
    if gpg --list-keys "${GIT_EMAIL:-user@example.com}" &>/dev/null; then
        log_info "GPG key already exists for ${GIT_EMAIL:-user@example.com}"
        return 0
    fi

    # Generate GPG key
    log_info "Generating GPG key..."
    gpg --full-generate-key <<EOF
    Key type: (1) RSA and RSA (default)
    Key size: 4096
    Expiration: 0
    Real name: User
    Email address: ${GIT_EMAIL:-user@example.com}
    Comment:
    Passphrase:
    Repeat passphrase:
    EOF

    log_info "GPG key generated"
}

configure_github_cli() {
    log_subsection "GitHub CLI Configuration"

    # Check if GitHub CLI is installed
    if ! command_exists gh; then
        log_warn "GitHub CLI (gh) not found, installing..."
        install_github_cli
    fi

    # Authenticate GitHub CLI
    if ! gh auth status &>/dev/null; then
        log_info "Authenticating GitHub CLI..."
        gh auth login --with-token < <(gh auth token)
    else
        log_info "GitHub CLI already authenticated"
    fi

    # Configure SSH for GitHub
    if [ -f "${HOME}/.ssh/id_ed25519.pub" ]; then
        log_info "Adding SSH key to GitHub"
        gh auth login --ssh
    fi

    log_success "GitHub CLI configured"
}

install_github_cli() {
    log_info "Installing GitHub CLI..."

    if command_exists curl; then
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
            sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | \
            sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
        sudo apt update
        sudo apt install gh -y
    elif command_exists pacman; then
        sudo pacman -S --noconfirm github-cli
    elif command_exists flatpak; then
        flatpak install flathub com.github.cli -y
    else
        log_error "Unsupported package manager, cannot install GitHub CLI"
        return 1
    fi

    log_info "GitHub CLI installed"
}
```

## SSH Key Management

### Key Generation

```bash
# Generate SSH key (ed25519 recommended)
ssh-keygen -t ed25519 -C "user@example.com" -f ~/.ssh/id_ed25519 -N ""

# Generate RSA key (if ed25519 not available)
ssh-keygen -t rsa -b 4096 -C "user@example.com" -f ~/.ssh/id_rsa -N ""
```

### SSH Config

```bash
# Add to ~/.ssh/config
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
```

### GitHub SSH Setup

```bash
# Add SSH key to GitHub
gh auth login --ssh
# Or manually:
cat ~/.ssh/id_ed25519.pub | pbcopy  # macOS
cat ~/.ssh/id_ed25519.pub | xclip -selection clipboard  # Linux
# Then paste into GitHub website
```

## GPG Key Management

### Key Generation

```bash
# Generate GPG key
gpg --full-generate-key
# Select RSA and RSA, 4096 bits, no expiration, your name/email
```

### Git GPG Signing

```bash
# Configure git to sign commits
git config --global user.signingkey <KEY_ID>
git config --global commit.gpgsign true
```

## GitHub CLI Setup

### Authentication

```bash
# Login with token
gh auth login --with-token < <(gh auth token)

# Or use SSH
gh auth login --ssh
```

### Repository Setup

```bash
# Clone with SSH
gh repo clone owner/repo

# Or HTTPS with token
gh repo clone https://github.com/owner/repo.git
# Then set credential helper
git config --global credential.helper store
```

## Error Handling

### Common Issues

| Issue | Solution |
|-------|----------|
| SSH key not found | Generate key with `ssh-keygen` |
| GPG key not found | Generate with `gpg --full-generate-key` |
| GitHub CLI not installed | Install via `gh auth login` or package manager |
| Permission denied | Ensure SSH key has correct permissions (700 for .ssh, 600 for keys) |
| Authentication failed | Re-run `gh auth login` |

## Logging

### Git Setup Log

```
=== Git Configuration ===
[INFO] Setting global git configuration
[INFO] Setting user.name: User
[INFO] Setting user.email: user@example.com
[INFO] Setting core.editor: vim
[INFO] Setting color.ui: auto
[INFO] Setting credential.helper: manager-core
[INFO] SSH key generation started
[INFO] Generating SSH key: /home/user/.ssh/id_ed25519
[INFO] SSH key added to agent
[INFO] Public key displayed
[INFO] GPG key generation started
[INFO] GPG key created for user@example.com
[INFO] GitHub CLI configuration started
[INFO] GitHub CLI already authenticated
[INFO] SSH key added to GitHub
[SUCCESS] Git configuration complete
```

## Performance

### Typical Execution Time

- Git configuration: 1-2 seconds
- SSH key generation: 2-5 seconds (if new)
- GPG key generation: 5-10 seconds (interactive)
- GitHub CLI setup: 1-3 seconds
- **Total**: 10-20 seconds

### Optimisation

- Skip existing configurations
- Batch key generation
- Use cached credentials when possible