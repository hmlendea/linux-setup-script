#!/bin/bash
source "scripts/common/common.sh"

function create-file-if-not-exists() {
    local FILE_PATH="${*}"

    [ -z "${FILE_PATH}" ] && return
    [ -f "${FILE_PATH}" ] && return

    local DIRECTORY_PATH="$(dirname ${FILE_PATH})"

    mkdir -p "${DIRECTORY_PATH}"
    touch "${FILE_PATH}"
}

function set_config_value() {
    local SEPARATOR="="

    if [[ "${1}" == "--separator" ]]; then
        shift
        SEPARATOR="${1}"
        shift
    fi

    local FILE_PATH="${1}"
    local KEY="${2}"
    local VALUE_RAW="${@:3}"

    create-file-if-not-exists "${FILE_PATH}"

    #local VALUE=$(echo "${VALUE_RAW}" | sed -e 's/[]\/$*.^|[]/\\&/g')
    local VALUE="${VALUE_RAW}"
    local FILE_CONTENT=""

    FILE_CONTENT=$(read-file "${FILE_PATH}")

    # If the value is not already set
    if [[ $(grep -c "^${KEY}${SEPARATOR}${VALUE}$" <<< "$FILE_CONTENT") == 0 ]]; then
        # If the config key already exists (with a different value)
        if [ $(grep -c "^${KEY}${SEPARATOR}.*$" <<< "$FILE_CONTENT") -gt 0 ]; then
            if [ -w "${FILE_PATH}" ]; then
                sed -i 's|^'"${KEY}${SEPARATOR}"'.*$|'"${KEY}${SEPARATOR}${VALUE}"'|g' "${FILE_PATH}"
            else
                sudo sed -i 's|^'"${KEY}${SEPARATOR}"'.*$|'"${KEY}${SEPARATOR}${VALUE}"'|g' "${FILE_PATH}"
            fi
        else
            file-append-line "${FILE_PATH}" "${KEY}${SEPARATOR}${VALUE}"
        fi

        echo "${FILE_PATH} >>> ${KEY}${SEPARATOR}${VALUE}"
    fi
}

function set_firefox_config_string() {
    set_firefox_config "${1}" "${2}" "\"${*:3}\""
}

function set_firefox_config() {
    PROFILE="${1}"
    KEY="${2}"
    VALUE_RAW="${@:3}"

    FILE="${HOME_REAL}/.mozilla/firefox/${PROFILE}/prefs.js"

    create-file-if-not-exists "${FILE_PATH}"

    VALUE=$(echo "${VALUE_RAW}" | sed -e 's/[]\/$*.^|[]/\\&/g')
    FILE_CONTENT=$(cat "${FILE}")

    # If the value is not already set
    if [[ $(grep -c "^user_pref(\"${KEY}\", *${VALUE});$" <<< "${FILE_CONTENT}") == 0 ]] && \
       [[ $(grep -c "^user_pref(\"${KEY}\", *\"${VALUE}\");$" <<< "${FILE_CONTENT}") == 0 ]]; then
        # If the config key already exists (with a different value)
        if [ $(grep -c "^user_pref(\"${KEY}.*$" <<< "${FILE_CONTENT}") -gt 0 ]; then
            sed -i '/^user_pref('"\"${KEY}"'/d' "${FILE}"
        fi

        file-append-line "${FILE}" "user_pref(\"${KEY}\", ${VALUE});"

        echo "${FILE} >>> ${KEY} = ${VALUE}"
    fi
}

