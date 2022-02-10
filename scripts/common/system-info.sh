#!/bin/bash
[[ "${BASH_SOURCE[0]}" == "${0}" ]] && source "scripts/common/common.sh"

function get_screen_width() {
    if does-bin-exist "xrandr"; then
        xrandr | grep -w connected | grep primary | sed 's/^.*primary \([0-9][0-9]*\)x.*/\1/g'
    elif does-bin-exist "xdpyinfo"; then
        xdpyinfo | grep "dimensions" | sed 's/^[^0-9]*\([0-9]\+\)x[0-9]\+ pixels.*/\1/g'
    else
        echo 0
    fi
}

function get_screen_width_millimetres() {
    if does-bin-exist "xrandr"; then
        xrandr | grep -w connected | grep primary | sed 's/.* \([0-9]\+\)mm x [0-9]\+mm.*/\1/g'
    elif does-bin-exist "xdpyinfo"; then
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
    if does-bin-exist "xrandr"; then
        xrandr | grep -w connected | grep primary | sed 's/^.*primary [0-9]\+x\([0-9]\+\).*/\1/g'
    elif does-bin-exist "xdpyinfo"; then
        xdpyinfo | grep "dimensions" | sed 's/^[^0-9]*[0-9]\+x\([0-9]\+\) pixels.*/\1/g'
    else
        echo 0
    fi
}

function get_screen_height_millimetres() {
    if does-bin-exist "xrandr"; then
        xrandr | grep -w connected | grep primary | sed 's/.* [0-9]\+mm x \([0-9]\+\)mm.*/\1/g'
    elif does-bin-exist "xdpyinfo"; then
        xdpyinfo | grep "dimensions" | sed 's/^.* pixels ([0-9]\+x\([0-9]\+\) mil.*/\1/g'
    else
        echo 0
    fi
}

