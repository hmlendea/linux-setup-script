# GitHub API Reference

This document provides API reference for GitHub integration operations in the linux-setup-script repository.

## GitHub Release Functions

### get_github_latest_release

```bash
function get_github_latest_release() {
    local REPOSITORY="${1}"

    local RELEASE_JSON
    RELEASE_JSON=$(curl -s "https://api.github.com/repos/${REPOSITORY}/releases/latest")

    echo "${RELEASE_JSON}"
}
```

**Parameters:**
- `REPOSITORY` (string): GitHub repository (owner/repo)

**Returns:**
- JSON response from GitHub API

**Example:**
```bash
RELEASE_JSON=$(get_github_latest_release "vim/vim")
```

### get_github_latest_release_version

```bash
function get_github_latest_release_version() {
    local REPOSITORY="${1}"

    local RELEASE_JSON
    RELEASE_JSON=$(get_github_latest_release "${REPOSITORY}")

    local VERSION
    VERSION=$(echo "${RELEASE_JSON}" | jq -r '.tag_name')

    echo "${VERSION}"
}
```

**Parameters:**
- `REPOSITORY` (string): GitHub repository (owner/repo)

**Returns:**
- Latest release version tag

**Example:**
```bash
VERSION=$(get_github_latest_release_version "vim/vim")
```

### get_github_latest_release_asset

```bash
function get_github_latest_release_asset() {
    local REPOSITORY="${1}"
    local FILTER="${2}"

    local RELEASE_JSON
    RELEASE_JSON=$(get_github_latest_release "${REPOSITORY}")

    local DOWNLOAD_URLS
    DOWNLOAD_URLS=$(echo "${RELEASE_JSON}" | jq -r '.assets[] | .browser_download_url')

    if [ -n "${FILTER}" ]; then
        echo "${DOWNLOAD_URLS}" | grep "${FILTER}"
    else
        echo "${DOWNLOAD_URLS}"
    fi
}
```

**Parameters:**
- `REPOSITORY` (string): GitHub repository (owner/repo)
- `FILTER` (string): Filter pattern for asset URLs (optional)

**Returns:**
- Download URLs matching filter

**Example:**
```bash
URL=$(get_github_latest_release_asset "vim/vim" "amd64.deb")
```

## GitHub Authentication

### setup_github_cli

```bash
function setup_github_cli() {
    if ! does_bin_exist 'gh'; then
        log_error "GitHub CLI not installed"
        return 1
    fi

    if ! gh auth status >/dev/null 2>&1; then
        log_info "GitHub CLI not authenticated"
        return 1
    fi

    return 0
}
```

**Returns:**
- `0` if GitHub CLI is authenticated
- `1` if not authenticated or not installed

**Example:**
```bash
if setup_github_cli; then
    echo "GitHub CLI ready"
fi
```

## GitHub Repository Operations

### clone_github_repo

```bash
function clone_github_repo() {
    local REPOSITORY="${1}"
    local TARGET_DIR="${2}"

    if does_directory_exist "${TARGET_DIR}"; then
        log_info "Repository already cloned: ${TARGET_DIR}"
        return 0
    fi

    git clone "https://github.com/${REPOSITORY}.git" "${TARGET_DIR}"

    return $?
}
```

**Parameters:**
- `REPOSITORY` (string): GitHub repository (owner/repo)
- `TARGET_DIR` (string): Target directory

**Returns:**
- `0` on success
- Non-zero on failure

**Example:**
```bash
clone_github_repo "vim/vim" "${HOME}/src/vim"
```

### update_github_repo

```bash
function update_github_repo() {
    local REPO_DIR="${1}"

    if ! does_directory_exist "${REPO_DIR}"; then
        log_error "Repository directory not found: ${REPO_DIR}"
        return 1
    fi

    cd "${REPO_DIR}"
    git pull

    return $?
}
```

**Parameters:**
- `REPO_DIR` (string): Repository directory

**Returns:**
- `0` on success
- Non-zero on failure

**Example:**
```bash
update_github_repo "${HOME}/src/vim"
```

## GitHub Gist Operations

### create_github_gist

```bash
function create_github_gist() {
    local FILE="${1}"
    local DESCRIPTION="${2}"
    local PUBLIC="${3}"

    if ! setup_github_cli; then
        return 1
    fi

    local VISIBILITY="--public"
    if [ "${PUBLIC}" != "true" ]; then
        VISIBILITY="--secret"
    fi

    gh gist create "${FILE}" --desc "${DESCRIPTION}" ${VISIBILITY}

    return $?
}
```

**Parameters:**
- `FILE` (string): File to upload
- `DESCRIPTION` (string): Gist description
- `PUBLIC` (string): "true" for public, "false" for secret

**Returns:**
- `0` on success
- Non-zero on failure

**Example:**
```bash
create_github_gist "/path/to/file" "My gist" "true"
```

## Error Handling

All GitHub functions follow consistent error handling:

- Return 0 on success, non-zero on failure
- Log errors with `log_error`
- Handle network errors gracefully
- Continue on non-critical failures

## See Also

- [components/integration-models.md](../components/integration-models.md) — Integration models
- [components/foundation-layer.md](../components/foundation-layer.md) — Foundation layer details
- [flows/git-setup.md](../flows/git-setup.md) — Git setup flow