function set_json_value() {
    local FILE_PATH="${1}"

    ( ! does-bin-exist "jq") && return
    [ ! -f "${FILE_PATH}" ] && return

    local PROPERTY="${2}"
    local VALUE=$(echo "${@:3}" | sed -e 's/[]\/$*.^|[]/\\&/g')

    local FILE_CONTENT=$(cat "${FILE_PATH}" | grep -v "^[ \t]*//" | tr -d '\n' | sed 's/,[ \t]*}/ }/g')
    local CURRENT_VALUE=$(jq "${PROPERTY}" <<< ${FILE_CONTENT})

    VALUE=$(echo "${VALUE}" | sed 's/\\\././g') # dirty fix

    if [ "${VALUE}" != "false" ] && [ "${VALUE}" != "true" ] && \
       ! [[ ${VALUE} =~ ^[0-9]+([.][0-9]+)?$ ]]; then
        VALUE="\"${VALUE}\""
    fi

    # If the value is not already set
    if [ "${VALUE}" != "${CURRENT_VALUE}" ]; then
        jq "${PROPERTY}"'='"${VALUE}" <<< ${FILE_CONTENT} > "${FILE_PATH}"
        echo "${FILE_PATH} >>> ${PROPERTY}=${VALUE}"
    fi
}

function set_json_value_root() {
    if ${HAS_SU_PRIVILEGES}; then
        local FUNCTION_DECLARATIONS="$(declare -f set_json_value); $(declare -f does-bin-exist)"
        sudo bash -c "${FUNCTION_DECLARATIONS}; set_json_value \"${1}\" '${2}' \"${3}\""
    fi
}

function set_xml_node() {
    FILE="${1}"
    NODE_RAW="${2}"
    VALUE_RAW="${@:3}"

    (! does-bin-exist "xmlstarlet") && return
    [ ! -f "${FILE}" ] && return

    NAMESPACE=$(cat "${FILE}" | grep "xmlns=" | sed 's/.*xmlns=\"\([^\"]*\)\".*/\1/g')
    VALUE=$(echo "${VALUE_RAW}" | sed -e 's/[]\/$*.^|[]/\\&/g')

    if [ -z "${NAMESPACE}" ]; then
        NODE=${NODE_RAW}
    else
        NODE=$(echo "${NODE_RAW}" | sed 's/\/\([^\/]\)/\/x:\1/g')
    fi

    OLD_VALUE=$(xmlstarlet sel -N x="${NAMESPACE}" -t -v ''"${NODE}"'' -n "${FILE}")

    if [ "${VALUE}" != "${OLD_VALUE}" ]; then
        echo "${FILE} >>> ${NODE_RAW} = ${VALUE}"
        xmlstarlet ed -L -N x="${NAMESPACE}" -u ''"${NODE}"'' -v ''"${VALUE}"'' "${FILE}"
    fi
}

function set_modprobe_option() {
    FILE="${ROOT_ETC}/modprobe.d/hori-system-config.conf"
    MODULE="${1}"
    KEY="${2}"
    VALUE="${3}"

    FILE_CONTENT=$(cat "${FILE}")

    # If the option is not already set
    if [[ $(grep -c "^options ${MODULE} ${KEY}=${VALUE}$" <<< "${FILE_CONTENT}") == 0 ]]; then
        # If the option key already exists (with a different value)
        if [ $(grep -c "^options ${MODULE} ${KEY}=.*$" <<< "${FILE_CONTENT}") -gt 0 ]; then
            sed -i 's|^options '"${MODULE} ${KEY}"'=.*$|options '"${MODULE} ${KEY}"'='"${VALUE}"'|g' "${FILE}"
        else
            file-append-line "${FILE}" "options ${MODULE} ${KEY}=${VALUE}"
        fi

        echo "${FILE} >>> ${KEY}=${VALUE}"
    fi
}

function get_gsetting() {
    SCHEMA="${1}"
    PROPERTY="${2}"

    (! $(does-bin-exist "gsettings")) && return

    echo $(gsettings get "${SCHEMA}" "${PROPERTY}" | sed "s/^'\(.*\)'$/\1/g")
}

function set_gsetting() {
    SCHEMA="${1}"
    PROPERTY="${2}"
    VALUE="${@:3}"

    (! does-bin-exist "gsettings") && return

    CURRENT_VALUE=$(get_gsetting "${SCHEMA}" "${PROPERTY}")

    if [ "${CURRENT_VALUE}" != "${VALUE}" ] && \
       [ "${CURRENT_VALUE}" != "'${VALUE}'" ]; then
        echo "GSettings >>> ${SCHEMA}.${PROPERTY}=${VALUE}"
        gsettings set "${SCHEMA}" "${PROPERTY}" "${VALUE}"
    fi
}

