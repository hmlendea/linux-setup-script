#!/bin/bash
source "scripts/common/filesystem.sh"
source "${REPO_DIR}/scripts/common/common.sh"
source "${REPO_DIR}/scripts/common/package-management.sh"
source "${REPO_DIR}/scripts/common/service-management.sh"
source "${REPO_DIR}/scripts/common/system-info.sh"

DEVICE_MODEL="$(get_device_model)"

if [[ "${DEVICE_MODEL}" =~ 'Argon ONE Up' ]]; then
    DBUS_POLICY_FILE_PATH='/etc/dbus-1/system.d/org.freedesktop.UPower.BatteryArgon.conf'
    DAEMON_FILE_PATH="${ROOT_USR_LOCAL_BIN}/argon-one-up-daemon"
    SYSTEMD_UNIT_FILE="${ROOT_ETC}/systemd/system/argon-one-up-daemon.service"

    WAS_RUST_INSTALLED=$(is_native_package_installed 'rustc')
    WAS_CARGO_INSTALLED=$(is_native_package_installed 'cargo')

    if [ ! -f "${DBUS_POLICY_FILE_PATH}" ]; then
        run_as_su wget \
            'https://raw.githubusercontent.com/0x6e3078/argon-one-up-daemon/refs/heads/main/config/org.freedesktop.UPower.BatteryArgon.conf' \
            -O "${DBUS_POLICY_FILE_PATH}"
    
        run_as_su systemctl reload 'dbus'
    fi

    if [ ! -f "${DAEMON_FILE_PATH}" ]; then
        ! ${WAS_RUST_INSTALLED} && install_native_package 'rustc'
        ! ${WAS_CARGO_INSTALLED} && install_native_package 'cargo'

        WORKING_DIRECTORY="$(pwd)"
        [ ! -d "${LOCAL_INSTALL_TEMP_DIR}" ] && mkdir -p "${LOCAL_INSTALL_TEMP_DIR}"
        cd "${LOCAL_INSTALL_TEMP_DIR}"

        [ ! -d 'argon-one-up-daemon' ] && git clone 'https://github.com/0x6e3078/argon-one-up-daemon.git'
        cd 'argon-one-up-daemon'

        [ ! -f 'target/release/argon-one-up-daemon' ] && cargo build --release
        run_as_su cp "${LOCAL_INSTALL_TEMP_DIR}/argon-one-up-daemon/target/release/argon-one-up-daemon" "${DAEMON_FILE_PATH}"

        ! ${WAS_RUST_INSTALLED} && uninstall_native_package 'rustc'
        ! ${WAS_CARGO_INSTALLED} && uninstall_native_package 'cargo'
    fi

    if [ ! -f "${SYSTEMD_UNIT_FILE}" ]; then
        run_as_su wget \
            'https://raw.githubusercontent.com/0x6e3078/argon-one-up-daemon/refs/heads/main/config/argon-one-up-daemon.service' \
            -O "${SYSTEMD_UNIT_FILE}"

        enable_service 'argon-one-up-daemon'
    fi
fi
