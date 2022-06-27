#!/bin/bash
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    source "scripts/common/filesystem.sh"
    source "${REPO_DIR}/scripts/common/common.sh"
fi

NUMBER_REGEX_PATTERN='^[0-9][0-9.]*$'
NUMBER_UINT_REGEX_PATTERN='^uint[0-9]+ [0-9]+$'
ARRAY_REGEX_PATTERN='^\[[0-9]+(\.[0-9]+)*(,\s*[0-9]+(\.[0-9]+)*)*]$'

function is_value_string() {
    local VALUE="${*}"

    [[ ${VALUE} =~ ${ARRAY_REGEX_PATTERN} ]] && return 1 # False


    if ! [[ ${VALUE} =~ ${NUMBER_REGEX_PATTERN} ]] \
    && ! [[ ${VALUE} =~ ${NUMBER_UINT_REGEX_PATTERN} ]]; then
        if [ "${VALUE}" != "true" ] && [ "${VALUE}" != "false" ]; then
            return 0 # True
        fi
    fi

    return 1 # False
}

function get_config_value() {
    local SEPARATOR="="

    if [[ "${1}" == "--separator" ]]; then
        shift
        SEPARATOR="${1}"
        shift
    fi

    local FILE_CONTENT=""
    local FILE_PATH="${1}"
    local KEY="${2}"

    [ ! -f "${FILE_PATH}" ] && return

    FILE_CONTENT=$(read_file "${FILE_PATH}")

    grep "^${KEY}\s*${SEPARATOR}" <<< "${FILE_CONTENT}" | sed \
        -e 's/^[^'"${SEPARATOR}"']*'"${SEPARATOR}"'//g' \
        -e 's/^\s*//g' -e 's/\s*$//g'
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

    create_file "${FILE_PATH}"

    #local VALUE=$(echo "${VALUE_RAW}" | sed -e 's/[]\/$*.^|[]/\\&/g')
    local VALUE="${VALUE_RAW}"
    local FILE_CONTENT=""

    FILE_CONTENT=$(read_file "${FILE_PATH}")

    CURRENT_VALUE=$(get_config_value --separator "${SEPARATOR}" "${FILE_PATH}" "${KEY}")

    if [[ "${CURRENT_VALUE}" == "${VALUE}" ]]; then
        return
    elif is_value_string "${VALUE}"; then
        if [[ "'${CURRENT_VALUE}'" == "${VALUE}" ]] \
        || [[ "\"${CURRENT_VALUE}\"" == "${VALUE}" ]]; then
            return
        fi
    fi

    # If the config key already exists (with a different value)
    if [ $(grep -c "^${KEY}\s*${SEPARATOR}.*$" <<< "${FILE_CONTENT}") -gt 0 ]; then
        if [ -w "${FILE_PATH}" ]; then
            sed -i 's|^'"${KEY}\s*${SEPARATOR}"'.*$|'"${KEY}${SEPARATOR}${VALUE}"'|g' "${FILE_PATH}"
        else
            sudo sed -i 's|^'"${KEY}${SEPARATOR}"'.*$|'"${KEY}${SEPARATOR}${VALUE}"'|g' "${FILE_PATH}"
        fi
    else
        append_line "${FILE_PATH}" "${KEY}${SEPARATOR}${VALUE}"
    fi

    echo "${FILE_PATH} >>> ${KEY}${SEPARATOR}${VALUE}"
}

