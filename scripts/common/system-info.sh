#!/bin/bash
source "scripts/common/filesystem.sh"
source "${REPO_DIR}/scripts/common/common.sh"

function get_screen_width() {
    if does_bin_exist "xrandr"; then
        xrandr | grep -w connected | grep primary | sed 's/^.*primary \([0-9][0-9]*\)x.*/\1/g'
    elif does_bin_exist "xdpyinfo"; then
        xdpyinfo | grep "dimensions" | sed 's/^[^0-9]*\([0-9]\+\)x[0-9]\+ pixels.*/\1/g'
    else
        echo 0
    fi
}

function get_screen_width_millimetres() {
    if does_bin_exist "xrandr"; then
        xrandr | grep -w connected | grep primary | sed 's/.* \([0-9]\+\)mm x [0-9]\+mm.*/\1/g'
    elif does_bin_exist "xdpyinfo"; then
        xdpyinfo | grep "dimensions" | sed 's/^.* pixels (\([0-9]\+\)x[0-9]\+ mil.*/\1/g'
    else
        echo 0
    fi
}

function get_screen_width_inches() {
    local SCREEN_WIDTH_MM=$(get_screen_width_millimetres)
    echo "${SCREEN_WIDTH_MM}/10/2.54" | bc -l
}

function get_screen_height() {
    if does_bin_exist "xrandr"; then
        xrandr | grep -w connected | grep primary | sed 's/^.*primary [0-9]\+x\([0-9]\+\).*/\1/g'
    elif does_bin_exist "xdpyinfo"; then
        xdpyinfo | grep "dimensions" | sed 's/^[^0-9]*[0-9]\+x\([0-9]\+\) pixels.*/\1/g'
    else
        echo 0
    fi
}

function get_screen_height_millimetres() {
    if does_bin_exist "xrandr"; then
        xrandr | grep -w connected | grep primary | sed 's/.* [0-9]\+mm x \([0-9]\+\)mm.*/\1/g'
    elif does_bin_exist "xdpyinfo"; then
        xdpyinfo | grep "dimensions" | sed 's/^.* pixels ([0-9]\+x\([0-9]\+\) mil.*/\1/g'
    else
        echo 0
    fi
}

function get_screen_dpi() {
    local RESOLUTION_H=$(get_screen_width)

    if [ "${RESOLUTION_H}" -eq 0 ] \
    || [ -z "${RESOLUTION_H}" ]; then
        if does_bin_exist "xdpyinfo"; then
            xdpyinfo | grep "resolution" | sed 's/^[^0-9]*\([0-9]*\)x[0-9]*.*/\1/g'
        else
            echo 0
        fi

        return
    fi

    local RESOLUTION_H_INCHES=$(get_screen_width_inches)
    local DPI=$(echo "${RESOLUTION_H}/${RESOLUTION_H_INCHES}" | bc -l)

    echo "${DPI}" | awk '{print int($1+0.5)}' # Round to nearest
}

function get_arch() {
    local ARCH=""

    if does_bin_exist "uname"; then
        ARCH=$(uname -m)
    fi

    if [ -z "${ARCH}" ];then
        if does_bin_exist "lscpu"; then
            ARCH=$(lscpu | grep "Architecture" | awk -F: '{print $2}' | sed 's/  //g' | sed 's/^ *//g')
        else
            # We make some big assumptions here
            echo "${CPU_FAMILY}" | grep -q "AMD\|Intel" && ARCH="x86_64"
            echo "${CPU_FAMILY}" | grep -q "Broadcom" && ARCH="aarch64"
            echo "${CPU_FAMILY}" | grep -q "Qualcomm" && ARCH="aarch64"
        fi
    fi

    echo "${ARCH}"
}

function get_arch_family() {
    local ARCH=""

    if [ -n "${1}" ]; then
        ARCH="${1}"
    else
        ARCH="$(get_arch)"
    fi

    local ARCH_FAMILY=""

    [ "${ARCH}" = "i686" ]     && ARCH_FAMILY="x86"
    [ "${ARCH}" = "x86_64" ]   && ARCH_FAMILY="x86"
    [ "${ARCH}" = "aarch64" ]  && ARCH_FAMILY="arm"
    [ "${ARCH}" = "armv7h" ]   && ARCH_FAMILY="arm"
    [ "${ARCH}" = "armv7l" ]   && ARCH_FAMILY="arm"
    [ "${ARCH}" = "armv8h" ]   && ARCH_FAMILY="arm"
    [ "${ARCH}" = "armv8l" ]   && ARCH_FAMILY="arm"

    echo "${ARCH_FAMILY}"
}

