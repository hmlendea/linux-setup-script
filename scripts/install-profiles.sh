#!/bin/bash
source "scripts/common/common.sh"

SYSTEM_PROFILES_DIRECTORY_PATH="${ROOT_ETC}/profile.d"

does-bin-exist "dotnet" && update-file-if-needed "profiles/dotnet.sh" "${SYSTEM_PROFILES_DIRECTORY_PATH}/dotnet.sh"
