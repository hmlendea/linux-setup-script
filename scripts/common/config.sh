#!/bin/bash
source "scripts/common/common.sh"

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

    if [ ! -f "${FILE_PATH}" ]; then
        # TODO: Handle directory creation
        touch "${FILE_PATH}"
    fi

    #local VALUE=$(echo "${VALUE_RAW}" | sed -e 's/[]\/$*.^|[]/\\&/g')
    local VALUE=$VALUE_RAW
    local FILE_CONTENT=$(cat "${FILE_PATH}")

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

    if [ ! -f "${FILE}" ]; then
        # TODO: Handle directory creation
        touch "${FILE}"
    fi

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
