# Build and Deployment

This document describes the build process, packaging, and deployment
strategies for the linux-setup-script repository.

## Overview

The repository is a collection of shell scripts and configuration files
that don't require traditional compilation. "Build" refers to validation,
packaging, and distribution preparation.

## Build Process

### 1. Validation Phase

```bash
# Validate all shell scripts
validate_scripts() {
    log_section "Validating scripts"

    # ShellCheck
    log_info "Running ShellCheck..."
    shellcheck scripts/**/*.sh scripts/common/*.sh

    # shfmt
    log_info "Checking formatting..."
    shfmt -d scripts/**/*.sh scripts/common/*.sh

    # Bats tests
    log_info "Running tests..."
    bats tests/

    log_success "Validation complete"
}
```

### 2. Linting Rules

```bash
# .shellcheckrc
# ShellCheck configuration
exclude=SC1091  # Source following not found
exclude=SC2034  # Unused variable
exclude=SC2155  # Declare and assign separately
```

```bash
# .shfmtrc
# shfmt configuration
-i 4          # 4 space indentation
-ci           # Indent switch cases
-sr           # Redirect operators
-kp           # Keep column alignment
-fn           # Function name format
```

### 3. Syntax Validation

```bash
# Check bash syntax
check_syntax() {
    log_info "Checking bash syntax..."

    for script in scripts/**/*.sh scripts/common/*.sh; do
        bash -n "${script}" || {
            log_error "Syntax error in ${script}"
            return 1
        }
    done

    log_success "Syntax check passed"
}
```

## Packaging

### 1. Release Archive

```bash
# Create release archive
create_release() {
    local version="$1"
    local archive="linux-setup-script-${version}.tar.gz"

    log_info "Creating release archive: ${archive}"

    # Create temporary directory
    local temp_dir=$(mktemp -d)
    local release_dir="${temp_dir}/linux-setup-script-${version}"

    # Copy repository (excluding .git, tests, docs)
    rsync -av \
        --exclude='.git' \
        --exclude='tests' \
        --exclude='docs' \
        --exclude='*.md' \
        --exclude='*.txt' \
        --exclude='*.log' \
        . "${release_dir}/"

    # Create archive
    tar -czf "${archive}" -C "${temp_dir}" "linux-setup-script-${version}"

    # Generate checksums
    sha256sum "${archive}" > "${archive}.sha256"

    log_success "Release archive created: ${archive}"

    # Cleanup
    rm -rf "${temp_dir}"
}
```

### 2. Installation Package

```bash
# Create installation script
create_installer() {
    local version="$1"
    local installer="install-linux-setup-script-${version}.sh"

    cat > "${installer}" <<'EOF'
#!/bin/bash
# Linux Setup Script Installer
# Version: VERSION_PLACEHOLDER

set -euo pipefail

REPO_URL="https://github.com/user/linux-setup-script"
INSTALL_DIR="${HOME}/.local/share/linux-setup-script"

main() {
    echo "Installing Linux Setup Script..."

    # Clone repository
    git clone "${REPO_URL}" "${INSTALL_DIR}"

    # Run setup
    cd "${INSTALL_DIR}"
    ./run.sh

    echo "Installation complete!"
}

main "$@"
EOF

    # Replace version placeholder
    sed -i "s/VERSION_PLACEHOLDER/${version}/g" "${installer}"
    chmod +x "${installer}"

    log_success "Installer created: ${installer}"
}
```

## Deployment

### 1. GitHub Release

```bash
# Deploy to GitHub Releases
deploy_github() {
    local version="$1"
    local archive="linux-setup-script-${version}.tar.gz"

    log_info "Deploying to GitHub Releases..."

    # Create release
    gh release create "v${version}" \
        --title "Linux Setup Script v${version}" \
        --notes-file CHANGELOG.md \
        "${archive}" \
        "${archive}.sha256" \
        "install-linux-setup-script-${version}.sh"

    log_success "GitHub release created"
}
```

### 2. AUR Package

```bash
# PKGBUILD for AUR
create_aur_package() {
    local version="$1"
    local pkgdir="linux-setup-script-${version}"

    mkdir -p "${pkgdir}"

    cat > "${pkgdir}/PKGBUILD" <<EOF
# Maintainer: Your Name <email@example.com>
pkgname=linux-setup-script
pkgver=${version}
pkgrel=1
pkgdesc="Personal Linux system provisioning and configuration framework"
arch=('any')
url="https://github.com/user/linux-setup-script"
license=('MIT')
depends=('bash' 'git' 'curl' 'jq')
optdepends=(
    'pacman: Arch Linux package manager'
    'apt: Debian/Ubuntu package manager'
    'apk: Alpine Linux package manager'
    'pkg: Termux package manager'
    'flatpak: Flatpak support'
    'snapd: Snap support'
)
source=("https://github.com/user/linux-setup-script/releases/download/v\${pkgver}/linux-setup-script-\${pkgver}.tar.gz")
sha256sums=('SKIP')

package() {
    cd "\${srcdir}/linux-setup-script-\${pkgver}"

    # Install scripts
    install -dm755 "\${pkgdir}/usr/share/linux-setup-script"
    cp -r scripts data resources rc profiles "\${pkgdir}/usr/share/linux-setup-script/"

    # Install main script
    install -Dm755 run.sh "\${pkgdir}/usr/bin/linux-setup-script"

    # Install documentation
    install -dm755 "\${pkgdir}/usr/share/doc/linux-setup-script"
    cp -r docs/* "\${pkgdir}/usr/share/doc/linux-setup-script/"

    # Install license
    install -Dm644 LICENSE "\${pkgdir}/usr/share/licenses/\${pkgname}/LICENSE"
}
EOF

    # Generate .SRCINFO
    cd "${pkgdir}"
    makepkg --printsrcinfo > .SRCINFO

    log_success "AUR package created in ${pkgdir}"
}
```

