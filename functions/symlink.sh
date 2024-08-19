#!/usr/bin/env bash
#
# Symlink Functions
# This file contains utility functions for managing symbolic links.
# ====================================================================================================

function list_directories() {
    local dir="$1"
    local exclude_items=("\.git") # TODO: add more exclude items

    # Check if the directory exists
    if [ ! -d "$dir" ]; then
        msg_error "Error: Directory '$dir' does not exist."
        return 1
    fi

    # Use find to list directories recursively, excluding specified items
    find "$dir" -type d | sed "s|^$dir/||" | grep -vE "^$|$(
        IFS=\|
        echo "${exclude_items[*]}"
    )" | grep -v "^$dir$" | sort

}

function list_files() {
    local dir="$1"
    local exclude_items=("README.md" ".DS_Store") # TODO: add more exclude items
    local file_list=()

    # List files directly under $dir
    while IFS= read -r file; do
        filename=$(basename "$file")
        exclude=false
        for exclude_item in "${exclude_items[@]}"; do
            if [[ "$filename" == "$exclude_item" ]]; then
                exclude=true
                break
            fi
        done
        if [ "$exclude" = false ] && [ -n "$filename" ]; then
            file_list+=("$filename")
        fi
    done <<<"$(find "$dir" -maxdepth 1 -type f)"

    # Sort the file list and save it to a variable
    IFS=$'\n' sorted_file_list=($(sort <<<"${file_list[*]}"))
    echo "${sorted_file_list[*]}"
}

function list_files_recursive() {
    local dir="$1"
    local exclude_items=("README.md" ".DS_Store")

    _dirs=$(list_directories "$dir")

    # Initialize an empty array to store the file list
    local file_list=()

    # Iterate through all directories
    while IFS= read -r subdir; do
        # Use find to list files in the current directory, excluding specified items
        while IFS= read -r file; do
            filename=$(basename "$file")
            exclude=false
            for exclude_item in "${exclude_items[@]}"; do
                if [[ "$filename" == "$exclude_item" ]]; then
                    exclude=true
                    break
                fi
            done
            if [ "$exclude" = false ] && [ -n "$filename" ]; then
                file_list+=("${subdir:+$subdir/}$filename")
            fi
        done <<<"$(find "$dir/$subdir" -maxdepth 1 -type f)"
    done <<<"$_dirs"

    # Sort the file list and save it to a variable
    IFS=$'\n' sorted_file_list=($(sort <<<"${file_list[*]}"))
    echo "${sorted_file_list[*]}"
    # list files under $dir
    list_files $dir
}

function list_files_and_directories() {
    local dir="$1"
    _dirs=$(list_directories "$dir")
    # Filter directories to keep only those at the end of the hierarchy
    local root_dirs=()
    local tmp_files
    for _dir in $_dirs; do
        # Check if the directory contains no subdirectories
        if [ -z "$(find "$dir/$_dir" -maxdepth 1 -type d -not -path "$dir/$_dir")" ]; then
            # log_debug "        ------root"
            root_dirs+=("$_dir")
        else
            tmp_files=("$(list_files "$dir/$_dir")")
            if [ -n "${tmp_files[*]}" ]; then
                while IFS= read -r _file; do
                    # log_debug "        ------ files::  $_dir/$_file"
                    root_dirs+=("$_dir/$_file")
                done <<<"${tmp_files[*]}"
            fi
        fi
    done

    root_dirs+=("$(list_files "$dir")")

    # Sort and return the root directories
    IFS=$'\n' sorted_root_dirs=($(sort <<<"${root_dirs[*]}"))
    echo "${sorted_root_dirs[*]}"
}