function get_soc_name() {
    local MODEL=""

    if [ -z "${MODEL}" ] \
    && [ -f "${ROOT_PROC}/cpuinfo" ]; then
        MODEL=$(cat "${ROOT_PROC}/cpuinfo" | \
            grep "^Hardware\s*:" | \
            awk -F: '{print $2}')
    fi

    if [ -z "${MODEL}" ] \
    && [ -f "${ROOT_PROC}/cpuinfo" ]; then
        MODEL=$(cat "${ROOT_PROC}/cpuinfo" | \
            grep "^model name" | \
            awk -F: '{print $2}')
    fi

    if [ -z "${MODEL}" ] \
    && does_bin_exist "lspci"; then
        if lspci | grep -q "\sPCI bridge:.*BCM[0-9]\+\s"; then
            MODEL=$(lspci | \
                grep "\sPCI bridge:" | \
                head -n 1 | \
                sed 's/.*\(BCM[0-9]\+\).*/\1/g')
        fi
    fi

    if [ -z "${MODEL}" ] \
    && [ -f "${ROOT_PROC}/device-tree/model" ]; then
        local DEVICE_MODEL=$(cat -A "${ROOT_PROC}/device-tree/model")

        if echo "${DEVICE_MODEL}" | grep -q "Raspberry Pi 3"; then
            MODEL="BCM2837"
        elif echo "${DEVICE_MODEL}" | grep -q "Raspberry Pi 4"; then
            MODEL="BCM2711"
        fi
    fi

    MODEL=$(echo "${MODEL}" | \
            head -n 1 | sed \
                -e 's/ Technologies//g' \
                -e 's/\sInc\s//g' \
                -e 's/,//g' \
                -e 's/^\s*//g' \
                -e 's/\s*$//g' \
                -e 's/\s\+/ /g')

    echo "${MODEL}"
}

function get_soc_model() {
    if [ -n "${SOC_FAMILY}" ]; then
        get_soc_name | sed 's/'"${SOC_FAMILY}"'//g'
    else
        get_soc_name
    fi
}

function get_soc_family() {
    local VENDOR=""

    echo "${SOC_NAME}" | grep -q "BCM\|Broadcom" && VENDOR="Broadcom"
    echo "${SOC_NAME}" | grep -q "Qualcomm" && VENDOR="Qualcomm"

    echo "${VENDOR}"
}

function get_cpu_model() {
    local MODEL=""

    [[ "${SOC_MODEL}" == "BCM2835" ]] && MODEL="ARM1176JZF-S"
    [[ "${SOC_MODEL}" == "BCM2837" ]] && MODEL="Cortex-A53"
    [[ "${SOC_MODEL}" == "BCM2711" ]] && MODEL="Cortex-A73"
    [[ "${SOC_MODEL}" == "SDM660" ]] && MODEL="Kryo 260"

    if [ -z "${MODEL}" ] \
    && [ -f "${ROOT_PROC}/cpuinfo" ]; then
        MODEL=$(cat "${ROOT_PROC}/cpuinfo" | \
            grep "^Hardware\s*:" | \
            awk -F: '{print $2}')
    fi

    if [ -z "${MODEL}" ] \
    && [ -f "${ROOT_PROC}/cpuinfo" ]; then
        MODEL=$(cat "${ROOT_PROC}/cpuinfo" | \
            grep "^model name" | \
            awk -F: '{print $2}')
    fi

    if [ -z "${MODEL}" ] \
    && does_bin_exist "lspci"; then
        if lspci | grep -q "\sPCI bridge:.*BCM[0-9]\+\s"; then
            MODEL=$(lspci | \
                grep "\sPCI bridge:" | \
                head -n 1 | \
                sed 's/.*\(BCM[0-9]\+\).*/\1/g')
        fi
    fi

    if [ -z "${MODEL}" ] \
    && does_bin_exist "lscpu"; then
        MODEL=$(lscpu | \
            grep "^Model name:" | \
            awk -F: '{print $2}')
    fi

    MODEL=$(echo "${MODEL}" | \
            head -n 1 | sed \
                -e 's/(TM)//g' \
                -e 's/(R)//g' \
                -e 's/ Technologies//g' \
                -e 's/\sInc\s//g' \
                -e 's/ [48][ -][Cc]ore//g' \
                -e 's/ \(CPU\|Processor\)//g' \
                -e 's/@ .*//g' \
                -e 's/,//g' \
                -e 's/'"${CPU_FAMILY}"'//g' \
                -e 's/^\s*//g' \
                -e 's/\s*$//g' \
                -e 's/\s\+/ /g')

    echo "${MODEL}"
}

