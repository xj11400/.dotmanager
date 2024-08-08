#!/usr/bin/env bash
#
# progress bar
#
# ====================================================================================================

_compare() {
    local value_l="$1" operator="$2" value_r="$3"

    awk -vv1="$value_l" -vv2="$value_r" 'BEGIN {
        split(v1, a, /\./); split(v2, b, /\./);
        if (a[1] == b[1]) {
            exit (a[2] '$operator' b[2]) ? 0 : 1
        }
        else {
            exit (a[1] '$operator' b[1]) ? 0 : 1
        }
    }'
}

# _compare() {
#     if [ "$(echo "$1 $2 $3" | bc)" == 0 ];then
#         echo false
#     else
#         echo true
#     fi
# }

_norm_percentage() {
    local percentage=$1

    if [ ! -z "$2" ]; then
        percentage=$(echo "($1*100)/$2" | bc)
    fi

    if $(_compare 0 ">" $percentage); then
        percentage=0
    elif $(_compare 0 "==" $percentage); then
        percentage=$1
    elif $(_compare 0 "<" $percentage) && $(_compare 1 ">" $percentage); then
        percentage=$(echo $percentage*100/1 | bc)
    elif $(_compare 0 "<" $percentage) && $(_compare 100 ">=" $percentage); then
        percentage=$(echo $percentage/1 | bc)
    elif $(_compare 100 "<" $percentage); then
        percentage=100
    fi

    IFS=''
    echo $percentage
}

# _progress_bar
# @arg1: width
# @arg2: percentage
_progress_bar() {
    local percentage=$2
    local width=$1
    local numFilled=$((percentage * width / 100))
    local numEmpty=$((width - numFilled))

    tput civis
    tput el1

    tput cub $(tput cols)

    printf "["
    printf "%${numFilled}s" | tr ' ' '='
    printf "%${numEmpty}s" | tr ' ' ' '
    printf "] %d%%" $percentage

}

# progress_bar
# @arg1: tag
# @arg2: width
# @arg3: current value
# @arg4: max value (default 100)
progress_bar_tag() {
    local percentage=$(_norm_percentage $3 $4)

    _progress_bar $2 $percentage

    # print tag
    if [[ ! -z $1 ]]; then
        printf " %s" $1
    fi

    if [[ $percentage -eq 100 ]]; then
        printf "\n"
        tput cnorm
    fi
}

# progress_bar
# @arg1: width
# @arg2: current value
# @arg3: max value (default 100)
progress_bar() {
    progress_bar_tag "" $1 $2 $3
}

progress_bar_print() {
    local percentage=$(_norm_percentage $2 $3)

    _progress_bar $1 $percentage

    printf "\n"
    tput cnorm
}

progress_bar_full() {
    local _size=$(($(tput cols) - 10))
    progress_bar $_size $1 $2
}

progress_bar_large() {
    progress_bar 100 $1 $2
}

progress_bar_medium() {
    progress_bar 50 $1 $2
}

progress_bar_small() {
    progress_bar 10 $1 $2
}

progress_bar_print_large() {
    local _size=$(($(tput cols) - 10))
    progress_bar_print $_size $1 $2
}

progress_bar_print_large() {
    progress_bar_print 100 $1 $2
}

progress_bar_print_medium() {
    progress_bar_print 50 $1 $2
}

progress_bar_print_small() {
    progress_bar_print 10 $1 $2
}