function set_firefox_config() {
    local PROFILE="${1}"
    local KEY="${2}"
    local VALUE_RAW="${@:3}"
    local FILE="${HOME_MOZILLA}/firefox/${PROFILE}/prefs.js"

    create_file "${FILE_PATH}"

    local VALUE=$(echo "${VALUE_RAW}" | sed -e 's/^\s*//g' -e 's/\s*$//g')

    is_value_string "${VALUE}" && VALUE="\"${VALUE}\""

    local FILE_CONTENT=$(cat "${FILE}")
    VALUE=$(echo "${VALUE}" | sed -e 's/[]\/$*.^|[]/\\&/g')

    # If the value is not already set
    if [[ $(grep -c "^user_pref(\"${KEY}\", *${VALUE});$" <<< "${FILE_CONTENT}") == 0 ]] && \
       [[ $(grep -c "^user_pref(\"${KEY}\", *\"${VALUE}\");$" <<< "${FILE_CONTENT}") == 0 ]]; then
        # If the config key already exists (with a different value)
        if [ $(grep -c "^user_pref(\"${KEY}.*$" <<< "${FILE_CONTENT}") -gt 0 ]; then
            sed -i '/^user_pref('"\"${KEY}"'/d' "${FILE}"
        fi

        append_line "${FILE}" "user_pref(\"${KEY}\", ${VALUE});"

        echo "${FILE} >>> ${KEY} = ${VALUE_RAW}"
    fi
}

function set_json_property() {
    local FILE_PATH="${1}"

    ( ! does_bin_exist "jq") && return
    [ ! -f "${FILE_PATH}" ] && return

    local PROPERTY="${2}"
    local VALUE_RAW="${@:3}"
    local VALUE=$(echo "${VALUE_RAW}" | sed -e 's/[]\/$*.^|[]/\\&/g')

    local FILE_CONTENT=$(cat "${FILE_PATH}" | grep -v "^[ \t]*//" | tr -d '\n' | sed 's/,[ \t]*}/ }/g')
    local CURRENT_VALUE=$(jq "${PROPERTY}" <<< "${FILE_CONTENT}")

    VALUE=$(echo "${VALUE}" | sed 's/\\\././g') # dirty fix

    is_value_string "${VALUE}" && VALUE="\"${VALUE}\""

    # If the value is not already set
    if [ "${VALUE}" != "${CURRENT_VALUE}" ] \
    && [ "${VALUE_RAW}" != "${CURRENT_VALUE}" ] \
    && [ "\"${VALUE_RAW}\"" != "${CURRENT_VALUE}" ]; then
        if [ -w "${FILE_PATH}" ]; then
            jq "${PROPERTY}"'='"${VALUE}" <<< "${FILE_CONTENT}" > "${FILE_PATH}"
        elif ${HAS_SU_PRIVILEGES}; then
            jq "${PROPERTY}"'='"${VALUE}" <<< "${FILE_CONTENT}" | run_as_su tee "${FILE_PATH}" > /dev/null
        else
            echo "Cannot set ${PROPERTY}=${VALUE} in ${FILE_PATH}"
            return
        fi

        echo "${FILE_PATH} >>> ${PROPERTY}=${VALUE}"
    fi
}

function set_xml_node() {
    FILE="${1}"
    NODE_RAW="${2}"
    VALUE_RAW="${@:3}"

    (! does_bin_exist "xmlstarlet") && return
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
    ACTION="options"
    MODULE="${1}"
    KEY="${2}"
    VALUE="${3}"

    FILE_CONTENT=$(cat "${FILE}")

    if [ "${MODULE}" = "blacklist" ]; then
        ACTION="blacklist"
        MODULE="${KEY}"
        KEY=""
        VALUE=""
    fi

    # If the option is not already set
    if [ -n "${KEY}" ]; then
        if [[ $(grep -c "^${ACTION} ${MODULE} ${KEY}=${VALUE}$" <<< "${FILE_CONTENT}") == 0 ]]; then
            # If the option key already exists (with a different value)
            if [ $(grep -c "^${ACTION} ${MODULE} ${KEY}=.*$" <<< "${FILE_CONTENT}") -gt 0 ]; then
                sed -i 's|^'"${ACTION} ${MODULE} ${KEY}"'=.*$|'"${ACTION} ${MODULE} ${KEY}"'='"${VALUE}"'|g' "${FILE}"
            else
                append_line "${FILE}" "${ACTION} ${MODULE} ${KEY}=${VALUE}"
            fi

            echo "${FILE} >>> ${ACTION} ${MODULE} ${KEY}=${VALUE}"
        fi
    else
        if ! grep -q "^${ACTION} ${MODULE}$" <<< "${FILE_CONTENT}"; then
            append_line "${FILE}" "${ACTION} ${MODULE}"
            echo "${FILE} >>> ${ACTION} ${MODULE}"
        fi
    fi
}