function get_cpu_vendor_from_line() {
    local CPU_LINE="${*}"
    local CPU_VENDOR=""

    echo "${CPU_LINE}" | grep -q "Advanced Micro Devices\|AMD" && CPU_VENDOR="AMD"
    echo "${CPU_LINE}" | grep -q "BCM\|Broadcom" && CPU_VENDOR="Broadcom"
    echo "${CPU_LINE}" | grep -q "Intel" && CPU_VENDOR="Intel"
    echo "${CPU_LINE}" | grep -q "Qualcomm" && CPU_VENDOR="Qualcomm"

    echo "${CPU_VENDOR}"
}

function get_cpu_family() {
    local CPU_LINE=""
    local VENDOR=""

    if does_bin_exist "dmidecode"; then
        CPU_LINE=$(get_dmi_string processor-manufacturer)
        VENDOR="$(get_cpu_vendor_from_line ${CPU_LINE})"
    fi

    if [ -z "${VENDOR}" ] \
    && [ -f "${ROOT_PROC}/cpuinfo" ]; then
        CPU_LINE=$(cat "${ROOT_PROC}/cpuinfo" | grep "^Hardware\s*:")
        VENDOR="$(get_cpu_vendor_from_line ${CPU_LINE})"
    fi

    if [ -z "${VENDOR}" ] \
    && [ -f "${ROOT_PROC}/cpuinfo" ]; then
        CPU_LINE=$(cat "${ROOT_PROC}/cpuinfo" | grep "^model name" | head -n 1)
        VENDOR="$(get_cpu_vendor_from_line ${CPU_LINE})"
    fi

    if [ -z "${VENDOR}" ] \
    && does_bin_exist "lspci"; then
        CPU_LINE=$(lspci | grep "\sPCI bridge:" | head -n 1)
        VENDOR="$(get_cpu_vendor_from_line ${CPU_LINE})"
    fi

    if [ -z "${VENDOR}" ] \
    && does_bin_exist "lscpu"; then
        CPU_LINE=$(lscpu | grep "^Model name:")
        VENDOR="$(get_cpu_vendor_from_line ${CPU_LINE})"
    fi

    [ -z "${VENDOR}" ] && VENDOR="${SOC_FAMILY}"

    echo "${VENDOR}"
}

function get_cpu() {
    echo "${CPU_FAMILY} ${CPU_MODEL}" | sed 's/^\s*//g'
}

function get_gpu_family() {
    local VENDOR=""

    if does_bin_exist "lspci" && [ -e "${ROOT_PROC}/bus/pci" ]; then
        local VGA_LINE=$(lspci | grep "VGA")
        echo "${VGA_LINE}" | grep -q "AMD"      && VENDOR="AMD"
        echo "${VGA_LINE}" | grep -q "Intel"    && VENDOR="Intel"
        echo "${VGA_LINE}" | grep -q "NVIDIA"   && VENDOR="Nvidia"
    fi

    if [ -z "${VENDOR}" ] && [ "${ARCH_FAMILY}" == "arm" ]; then
        VENDOR="${SOC_FAMILY}"
    fi

    [ -z "${VENDOR}" ] && VENDOR="${CPU_FAMILY}"

    echo "${VENDOR}"
}