function _symlink() {
    local src_dir=$1
    local target_dir=$2
    local opt_files=$3

    local _symlink_items=()
    if [ "$opt_files" = true ]; then
        _symlink_items+=($(list_files_recursive "$src_dir"))
    else
        _symlink_items+=($(list_files_and_directories "$src_dir"))
    fi

    # Check if the target item already exists
    local _target_item
    local _items_to_symlink=()
    for _item in "${_symlink_items[@]}"; do
        log_info "symlink item: $_item"
        _target_item="$target_dir/$_item"
        if [ -e "$_target_item" ] || [ -L "$_target_item" ]; then
            log_info "Warning: '$_target_item' already exists."
            # Check if the target item is not a symlink
            if [ ! -L "$_target_item" ]; then
                msg_error "Error: '$_target_item' exists and is not a symlink. Skipping."
                exit 1
            fi

            # If --resymlink option is not set, skip this item
            if [ "$_opt_resymlink" != true ]; then
                log_info "Skipping existing symlink '$_target_item'. Use --resymlink to override."
                continue
            fi

            # Remove existing symlink if --resymlink is set
            log_info "Removing existing symlink '$_target_item'."
            rm "$_target_item"
            _items_to_symlink+=("$_item")
        else
            _items_to_symlink+=("$_item")
        fi
    done

    # Perform symlink
    local _src_item
    local _target_parent
    for _item in "${_items_to_symlink[@]}"; do
        log_debug "     --- $_item"
        _src_item="$src_dir/$_item"
        _target_item="$target_dir/$_item"

        # Create parent directory if it doesn't exist
        _target_parent=$(dirname "$_target_item")
        [ ! -d "$_target_parent" ] && mkdir -p "$_target_parent"

        # Create the symlink
        log_debug "      > ln -s $_src_item $_target_item"
        ln -s "${_src_item}" "${_target_item}"
    done
}

function symlink() {
    local src_dir=()
    local target=""
    # parse options
    local _opt_files=false
    local _opt_resymlink=false

    # Parse parameters
    for arg in "$@"; do
        case $arg in
        --target=*)
            target="${arg#*=}"
            ;;
        --source=*)
            src_dir+=("${arg#*=}")
            ;;
        --files)
            _opt_files=true
            ;;
        --resymlink)
            _opt_resymlink=true
            ;;
        --help | -h)
            echo "Create symlinks from specific directories to target path."
            echo ""
            echo "Usage: $0 [OPTIONS] <directory>"
            echo ""
            echo "Options:"
            echo "  --files               Create a symlink for each file in the directory"
            echo "  --resymlink           Resymlink existing symlinks or create new symlinks"
            echo "  --help, -h            Display this help message"
            echo ""
            echo "Specify options:"
            echo "  --source=<path>  Specify a custom dotfiles directory"
            echo "  --target=<path>  Specify a custom target directory"
            echo ""
            exit 0
            ;;
        *)
            src_dir+=("$current_dir/$arg")
            ;;
        esac
    done

    # parse ~ to $HOME
    for i in "${!src_dir[@]}"; do
        src_dir[$i]="${src_dir[$i]/#\~/$HOME}"
    done
    target="${target/#\~/$HOME}"

    # Resolve realpath
    for i in "${!src_dir[@]}"; do
        src_dir[$i]=$(realpath "${src_dir[$i]}")
        if [ -z "${src_dir[$i]}" ]; then
            msg_error "Error: Source path '${src_dir[$i]}' is not valid."
            return 1
        fi
    done

    target_dir=$(realpath "$target" 2>&- || echo "")
    if [ -z "$target_dir" ]; then
        if [ -d "$(realpath "$(dirname "$target")")" ]; then
            log_info "Creating target directory: $target"
            mkdir -p "$target"
            target_dir=$(realpath "$target")
        else
            msg_error "Error: Target must be specified."
            return 1
        fi
    fi

    log_info " [symlink] src: ${src_dir[@]}"
    log_info " [symlink] target: $target_dir"

    # Get the list of items to symlink
    for _src_dir in "${src_dir[@]}"; do
        _symlink $_src_dir $target_dir $_opt_files
    done
}