### 3. Homebrew Formula

```bash
# Create Homebrew formula
create_homebrew_formula() {
    local version="$1"
    local formula="linux-setup-script.rb"

    cat > "${formula}" <<EOF
class LinuxSetupScript < Formula
  desc "Personal Linux system provisioning and configuration framework"
  homepage "https://github.com/user/linux-setup-script"
  url "https://github.com/user/linux-setup-script/releases/download/v#{version}/linux-setup-script-#{version}.tar.gz"
  sha256 "SHA256_PLACEHOLDER"
  license "MIT"

  depends_on "bash"
  depends_on "git"
  depends_on "curl"
  depends_on "jq"

  def install
    libexec.install "scripts", "data", "resources", "rc", "profiles"
    bin.install "run.sh" => "linux-setup-script"
    doc.install "docs"
  end

  test do
    system "#{bin}/linux-setup-script", "--version"
  end
end
EOF

    log_success "Homebrew formula created: ${formula}"
}
```

## CI/CD Pipeline

### 1. GitHub Actions Workflow

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y shellcheck shfmt bats

      - name: ShellCheck
        run: shellcheck scripts/**/*.sh scripts/common/*.sh

      - name: Check formatting
        run: shfmt -d scripts/**/*.sh scripts/common/*.sh

      - name: Syntax check
        run: |
          for script in scripts/**/*.sh scripts/common/*.sh; do
            bash -n "$script"
          done

      - name: Run tests
        run: bats tests/

  test-platforms:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        distro: [archlinux, debian, ubuntu, alpine]
    steps:
      - uses: actions/checkout@v4

      - name: Run in container
        run: |
          docker run --rm -v "${PWD}:/repo" "${distro}:latest" \
            /bin/bash -c "cd /repo && ./run.sh --dry-run"

  release:
    needs: [validate, test-platforms]
    if: github.event_name == 'push' && startsWith(github.ref, 'refs/tags/')
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Create release
        run: |
          VERSION="${GITHUB_REF#refs/tags/v}"
          ./scripts/create-release.sh "${VERSION}"

      - name: Deploy to GitHub
        run: |
          VERSION="${GITHUB_REF#refs/tags/v}"
          ./scripts/deploy-github.sh "${VERSION}"
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### 2. Release Script

```bash
# scripts/create-release.sh

#!/bin/bash
set -euo pipefail

VERSION="$1"

if [ -z "${VERSION}" ]; then
    echo "Usage: $0 <version>"
    exit 1
fi

# Validate version format
if ! [[ "${VERSION}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Invalid version format: ${VERSION}"
    exit 1
fi

# Run validation
./scripts/validate.sh

# Create release artifacts
./scripts/package-release.sh "${VERSION}"

echo "Release ${VERSION} prepared successfully"
```

## Versioning

### Semantic Versioning

```
MAJOR.MINOR.PATCH

MAJOR: Breaking changes (incompatible API)
MINOR: New features (backward compatible)
PATCH: Bug fixes (backward compatible)
```

### Version Sources

```bash
# Get version from git tags
get_version() {
    git describe --tags --abbrev=0 2>/dev/null || echo "0.0.0-dev"
}

# Get version from file
get_version_file() {
    cat VERSION 2>/dev/null || get_version
}
```

## Distribution Channels

| Channel | Method | Audience |
|---------|--------|----------|
| GitHub Releases | Direct download | All users |
| AUR | `yay -S linux-setup-script` | Arch users |
| Homebrew | `brew install linux-setup-script` | macOS/Linux users |
| Git clone | `git clone ...` | Developers |
| Installer script | `curl ... | bash` | Quick install |

## Deployment Checklist

### Pre-release
- [ ] All tests pass
- [ ] ShellCheck clean
- [ ] Formatting correct
- [ ] Documentation updated
- [ ] CHANGELOG updated
- [ ] Version bumped

### Release
- [ ] Tag created
- [ ] GitHub Release created
- [ ] Artifacts uploaded
- [ ] Checksums published
- [ ] AUR package updated
- [ ] Homebrew formula updated

### Post-release
- [ ] Installation tested
- [ ] Upgrade tested
- [ ] Rollback tested
- [ ] Announcement made

## Rollback Procedure

```bash
# Rollback to previous version
rollback() {
    local previous_version="$1"

    log_warn "Rolling back to ${previous_version}..."

    # Remove current installation
    rm -rf "${INSTALL_DIR}"

    # Install previous version
    ./install-linux-setup-script-${previous_version}.sh

    log_success "Rollback complete"
}
```

## Future Enhancements

1. **Signed releases** — GPG-signed artifacts
2. **SBOM generation** — Software Bill of Materials
3. **Reproducible builds** — Bit-for-bit identical archives
4. **Auto-update** — Built-in update mechanism
5. **Delta updates** — Incremental updates
6. **Multi-arch builds** — ARM, x86_64, RISC-V