#!/usr/bin/env bash
#
# question
#
# ====================================================================================================

# @description The stty raw mode prevents ctrl-c from working
#              and can get you stuck in an input loop with no
#              way out. Also the man page says stty -raw is not
#              guaranteed to return your terminal to the same state.
# @arg $1 reference set received char
# https://stackoverflow.com/a/30022297
_read_char() {
    stty -icanon -echo
    eval "$1=\$(dd bs=1 count=1 2>/dev/null)"
    stty icanon echo
}

_msg_question() {
    printf "${green}? $1${normal} " >&2
}

confirm() {
    local default="n"
    if [[ "$2" == "y" ]] || [[ "$2" == "Y" ]]; then
        default="y"
        _msg_question "$1 (n/Y)"
    elif [[ "$2" == "n" ]] || [[ "$2" == "N" ]]; then
        default="n"
        _msg_question "$1 (y/N)"
    elif [ ! -n "$2" ]; then
        _msg_question "$1 (y/N)"
    fi
    
    local result=""
    until [[ "$result" == "y" ]] || [[ "$result" == "n" ]] || [[ "$result" == "Y" ]] || [[ "$result" == "N" ]]; do
        _read_char result

        if [ ${#result} -eq 0 ]; then
            # printf "Enter was hit\n" >&2
            result="$default"
        fi
    done

    printf "${cyan}$result${normal}" >&2
    case "$result" in
    y | Y) printf "1" ;;
    n | N) printf "0" ;;
    esac

    printf "\n" >&2
}

password() {
    _msg_question "$1"
    printf "${cyan}" >&2
    local password=''
    local IFS=
    while read -r -s -n1 char; do
        # ENTER pressed; output \n and break.
        [[ -z "${char}" ]] && {
            printf '\n' >&2
            break
        }
        # BACKSPACE pressed; remove last character
        if [ "${char}" == $'\x7f' ]; then
            if [ "${#password}" -gt 0 ]; then
                password="${password%?}"
                printf '\b \b' >&2
            fi
        else
            password+=$char
            printf '*' >&2
        fi
    done
    printf "${normal}" >&2
    printf "%s" "${password}"
}
