#!/usr/bin/env bash
#
# message
#
# ====================================================================================================

msg_error() {
    printf "${red}✘ $1${normal}\n" >&2
}

msg_success() {
    printf "${green}✔ $1${normal}\n" >&2
}

msg_warning() {
    printf "${yellow}❢ $1${normal}\n" >&2
}

msg_hint() {
    printf "${gray}✱ $1${normal}\n" >&2
}

msg_question() {
    printf "${green}? $1${normal}\n" >&2
}

msg_step() {
    printf "${blue}> $1${normal}\n" >&2
}

msg_sub_step() {
    printf "${blue}  - $1${normal}\n" >&2
}

msg() {
    printf "$1\n" >&2
}

msg_title() {
    local input="$1"
    local total_width=${2:-50}
    local input_length=${#input}
    local padding=$(( (total_width - input_length - 4) / 2 ))

    local dashs=$(printf "%*s" "$padding" "" | tr ' ' '-')
    local result=$(printf '%s| %s |%s' "$dashs" "${blue}${input}${normal}" "$dashs")

    echo ""
    echo "${result}"
    echo ""
}

msg_header() {
    local input="$1"
    local total_width=${2:-50}
    local input_length=${#input}
    local padding=$(( (total_width - input_length - 4) / 2 ))
    local dashes=$(printf '%*s' "$total_width" | tr ' ' '-')
    local result=$(printf '%*s| %s |%*s' "$padding" "" "$input" "$padding" "")

    echo "${dashes}"
    echo "${result}"
    echo "${dashes}"
}
