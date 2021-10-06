#!/bin/bash

# Architecture
ARCH=$(lscpu | grep "Architecture" | awk -F: '{print $2}' | sed 's/  //g' | sed 's/^ *//g')

[ "${ARCH}" == "x86_64" ]   && ARCH_FAMILY="x86"
[ "${ARCH}" == "aarch64" ]  && ARCH_FAMILY="arm"
[ "${ARCH}" == "armv7l" ]   && ARCH_FAMILY="arm"
[ "${ARCH}" == "armv8l" ]   && ARCH_FAMILY="arm"

# Distribution
KERNEL_VERSION=$(uname -r)
DISTRO=$(echo "${KERNEL_VERSION}" | sed 's/^[0-9.]*-\([A-Za-z]*\).*$/\1/g')

if [ "${DISTRO}" == "lineageos" ] || [ $(uname -a | grep -c "Android") -ge 1 ]; then
    DISTRO_FAMILY="android"
fi

if [ "${DISTRO}" == "arch" ]; then
    DISTRO_FAMILY="arch"
fi

# Root partition mount point
ROOT_PATH=""
[ "${DISTRO_FAMILY}" == "android" ] && ROOT_PATH="/data/data/com.termux/files/usr"

ROOT_BIN="${ROOT_PATH}/bin"
ROOT_BOOT="${ROOT_PATH}/boot"
ROOT_ETC="${ROOT_PATH}/etc"
ROOT_LIB="${ROOT_PATH}/lib"
ROOT_OPT="${ROOT_PATH}/opt"
ROOT_PROC="${ROOT_PATH}/proc"
ROOT_SYS="${ROOT_PATH}/sys"
ROOT_USR="${ROOT_PATH}/usr"
ROOT_USR_BIN="${ROOT_USR}/bin"
ROOT_USR_LIB="${ROOT_USR}/lib"
ROOT_USR_SHARE="${ROOT_USR}/share"

# System characteristics
if [ -f "${ROOT_PROC}/cpuinfo" ]; then
    CPU_MODEL=$(cat "${ROOT_PROC}/cpuinfo" | \
        grep "^model name" | \
        awk -F: '{print $2}' | \
        sed 's/^ *//g' | \
        head -n 1 | \
        sed 's/(TM)//g' | \
        sed 's/(R)//g' | \
        sed 's/ CPU//g' | \
        sed 's/@ .*//g' | \
        sed 's/^[ \t]*//g' | \
        sed 's/[ \t]*$//g')
fi

CHASSIS_TYPE="Desktop"
POWERFUL_PC=false
GAMING_PC=false
HAS_GUI=false
IS_EFI=0
HAS_SU_PRIVILEGES=false

if [ -n "${CPU_MODEL}" ] && [ $(echo ${CPU_MODEL} | grep -c "Atom") -le 1 ]; then
    POWERFUL_PC=true
fi

if ${POWERFUL_PC}; then
    if [ "${CPU_MODEL}" == "Intel Core i7-3610QM" ]; then
        GAMING_PC=false
    elif [ -n "${CPU_MODE}" ]; then
        GAMING_PC=true
    fi
fi

if [ -d "${ROOT_SYS}/module/battery" ]; then
    CHASSIS_TYPE="Laptop"
elif [ "${DISTRO_FAMILY}" == "android" ]; then
    CHASSIS_TYPE="Phone"
fi

if [ -d "${ROOT_SYS}/firmware/efi/efivars" ]; then
	IS_EFI=1
fi

if [ -f "${ROOT_ETC}/systemd/system/display-manager.service" ] || \
   [[ "${HOSTNAME}" = *PC ]] || \
   [[ "${HOSTNAME}" = *Top ]]; then
    HAS_GUI=true

    if [ "${ARCH_FAMILY}" == "arm" ]; then
        POWERFUL_PC=false
    fi
fi

if [ -f "${ROOT_BIN}/sudo" ] ||
   [ -f "${ROOT_USR_BIN}/sudo" ]; then
    if [ "${DISTRO_FAMILY}" == "android" ]; then
        [ -f "/sbin/su" ] && HAS_SU_PRIVILEGES=true
    else
        HAS_SU_PRIVILEGES=true
    fi
fi

# Username and home directory
USER_REAL=${SUDO_USER}
[ ! -n "${USER_REAL}" ] && USER_REAL=${USER}

HOME_REAL=$(grep "${USER_REAL}" "${ROOT_PATH}/etc/passwd" 2>/dev/null | cut -f6 -d":")

if [ ! -d "${HOME_REAL}" ]; then
    if [ -d "/data/data/com.termux/files/home" ]; then
        HOME_REAL="/data/data/com.termux/files/home"
    else
        HOME_REAL="/home/${USER_REAL}"
    fi
fi