function get_gpu_model() {
    local MODEL=""

    [[ "${SOC_MODEL}" == "BCM2835" ]] && MODEL="VideoCore IV"
    [[ "${SOC_MODEL}" == "BCM2837" ]] && MODEL="VideoCore IV"
    [[ "${SOC_MODEL}" == "BCM2711" ]] && MODEL="VideoCore VI"
    [[ "${SOC_MODEL}" == "SDM660" ]] && MODEL="Adreno 512"

    if [ -z "${MODEL}" ] \
    && does_bin_exist "lspci" \
    && [ -e "${ROOT_PROC}/bus/pci" ]; then
        MODEL=$(lspci | grep VGA | tail -n 1 | sed \
            -e 's/^[^\[]*\[\([a-zA-Z0-9 ]*\)].*/\1/g' \
            -e 's/^00:0[0-9].[0-9] VGA compatible controller: //g' \
            -e 's/\(AMD\|Intel\|NVIDIA\)//g' \
            -e 's/Corporation//g' \
            -e 's/(rev [0-9][0-9])//g' \
            -e 's/^\s*//g' \
            -e 's/\s*$//g')
    fi

    if [ -z "${MODEL}" ] \
    && [[ "${ARCH_FAMILY}" == "arm" ]]; then
        MODEL="$(get_cpu_model)"
    fi

    echo "${MODEL}"
}

function get_gpu() {
    echo "${GPU_FAMILY} ${GPU_MODEL}" | sed 's/^\s*//g'
}

function get_driver() {
    local COMPONENT="${*}"

    DRIVER=$(does_bin_exist "lspci" && lspci -k 2> /dev/null | \
        grep "${COMPONENT}" | \
        grep "Kernel driver" | \
        awk -F":" '{print $2}' | \
        tail -n 1 | \
        sed -e 's/^\s*//g' -e 's/\s*$//g')

    [ -z "${DRIVER}" ] && DRIVER="unknown"

    echo "${DRIVER}"
}

function is_driver_loaded() {
    local DRIVER="${*}"

    if [ -n "$(get_driver ${DRIVER})" ]; then
        return 0 # True
    else
        return 1 # False
    fi
}

function get_wifi_driver() {
    get_driver "wifi"
}

function get_audio_driver() {
    get_driver "snd"
}

function get_dmi_string() {
    local KEY="${*}"
    does_bin_exist "dmidecode" && run_as_su dmidecode -s "${KEY}" 2> /dev/null
}

function get_chassis_type() {
    local DMI_CHASSIS_TYPE="$(get_dmi_string chassis-type)"

    if [ "${DMI_CHASSIS_TYPE}" = "Notebook" ]; then
        echo "Laptop"
        return
    fi

    if [ -d "${ROOT_SYS}/module/battery" ] \
    && [ -d "${ROOT_PROC}/acpi/button/lid" ]; then
        echo "Laptop"
        return
    fi

    if [ "${DISTRO_FAMILY}" = "Android" ]; then
        echo "Phone"
        return
    fi

    if does_bin_exist "uname" \
    && uname -r | grep -q "raspberry\|rpi"; then
        echo "SBC"
        return
    fi

    if [ -f "${ROOT_PROC}/device-tree/model" ] \
    && grep -aq "Raspberry" "${ROOT_PROC}/device-tree/model"; then
        echo "SBC"
        return
    fi

    echo "Desktop"
}

function gpu_has_optimus_support() {
    if [ "${GPU_FAMILY}" = "Nvidia" ]; then
        if [ "${GPU_MODEL}" = "GeForce 610M" ]; then
            return 0 # True
        fi
    fi

    return 1 # False
}

# Distribution
KERNEL_VERSION=$(uname -r)

if [ -f "/etc/os-release" ]; then
    DISTRO=$(grep "^ID" "/etc/os-release" | tail -n 1 | awk -F'=' '{print $2}')
else
    DISTRO=$(echo "${KERNEL_VERSION}" | sed \
        -e 's/^[^-]*-//g' \
        -e 's/^[0-9][0-9]*-//g' \
        -e 's/raspberrypi-//g' \
        -e 's/-[0-9]*$//g' \
        -e 's/-[a-z0-9]*$//g')
fi

OS=$(uname -s)

