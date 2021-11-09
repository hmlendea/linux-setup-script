#!/bin/bash

PUBRING_FILE_PATH="${HOME}/.gnupg/pubring.kbx"
GITHUB_KEY_ID_FILE_PATH="${HOME}/.gnupg/github_key_id.txt"
GITCONFIG_FILE_PATH="${HOME}/.gitconfig"

if [ -f "${PUBRING_FILE_PATH}" ] &&
   [ -f "${GITHUB_KEY_ID_FILE_PATH}" ]; then
    GITHUB_GPG_KEY_ID=$(<"${GITHUB_KEY_ID_FILE_PATH}")

    if [ -n "${GITHUB_GPG_KEY_ID}" ]; then
        echo "Found GitHub GPG Key: ${GITHUB_GPG_KEY_ID}"

        git config --global user.signingkey "${GITHUB_GPG_KEY_ID}"
        git config --global commit.gpgsign true

        sed -i 's/\t/    /g' "${GITCONFIG_FILE_PATH}"
    fi
fi