function set_pulseaudio_module_option() {
    FILE="${ROOT_ETC}/pulse/default.pa"
    ACTION="load-module"
    MODULE="${1}"
    KEY="${2}"
    VALUE="${3}"

    FILE_CONTENT=$(cat "${FILE}")

    # If the option is not already set
    if [ -n "${KEY}" ]; then
        if [[ $(grep -c "^${ACTION} ${MODULE} ${KEY}=${VALUE}$" <<< "${FILE_CONTENT}") == 0 ]]; then
            # If the option key already exists (with a different value)
            if [ $(grep -c "^${ACTION} ${MODULE} ${KEY}=.*$" <<< "${FILE_CONTENT}") -gt 0 ]; then
                run_as_su sed -i 's|^'"${ACTION} ${MODULE} ${KEY}"'=.*$|'"${ACTION} ${MODULE} ${KEY}"'='"${VALUE}"'|g' "${FILE}"
            elif [ $(grep -c "^${ACTION} ${MODULE}$" <<< "${FILE_CONTENT}") -gt 0 ]; then
                run_as_su sed -i 's|^'"${ACTION} ${MODULE}"'$|'"${ACTION} ${MODULE} ${KEY}"'='"${VALUE}"'|g' "${FILE}"
            else
                append_line "${FILE}" "${ACTION} ${MODULE} ${KEY}=${VALUE}"
            fi

            echo "${FILE} >>> ${ACTION} ${MODULE} ${KEY}=${VALUE}"
        fi
    else
        if ! grep -q "^${ACTION} ${MODULE}$" <<< "${FILE_CONTENT}"; then
            append_line "${FILE}" "${ACTION} ${MODULE}"
            echo "${FILE} >>> ${ACTION} ${MODULE}"
        fi
    fi
}

function get_gsetting() {
    (! ${HAS_GUI}) && return
    (! $(does_bin_exist "gsettings")) && return

    local SCHEMA="${1}"
    local PROPERTY="${2}"

    echo $(gsettings get "${SCHEMA}" "${PROPERTY}" | sed "s/^'\(.*\)'$/\1/g")
}

function set_gsetting() {
    (! ${HAS_GUI}) && return
    (! does_bin_exist "gsettings") && return

    local SCHEMA="${1}"
    local PROPERTY="${2}"
    local VALUE="${@:3}"
    local CURRENT_VALUE=""

    if [ -d "${HOME_VAR_APP}/${SCHEMA}" ]; then
        set_gsetting_flatpak "${SCHEMA}" "${PROPERTY}" "${VALUE}"
        return
    else
        local SCHEMA_ROOT=$(echo "${SCHEMA}" | awk -F"." '{print $1"."$2"."$3}')

        if [ -d "${HOME_VAR_APP}/${SCHEMA_ROOT}" ]; then
            set_gsetting_flatpak "${SCHEMA_ROOT}" "${PROPERTY}" "${VALUE}"
            return
        fi

        local APP_NAME=$(ls "${HOME_VAR_APP}" | grep -i "^${SCHEMA_ROOT}$" | head -n 1)

        if [ -n "${APP_NAME}" ] \
        && [ -d "${HOME_VAR_APP}/${APP_NAME}" ]; then
            set_gsetting_flatpak "${APP_NAME}" "${PROPERTY}" "${VALUE}"
            return
        fi
    fi

    if ! gsettings list-schemas | grep -q "^${SCHEMA}" \
    && ! gsettings writable "${SCHEMA}" "${PROPERTY}" 2>/dev/null | grep -q "true"; then
        return
    fi

    CURRENT_VALUE=$(get_gsetting "${SCHEMA}" "${PROPERTY}")

    if [ "${CURRENT_VALUE}" != "${VALUE}" ] && \
       [ "${CURRENT_VALUE}" != "'${VALUE}'" ]; then
        echo "GSettings >>> ${SCHEMA}.${PROPERTY}=${VALUE}"
        gsettings set "${SCHEMA}" "${PROPERTY}" "${VALUE}"
    fi
}

