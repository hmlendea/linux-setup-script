#!/bin/bash

source "scripts/common/common.sh"

function make-link-if-needed() {
    SOURCE_PATH="${1}"
    TARGET_PATH="${2}"

    TARGET_PATH_DIR=$(dirname "${TARGET_PATH}")

    if [ ! -e "${TARGET_PATH}" ]; then
        echo "Linking '${SOURCE_PATH}' to '${TARGET_PATH}'..."

        if [ -w "${TARGET_PATH_DIR}" ]; then
            ln -s "${SOURCE_PATH}" "${TARGET_PATH}"
        else
            run-as-su ln -s "${SOURCE_PATH}" "${TARGET_PATH}"
        fi
    fi
}

make-link-if-needed "/usr/share/dotnet" "/opt/dotnet"
