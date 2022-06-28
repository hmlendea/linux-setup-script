#!/bin/bash
source "scripts/common/filesystem.sh"

GITCONFIG_LOCATION="${XDG_CONFIG_HOME}/git/config"
GITHUB_KEY_SETTINGS_PAGE="https://github.com/settings/keys"
SSH_CONFIG_FILE_PATH="${HOME}/.ssh/config"

function getGitConfigValue() {
    grep "^ *${1} *=" "${GITCONFIG_LOCATION}" | sed 's/ //g' | awk -F= '{print $2}'
}

EMAIL=$(getGitConfigValue "email")
KEY_FILE_NAME="github_${HOSTNAME}_id_ed25519"
KEY_FILE_PATH="${HOME}/.ssh/${KEY_FILE_NAME}"

if [ -f "${KEY_FILE_PATH}" ]; then
    echo "SSH key already present (${KEY_FILE_PATH})"
    exit 1
fi

echo "Generating new key (${KEY_FILE_PATH})..."

ssh-keygen \
    -C "${EMAIL}" \
    -t ed25519 \
    -f "${KEY_FILE_PATH}"

echo "Adding the SSH key to the agent..."
eval "$(ssh-agent -s)"
ssh-add "${KEY_FILE_PATH}"
echo "Host github.com" > "${SSH_CONFIG_FILE_PATH}"
echo "    User git" >> "${SSH_CONFIG_FILE_PATH}"
echo "    IdentityFile ${KEY_FILE_PATH}" >> "${SSH_CONFIG_FILE_PATH}"
chmod 600 "${SSH_CONFIG_FILE_PATH}"
ssh-add -l

if [ -f "/usr/bin/xclip" ]; then
    echo "Copying the key to the clipboard..."
    xclip -selection clipboard < "${KEY_FILE_PATH}.pub"
else
    echo "Please copy the key into the clipboard manually:"
    cat "${KEY_FILE_PATH}.pub"
    echo ""
fi

echo "Next you will need to register the key on your account..."
if [ -f "/usr/bin/xdg-open" ]; then
    echo "  Opening the GitHub key settings page..."
    xdg-open "${GITHUB_KEY_SETTINGS_PAGE}"
else
    echo "  Please open the following URL:"
    echo "  ${GITHUB_KEY_SETTINGS_PAGE}"
fi

echo "Once ready, press Enter to test the connection..."
read -r
ssh -T "git@github.com"