function get_screen_dpi() {
    local RESOLUTION_H=$(get_screen_width)

    if [ "${RESOLUTION_H}" -eq 0 ] \
    || [ -z "${RESOLUTION_H}" ]; then
        if does-bin-exist "xdpyinfo"; then
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

    if does-bin-exist "uname"; then
        ARCH=$(uname -m)
    fi

    if [ -z "${ARCH}" ];then
        if does-bin-exist "lscpu"; then
            ARCH=$(lscpu | grep "Architecture" | awk -F: '{print $2}' | sed 's/  //g' | sed 's/^ *//g')
        else
            local CPU_FAMILY="$(get_cpu_family)"
            # We make some big assumptions here
            echo "${CPU_FAMILY}" | grep -q "AMD\|Intel" && ARCH="x86_64"
            echo "${CPU_FAMILY}" | grep -q "Broadcom" && ARCH="aarch64"
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

function get_cpu_model() {
    local CPU_MODEL=""

    if [ -f "${ROOT_PROC}/cpuinfo" ] && grep -q "^Hardware\s*:" "${ROOT_PROC}/cpuinfo"; then
        CPU_MODEL=$(cat "${ROOT_PROC}/cpuinfo" | \
            grep "^Hardware" | \
            awk -F: '{print $2}')
    elif does-bin-exist "lscpu"; then
        CPU_MODEL=$(lscpu | \
            grep "^Model name:" | \
            awk -F: '{print $2}')
    elif [ -f "${ROOT_PROC}/cpuinfo" ]; then
        CPU_MODEL=$(cat "${ROOT_PROC}/cpuinfo" | \
            grep "^model name" | \
            awk -F: '{print $2}')
    fi

    CPU_MODEL=$(echo "${CPU_MODEL}" | \
            head -n 1 | \
            sed 's/^\s*\(.*\)\s*$/\1/g' | \
            sed 's/(TM)//g' | \
            sed 's/(R)//g' | \
            sed 's/ [48][ -][Cc]ore//g' | \
            sed 's/ \(CPU\|Processor\)//g' | \
            sed 's/@ .*//g' | \
            sed 's/^[ \t]*//g' | \
            sed 's/[ \t]*$//g')

    echo "${CPU_MODEL}"  | sed 's/\(AMD\|Broadcom\|Intel\) //g'
}

function get_cpu_family() {
    local CPU_LINE=""
    local CPU_FAMILY=""

    if does-bin-exist "dmidecode" && [ -n "$(get_dmi_string processor-manufacturer)" ]; then
        CPU_LINE=$(get_dmi_string processor-manufacturer)
    elif [ -f "${ROOT_PROC}/cpuinfo" ] && grep -q "^Hardware\s*:" "${ROOT_PROC}/cpuinfo"; then
        CPU_LINE=$(cat "${ROOT_PROC}/cpuinfo" | grep "^Hardware")
    elif does-bin-exist "lscpu"; then
        CPU_LINE=$(lscpu | grep "^Model name:")
    elif [ -f "${ROOT_PROC}/cpuinfo" ]; then
        CPU_LINE=$(cat "${ROOT_PROC}/cpuinfo" | grep "^model name" | head -n 1)
    fi

    echo "${CPU_LINE}" | grep -q "AMD" && CPU_FAMILY="AMD"
    echo "${CPU_LINE}" | grep -q "BCM\|Broadcom" && CPU_FAMILY="Broadcom"
    echo "${CPU_LINE}" | grep -q "Intel" && CPU_FAMILY="Intel"

    echo "${CPU_FAMILY}"
}

function get_cpu() {
    echo "$(get_cpu_family) $(get_cpu_model)" | sed 's/^\s*//g'
}

function get_gpu_family() {
    local GPU_FAMILY=""

    if does-bin-exist "lspci" && [ -e "${ROOT_PROC}/bus/pci" ]; then
        local VGA_LINE=$(lspci | grep "VGA")
        echo "${VGA_LINE}" | grep -q "AMD"      && GPU_FAMILY="AMD"
        echo "${VGA_LINE}" | grep -q "Intel"    && GPU_FAMILY="Intel"
        echo "${VGA_LINE}" | grep -q "NVIDIA"   && GPU_FAMILY="Nvidia"
    fi

    if [ -z "${GPU_FAMILY}" ] && [ "${ARCH_FAMILY}" == "arm" ]; then
        GPU_FAMILY="$(get_cpu_family)"
    fi

    echo "${GPU_FAMILY}"
}

function get_gpu_model() {
    local GPU_MODEL=""

    if does-bin-exist "lspci" && [ -e "${ROOT_PROC}/bus/pci" ]; then
        lspci | grep VGA | tail -n 1 | sed \
            -e 's/^[^\[]*\[\([a-zA-Z0-9 ]*\)].*/\1/g' \
            -e 's/^00:0[0-9].[0-9] VGA compatible controller: //g' \
            -e 's/\(AMD\|Intel\|NVIDIA\)//g' \
            -e 's/Corporation//g' \
            -e 's/(rev [0-9][0-9])//g' \
            -e 's/^\s*//g' -e 's/\s*$//g'
    elif [ -z "${GPU_MODEL}" ] && [ "${ARCH_FAMILY}" == "arm" ]; then
        get_cpu_model
    fi
}

function get_gpu() {
    echo "$(get_gpu_family) $(get_gpu_model)" | sed 's/^\s*//g'
}

function get_driver() {
    local COMPONENT="${*}"

    DRIVER=$(does-bin-exist "lspci" && lspci -k 2> /dev/null | \
        grep "${COMPONENT}" | \
        grep "Kernel driver" | \
        awk -F":" '{print $2}' | \
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
    does-bin-exist "dmidecode" && run-as-su dmidecode -s "${KEY}" 2> /dev/null
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

    if does-bin-exist "uname" \
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
    local GPU_FAMILY="$(get_gpu_family)"
    local GPU_MODEL="$(get_gpu_model)"

    if [ "${GPU_FAMILY}" = "Nvidia" ]; then
        if [ "${GPU_MODEL}" = "GeForce 610M" ]; then
            return 0 # True
        fi
    fi

    return 1 # False
}
