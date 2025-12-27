if [[ "$TERM" != "dumb" ]]; then
    # Check if tput is available and working
    if command -v tput >/dev/null 2>&1 && tput setaf 1 >/dev/null 2>&1; then
        black="$(tput setaf 0)"
        red="$(tput setaf 1)"
        green="$(tput setaf 2)"
        yellow="$(tput setaf 3)"
        blue="$(tput setaf 4)"
        magenta="$(tput setaf 5)"
        cyan="$(tput setaf 6)"
        white="$(tput setaf 7)"
        bold="$(tput bold)"
        dim="$(tput dim)"
        normal="$(tput sgr0)"
        gray="$(tput bold)$(tput setaf 0)"
    else
        black="\033[0;30m"
        red="\033[0;31m"
        green="\033[0;32m"
        yellow="\033[0;33m"
        blue="\033[0;34m"
        magenta="\033[0;35m"
        cyan="\033[0;36m"
        white="\033[0;37m"
        bold="\033[1m"
        dim="\033[2m"
        normal="\033[0m"
        gray="\033[1;30m"
    fi
fi