if [ "${DISTRO}" = "arch" ] \
|| [ "${DISTRO}" = "ARCH" ]; then
    DISTRO="Arch Linux"
    DISTRO_FAMILY="Arch"
elif [ "${DISTRO}" = "debian" ]; then
    DISTRO="Debian"
    DISTRO_FAMILY="Debian"
elif [ "${DISTRO}" = "lineageos" ] || [ $(uname -a | grep -c "Android") -ge 1 ]; then
    DISTRO="LineageOS"
    DISTRO_FAMILY="Android"
    OS="Android"
fi

if [ "${OS}" = "CYGWIN_NT-10.0" ]; then
    DISTRO="Cygwin"
    DISTRO_FAMILY="Windows"
    OS="Windows"
fi

# Architecture
[ -z "${ARCH}" ] && ARCH="$(get_arch)"
[ -z "${ARCH_FAMILY}" ] && ARCH_FAMILY="$(get_arch_family ${ARCH})"
[ -z "${SOC_FAMILY}" ] && SOC_FAMILY="$(get_soc_family)"
[ -z "${SOC_MODEL}" ] && SOC_MODEL="$(get_soc_model)"
[ -z "${CPU_FAMILY}" ] && CPU_FAMILY="$(get_cpu_family)"
[ -z "${CPU_MODEL}" ] && CPU_MODEL="$(get_cpu_model)"
[ -z "${GPU_FAMILY}" ] && GPU_FAMILY="$(get_gpu_family)"
[ -z "${GPU_MODEL}" ] && GPU_MODEL="$(get_gpu_model)"

# System characteristics
CPU_MODEL="$(get_cpu_model)"

CHASSIS_TYPE="$(get_chassis_type)"
POWERFUL_PC=false
IS_DEVELOPMENT_DEVICE=false
IS_GENERAL_PURPOSE_DEVICE=true
IS_GAMING_DEVICE=false
HAS_GUI=true
HAS_SU_PRIVILEGES=true
HAS_EFI_SUPPORT=false

if [ "${CHASSIS_TYPE}" = "Phone" ]; then
    POWERFUL_PC=false
    IS_GENERAL_PURPOSE_DEVICE=true
    IS_GAMING_DEVICE=false
    HAS_GUI=true
    HAS_SU_PRIVILEGES=false
    HAS_EFI_SUPPORT=false
else
    if [ "${ARCH_FAMILY}" = "x86" ]; then
        if [ -n "${CPU_MODEL}" ] && [ $(echo ${CPU_MODEL} | grep -c "Atom") -le 1 ]; then
            POWERFUL_PC=true
        fi
    fi

    if ${POWERFUL_PC}; then
        if [ "${CPU_MODEL}" = "Ryzen 7 5800X" ]; then
            IS_GAMING_DEVICE=true
            HAS_GUI=true
        else
            IS_GAMING_DEVICE=false
        fi
    fi

    [ -d "${ROOT_SYS}/firmware/efi/efivars" ] && HAS_EFI_SUPPORT=true
fi

if [ -f "${ROOT_ETC}/systemd/system/display-manager.service" ]; then
    HAS_GUI=true
else
    case ${HOSTNAME} in
        *"PC")  HAS_GUI=true ;;
        *"Pi")  HAS_GUI=false ;;
        *"Top") HAS_GUI=true ;;
        *)      HAS_GUI=false ;;
    esac
fi

if ${HAS_GUI}; then
    if does_bin_exist "code" "code-oss" "codium" "com.visualstudio.code" \
    || does_bin_exist "dotnet"; then
        IS_DEVELOPMENT_DEVICE=true
    fi

    if does_bin_exist "steam" "com.valvesoftware.Steam"; then
        IS_GAMING_DEVICE=true
    fi
else
    IS_GENERAL_PURPOSE_DEVICE=false
fi

if does_bin_exist "sudo"; then
    if [ "${DISTRO_FAMILY}" = "Android" ]; then
        [ -f "/sbin/su" ] && HAS_SU_PRIVILEGES=true
    else
        HAS_SU_PRIVILEGES=true
    fi
else
    HAS_SU_PRIVILEGES=false
fi

[ "${UID}" -eq 0 ] && HAS_SU_PRIVILEGES=true
