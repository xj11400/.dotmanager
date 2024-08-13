#!/bin/bash

# stow
# ----
check_stow() {
    if [ ! -x "$(command -v stow)" ]; then
        local current=$(pwd)
        echo -e "\033[4;34m▓▒░\033[0m install stow"
        git clone https://git.savannah.gnu.org/git/stow.git --depth 1 /tmp/stow
        cd /tmp/stow
        echo $(pwd)
        ./configure
        sudo make install
        cd $current
    fi
}

stow_dot() {
    local _dir=$1
    local _list=$2[@]
    local _idx=0

    local opts=("${!_list}")
    local opts_count=$((${#opts[@]}))

    for _d in ${!_list}; do
        progress_bar_tag $_d 50 $_idx ${opts_count}
        stow -d $_dir -t $HOME $_d --no-folding --restow
        _idx=$((_idx + 1))
    done

    progress_bar_tag "done" 50 $_idx ${opts_count}
}

stow_dot_user() {
    local _dir=$1
    local _list=$2[@]
    local _idx=0

    local opts=("${!_list}")
    local opts_count=$((${#opts[@]}))

    for _d in ${!_list}; do
        progress_bar_tag $_d 50 $_idx ${opts_count}
        stow -d $_dir -t $HOME $_d --restow
        _idx=$((_idx + 1))
    done

    progress_bar_tag "done" 50 $_idx ${opts_count}
}

restow_dot() {
    local _dir=$1
    local _list=$2[@]
    for _d in ${!_list}; do
        echo "${_dir}/$_d"
        stow -d $_dir -t $HOME $_d --no-folding --restow
    done
}
