#!/bin/bash
export DOTNET_ROOT="/usr/share/dotnet"
DOTNET_VERSION="$(dotnet --version)"

export MSBuildSDKsPath="${DOTNET_ROOT}/sdk/${DOTNET_VERSION}/Sdks"

[[ "${PATH}" != *"${DOTNET_TOOLS_PATH}"* ]] && export PATH="${PATH}:${DOTNET_TOOLS_PATH}"

# Extract self-contained executables under HOME to avoid multi-user issues from using the default '/var/tmp'
[ -z "${DOTNET_BUNDLE_EXTRACT_BASE_DIR}" ] && export DOTNET_BUNDLE_EXTRACT_BASE_DIR="${XDG_CACHE_HOME:-"${HOME}"/.cache}/dotnet_bundle_extract"