function set_gsetting_flatpak() {
    (! ${HAS_GUI}) && return

    local APP="${1}"
    local PROPERTY="${2}"
    local VALUE="${3}"

    is_value_string "${VALUE}" && VALUE="'${VALUE}'"

    local KEYFILE_PATH="${HOME_VAR_APP}/${APP}/config/glib-2.0/settings/keyfile"

    set_config_value "${KEYFILE_PATH}" "${PROPERTY}" "${VALUE}"
}

function set_launcher_entries() {
    local FILE="${1}" && shift

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
    local VAL="${3}"
    local SECTION="Desktop Entry"

    if grep -q "/" <<< "${KEY}"; then
        SECTION=$(awk -F'/' '{print $1}' <<< "${KEY}")
        KEY=$(awk -F'/' '{print $2}' <<< "${KEY}")
    fi

    local FILE_PATH_RAW=$(get_symlink_target "${FILE}")

    if [ "$#" != "3" ]; then
        echo "ERROR: Invalid arguments (count: $#) for set_launcher_entry: ${*}" >&2
    fi

    if [ ! -f "${FILE}" ]; then
        return
    fi

    if [ ! -x "${FILE}" ]; then
        run_as_su chmod +x "${FILE}"
    fi

    local KEY_ID=$(echo "${KEY}" | sed -e 's/^\([^\[]*\).*/\1/g' -e 's/\s//g')
    local KEY_LANGUAGE=$(echo "${KEY}" | sed -e 's/^'"${KEY_ID}"'//g' -e 's/\s//g' -e 's/^.\(.*\).$/\1/g')

    if [ "${KEY_ID}" != "FullName" ]; then
        local KEY_ESC="${KEY}"
        local VAL_ESC="${VAL}"

        local FILE_CONTENTS=""
        #local HAS_MULTIPLE_SECTIONS=false
        local SECTION_INDEX=1
        local SECTION_FIRST_LINE=1
        local SECTION_LAST_LINE=1

        KEY_ESC=$(echo "${KEY}" | sed -e 's/[]\/$*.^|[]/\\&/g')
        VAL_ESC=$(echo "${VAL}" | sed -e 's/[]\/$*.^|[]/\\&/g')

        if ! grep -q "^\[${SECTION}\]$" "${FILE}"; then
            append_line "${FILE}" ""
            append_line "${FILE}" "[${SECTION}]"
            append_line "${FILE}" ""
        fi

        if [ $(grep -c "^\[.*\]$" <<< "${FILE_CONTENTS}") -gt 1 ]; then
            #HAS_MULTIPLE_SECTIONS=true
            SECTION_INDEX=$(grep -n "^\[.*\]$" "${FILE}" | grep -n "\[${SECTION}\]" | awk -F: '{print $1}')

            [ -z "${SECTION_INDEX}" ] && SECTION_INDEX=1

            SECTION_FIRST_LINE=$(grep -n "^\[${SECTION}\]$" "${FILE}" | awk -F: '{print $1}')
            SECTION_LAST_LINE=$(grep -n "^\[.*\]$" "${FILE}" | tail -n +$((SECTION_INDEX+1)) | awk -F: '{print $1}' | head -n 1)

            [ -z "${SECTION_LAST_LINE}" ] && SECTION_LAST_LINE=$(wc -l "${FILE}" | awk '{print $1}')

            FILE_CONTENTS=$(tail -n "+${SECTION_FIRST_LINE}" "${FILE}" | head -n "$((SECTION_LAST_LINE-SECTION_FIRST_LINE+1))")
        else
            SECTION_LAST_LINE=$(wc -l "${FILE}" | awk '{print $1}')
            FILE_CONTENTS=$(cat "${FILE}")
        fi

        if ! grep -q "^${KEY_ESC}=\(${VAL}\|${VAL_ESC}\)$" <<< "${FILE_CONTENTS}" \
        || grep -q "^${KEY_ESC}=$" <<< "${FILE_CONTENTS}"; then
            if grep -q "^${KEY_ESC}=.*$" <<< "${FILE_CONTENTS}"; then
                if [ -z "${VAL}" ]; then
                    run_as_su sed -i ''"${SECTION_FIRST_LINE}"','"${SECTION_LAST_LINE}"' {/^'"${KEY_ESC}"'=.*$/d}' "${FILE_PATH_RAW}"
                else
                    run_as_su sed -i ''"${SECTION_FIRST_LINE}"','"${SECTION_LAST_LINE}"' s|^'"${KEY_ESC}"'=.*$|'"${KEY_ESC}"'='"${VAL}"'|g' "${FILE_PATH_RAW}"
                fi
            elif [ -n "${VAL}" ]; then
                #if ${HAS_MULTIPLE_SECTIONS}; then
                    run_as_su sed -i "${SECTION_LAST_LINE} i ${KEY_ESC}=${VAL_ESC}" "${FILE_PATH_RAW}"
                #else
                #    append_line "${FILE}" "${KEY}=${VAL}"
                #fi
            fi

            KEY_TO_PRINT=$(echo "${SECTION}/${KEY}" | sed 's/Desktop Entry\///g')

            echo "${FILE} >>> ${KEY_TO_PRINT}=${VAL}"
        fi
    fi


    if [[ "${KEY_ID}" == "Name" ]]; then
        set_launcher_entry_for_language "${FILE}" "${KEY_LANGUAGE}" "${SECTION}/Name" "${VAL}"
        #if [[ "${KEY_LANGUAGE}" == "en"* ]]; then
        #    set_launcher_entry "${FILE}" "${SECTION}/GenericName" "${VAL}"
        #else
        #    set_launcher_entry_for_language "${FILE}" "${KEY_LANGUAGE}" "${SECTION}/GenericName" "${VAL}"
        #fi
    elif [[ "${KEY_ID}" == "FullName" ]]; then
        set_launcher_entry_for_language "${FILE}" "${KEY_LANGUAGE}" "${SECTION}/X-GNOME-${KEY_ID}" "${VAL}"
        set_launcher_entry_for_language "${FILE}" "${KEY_LANGUAGE}" "${SECTION}/X-MATE-${KEY_ID}" "${VAL}"
    elif [[ "${KEY_ID}" == "Comment" ]] \
      || [[ "${KEY_ID}" == "GenericName" ]] \
      || [[ "${KEY_ID}" == "Icon" ]] \
      || [[ "${KEY_ID}" == "Keywords" ]]; then
        set_launcher_entry_for_language "${FILE}" "${KEY_LANGUAGE}" "${SECTION}/${KEY_ID}" "${VAL}"
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
    local FILE_PATH="${*}"
    local FILE_LABEL=$(basename "${FILE_PATH}" | cut -f 1 -d '.')
    local NAME=$(echo "${FILE_LABEL}" | sed -e 's/-/ /g' -e 's/^./\U&/g' -e 's/\s./\U&/g')

    if [ ! -f "${FILE_PATH}" ]; then
        create_file "${FILE_PATH}"
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
        echo "Created launcher '${FILE_PATH}'"
    fi
}
