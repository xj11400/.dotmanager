#!/usr/bin/env bash
#
# general
#
# ====================================================================================================

# store the current set options
OLD_SET=$-
set -e

if [[ "$(uname)" == "Darwin" ]]; then
    arrow="$(echo '\xe2\x9d\xaf')"
    checked="$(echo '\xe2\x97\x89')"
    unchecked="$(echo '\xe2\x97\xaf')"
else
    arrow="$(echo -e '\xe2\x9d\xaf')"
    checked="$(echo -e '\xe2\x97\x89')"
    unchecked="$(echo -e '\xe2\x97\xaf')"
fi


on_default() {
    true
}

gen_index() {
    local k=$1
    local l=0
    if [ $k -gt 0 ]; then
        for l in $(seq $k); do
            echo "$l-1" | bc
        done
    fi
}

on_keypress() {
    local OLD_IFS
    local IFS
    local key
    OLD_IFS=$IFS
    local on_up=${1:-on_default}
    local on_down=${2:-on_default}
    local on_space=${3:-on_default}
    local on_enter=${4:-on_default}
    local on_left=${5:-on_default}
    local on_right=${6:-on_default}
    local on_ascii=${7:-on_default}
    local on_backspace=${8:-on_default}
    _break_keypress=false
    while IFS="" read -rsn1 key; do
        case "$key" in
        $'\x1b')
            read -rsn1 key
            if [[ "$key" == "[" ]]; then
                read -rsn1 key
                case "$key" in
                'A') eval $on_up;;
                'B') eval $on_down;;
                'D') eval $on_left;;
                'C') eval $on_right;;
                esac
            fi
            ;;
            ' ') eval $on_space ' ';;
            [a-z0-9A-Z\!\#\$\&\+\,\-\.\/\;\=\?\@\[\]\^\_\{\}\~]) eval $on_ascii $key;;
            $'\x7f') eval $on_backspace $key;;
            '') eval $on_enter $key;;
        esac
        if [ $_break_keypress = true ]; then
            break
        fi
    done
    IFS=$OLD_IFS
}

print() {
    echo "$1"
    tput el
}

cleanup() {
    # Reset character attributes, make cursor visible, and restore
    # previous screen contents (if possible).
    tput sgr0
    tput cnorm
    stty echo

    # Restore `set e` option to its orignal value
    if [[ $OLD_SET =~ e ]]; then
        set -e
    else
        set +e
    fi
}

control_c() {
    cleanup
    exit $?
}


function gen_env_from_options() {
    local IFS=$'\n'
    local _indices
    local _env_names
    local _checkbox_selected
    eval _indices=( '"${'${1}'[@]}"' )
    eval _env_names=( '"${'${2}'[@]}"' )

    for i in $(gen_index ${#_env_names[@]}); do
        _checkbox_selected[$i]=false
    done

    for i in ${_indices[@]}; do
        _checkbox_selected[$i]=true
    done

    for i in $(gen_index ${#_env_names[@]}); do
        printf "%s=%s\n" "${_env_names[$i]}" "${_checkbox_selected[$i]}"
    done
}
