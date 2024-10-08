#!/usr/bin/env bash
#
# functions.sh
#
# ====================================================================================================

function clone_and_update_repos() {
    local repo_url="$1"
    local target_dir="$2"
    local opt=$3

    if [ ! -d "$target_dir" ]; then
        if [ "$repo_url" == "-" ]; then
            msg_sub_step "Nothing to update in $target_dir"
        else
            msg_sub_step "Cloning repository to $target_dir"
            git clone "$repo_url" "$target_dir"
        fi
        return
    fi

    if [ -d "$target_dir/.git" ]; then
        if [ "$opt" = "update" ]; then
            local cwd=$(pwd)
            local is_dirty=false
            msg_sub_step "  Updating existing repository in $target_dir"
            cd "$target_dir"

            # Check if there are new commits on the remote
            git fetch
            if [ "$(git rev-parse HEAD)" != "$(git rev-parse @{u})" ]; then

                # Check if the git repository is dirty
                if ! git diff-index --quiet HEAD --; then
                    msg_sub_step "  Repository is dirty. Stashing changes..."
                    git stash
                    is_dirty=true
                fi

                git pull --rebase

                [ "$is_dirty" = true ] && git stash pop
            else
                msg_sub_step "  Repository is up to date."
            fi
            cd "$cwd"
        else
            msg_sub_step "  Repository Directory already exist."
        fi
    else
        msg_warning "  Directory $target_dir exists but is not a git repository"
        return
    fi
}

function scan_dirs() {
    local dir="$1"

    # Check if the directory exists
    if [ ! -d "$dir" ]; then
        msg_error "Directory '$dir' does not exist."
        return
        # return 1  # don't interrupt
    fi

    # Use find to list directories, excluding those starting with '.' or '_'
    find "$dir" -maxdepth 1 -type d \( ! -name '.*' -a ! -name '_*' \) | sed 's|.*/||' | grep -v "^$(basename "$dir")$" | sort
}

function parse_symlink_items() {
    local input="$1"
    local items=()
    local items_string="${input}"

    # Check if the input contains '|'
    if [[ "$input" == *"|"* ]]; then
        # Get the string after '|' to the end
        items_string="${input#*|}"
    fi

    # Parse the items separated by comma
    IFS=',' read -ra items <<<"$items_string"

    # Trim whitespace from each item
    # items=("${items[@]/#/$(echo '\x1b[K')}" "${items[@]/%/$(echo '\x1b[K')}")

    # Remove empty elements
    items=("${items[@]}")

    # Return the item list, joined by spaces
    echo "${items[*]}"
}

function parse_symlink_opt() {
    local input="$1"
    local opt=""

    # Check if the input contains '|'
    if [[ "$input" == *"|"* ]]; then
        # Get the string before '|'
        opt="${input%%|*}"

        # Trim whitespace
        opt="$(echo "${opt}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    fi

    # Return the option (or empty string if no '|' was found)
    echo "$opt"
}

function check_cmd() {
    command -v "$1" >/dev/null 2>&1
}

function need_cmd() {
    if ! check_cmd "$1"; then
        msg_error "need '$1' (command not found)"
    fi
}