function set_launcher_entries() {
    local FILE="${1}"
    shift

    if [ "$(( $# % 2))" -ne 0 ]; then
        echo "ERROR: Invalid arguments (count: $#) for set_launcher_entries: ${*}" >&2
        exit 1
    fi

    local PAIRS_COUNT=$(($# / 2))

    if [ ! -f "${FILE}" ]; then
        return
    fi

    for I in $(seq 1 ${PAIRS_COUNT}); do
        local KEY="${1}" && shift
        local VAL="${1}" && shift

        if [ -n "${KEY}" ] && [ -n "${VAL}" ]; then
            set_launcher_entry "${FILE}" "${KEY}" "${VAL}"
        fi
    done
}

function set_launcher_entry() {
    local FILE="${1}"
    local KEY="${2}"
    local VAL="${*:3}"

    if [ "$#" != "3" ]; then
        echo "ERROR: Invalid arguments (count: $#) for set_launcher_entry: ${*}" >&2
    fi

    if [ ! -f "${FILE}" ]; then
        return
    fi

    if [ ! -x "${FILE}" ]; then
        chmod +x "${FILE}"
    fi

    local KEY_ID=$(echo "${KEY}" | sed -e 's/^\([^\[]*\).*/\1/g' -e 's/\s//g')
    local KEY_LANGUAGE=$(echo "${KEY}" | sed -e 's/^'"${KEY_ID}"'//g' -e 's/\s//g' -e 's/^.\(.*\).$/\1/g')

    if [ "${KEY_ID}" != "FullName" ]; then
        local KEY_ESC="${KEY}"
        local VAL_ESC="${VAL}"

        local FILE_CONTENTS=""
        local HAS_MULTIPLE_SECTIONS=false
        local LAST_SECTION_LINE=-1

        KEY_ESC=$(echo "${KEY}" | sed -e 's/[]\/$*.^|[]/\\&/g')
        VAL_ESC=$(echo "${VAL}" | sed -e 's/[]\/$*.^|[]/\\&/g')

        FILE_CONTENTS=$(cat "${FILE}")
        LAST_SECTION_LINE=$(wc -l "${FILE}" | awk '{print $1}')

        if [ $(grep -c "^\[.*\]$" <<< "${FILE_CONTENTS}") -gt 1 ]; then
            HAS_MULTIPLE_SECTIONS=true
            LAST_SECTION_LINE=$(grep -n "^\[.*\]$" "${FILE}" | sed '2q;d' | awk -F: '{print $1}')
            FILE_CONTENTS=$(echo "${FILE_CONTENTS}" | head -n "${LAST_SECTION_LINE}")
        fi

        if [[ $(grep -c "^${KEY_ESC}=\(${VAL}\|${VAL_ESC}\)$" <<< "${FILE_CONTENTS}") == 0 ]] \
        || [[ $(grep -c "^${KEY_ESC}=$" <<< "${FILE_CONTENTS}") == 1 ]]; then
            if [ $(grep -c "^${KEY_ESC}=.*$" <<< "${FILE_CONTENTS}") -gt 0 ]; then
                if [ -z "${VAL}" ]; then
                    sed -i '1,'"${LAST_SECTION_LINE}"' {/^'"${KEY_ESC}"'=.*$/d}' "${FILE}"
                else
                    sed -i '1,'"${LAST_SECTION_LINE}"' s|^'"${KEY_ESC}"'=.*$|'"${KEY_ESC}"'='"${VAL}"'|g' "${FILE}"
                fi
            elif [ -n "${VAL}" ]; then
                if ${HAS_MULTIPLE_SECTIONS}; then
                    sed -i "${LAST_SECTION_LINE} i ${KEY_ESC}=${VAL_ESC}" "${FILE}"
                else
                    printf "${KEY}=${VAL}\n" >> "${FILE}"
                fi
            fi

            echo "${FILE} >>> ${KEY}=${VAL}"
        fi
    fi

    if [[ "${KEY_ID}" == "Name" ]]; then
        set_launcher_entry_for_language "${FILE}" "${KEY_LANGUAGE}" "Name" "${VAL}"
        set_launcher_entry_for_language "${FILE}" "${KEY_LANGUAGE}" "GenericName" "${VAL}"
    elif [[ "${KEY_ID}" == "FullName" ]]; then
        set_launcher_entry_for_language "${FILE}" "${KEY_LANGUAGE}" "X-GNOME-${KEY_ID}" "${VAL}"
        set_launcher_entry_for_language "${FILE}" "${KEY_LANGUAGE}" "X-MATE-${KEY_ID}" "${VAL}"
    elif [[ "${KEY_ID}" == "Comment" ]] \
      || [[ "${KEY_ID}" == "Icon" ]] \
      || [[ "${KEY_ID}" == "Keywords" ]]; then
        set_launcher_entry_for_language "${FILE}" "${KEY_LANGUAGE}" "${KEY_ID}" "${VAL}"
    fi
}

function set_launcher_entry_for_language() {
    local FILE="${1}"
    local LANGUAGE="${2}"
    local KEY="${3}"
    local VALUE="${4}"

    if [ -z "${KEY_LANGUAGE}" ] \
    || [[ "${KEY_LANGUAGE}" == "en" ]]; then
        set_launcher_entry_english "${FILE}" "${KEY}" "${VAL}"
    elif [[ "${KEY_LANGUAGE}" == "es" ]]; then
        set_launcher_entry_spanish "${FILE}" "${KEY}" "${VAL}"
    elif [[ "${KEY_LANGUAGE}" == "ro" ]]; then
        set_launcher_entry_romanian "${FILE}" "${KEY}" "${VAL}"
    fi
}

function set_launcher_entry_english() {
    local FILE="${1}"
    local KEY="${2}"
    local VAL="${*:3}"

    set_launcher_entries "${FILE}" \
        "${KEY}[en_AU]" "${VAL}" \
        "${KEY}[en_CA]" "${VAL}" \
        "${KEY}[en_GB]" "${VAL}" \
        "${KEY}[en_NZ]" "${VAL}" \
        "${KEY}[en_US]" "${VAL}" \
        "${KEY}[en_ZA]" "${VAL}"
}

function set_launcher_entry_romanian() {
    local FILE="${1}"
    local KEY="${2}"
    local VAL="${*:3}"

    set_launcher_entries "${FILE}" \
        "${KEY}[ro_RO]" "${VAL}" \
        "${KEY}[ro_MD]" "${VAL}"
}
function set_launcher_entry_spanish() {
    local FILE="${1}"
    local KEY="${2}"
    local VAL="${*:3}"

    set_launcher_entries "${FILE}" \
        "${KEY}[es_AR]" "${VAL}" \
        "${KEY}[es_CL]" "${VAL}" \
        "${KEY}[es_ES]" "${VAL}" \
        "${KEY}[es_MX]" "${VAL}"
}

function create_launcher() {
    local FILE_PATH="$*"
    local NAME=$(basename "${FILE_PATH}" | cut -f 1 -d '.')

    if [ ! -f "${FILE_PATH}" ]; then
        {
            echo "[Desktop Entry]"
            echo "Version=1.0"
            echo "NoDisplay=false"
            echo "Encoding=UTF-8"
            echo "Type=Application"
            echo "Terminal=false"
            echo "Exec=${NAME}"
            echo "StartupWMClass=${NAME}"
            echo "Name=${NAME}"
            echo "Comment=${NAME}"
            echo "Keywords=${NAME}"
            echo "Icon=${NAME}"
        } > "${FILE_PATH}"

        chmod +x "${FILE_PATH}"
        echo "Created file '${FILE_PATH}'"
    fi
}