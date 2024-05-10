#!/bin/bash
function get_latest_github_release_assets() {
    local REPOSITORY="${1}"
    
    curl -Ls "https://api.github.com/repos/${REPOSITORY}/releases/latest" | \
        grep "browser_download_url" | \
        cut -d "\"" -f 4
}
