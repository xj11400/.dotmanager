#!/usr/bin/env bash
#
# Symlink Functions
# This file contains utility functions for managing symbolic links.
# ====================================================================================================

function list_directories() {
    local dir="$1"
    local exclude_items=("\.git" "\.tmp$")
    local dir_list=()

    # Check if the directory exists
    if [ ! -d "$dir" ]; then
        msg_error "Error: Directory '$dir' does not exist."
        return 1
    fi

    local _current_pass_dir
    # List directly under $dir
    while IFS= read -r _dir; do
        exclude=false
        for exclude_item in "${exclude_items[@]}"; do
            #
            if [[ -n "$_current_pass_dir" && "$_dir" == "${_current_pass_dir}"* ]]; then
                exclude=true
                log_debug "  $_dir  <pass dir>  $_current_pass_dir"
                break
            fi
            #
            if [[ "$_dir" =~ $exclude_item ]]; then
                exclude=true
                _current_pass_dir=$_dir
                log_debug "  $_dir  <catch dir>  $exclude_item"
                break
            fi
        done
        if [ "$exclude" = false ] && [ -n "$_dir" ]; then
            dir_list+=("$_dir")
        fi
    done <<<"$(find "$dir" -type d | sed "s|^$dir/||" | grep -v "^$dir$")"

    # Sort the dir list and save it to a variable
    IFS=$'\n' sorted_dir_list=($(sort <<<"${dir_list[*]}"))
    echo "${sorted_dir_list[*]}"
}

function list_files() {
    local dir="$1"
    local exclude_items=("README.md" ".DS_Store" "\.git" "\.bak$")
    local file_list=()

    # List files directly under $dir
    while IFS= read -r file; do
        filename=$(basename "$file")
        exclude=false
        for exclude_item in "${exclude_items[@]}"; do
            if [[ "$filename" =~ $exclude_item ]]; then
                exclude=true
                log_debug "     $filename  <catch file>  $exclude_item"
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

    _dirs=$(list_directories "$dir")

    # Initialize an empty array to store the file list
    local file_list=()
    local tmp_files

    # Iterate through all directories
    while IFS= read -r subdir; do
        tmp_files=("$(list_files "$dir/$subdir")")
        if [ -z "${tmp_files[*]}" ]; then
            continue
        fi
        while IFS= read -r _file; do
            file_list+=("${subdir:+$subdir/}$_file")
        done <<<"${tmp_files[*]}"
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
    while IFS= read -r _dir; do
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
    done <<< "$_dirs"

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
        _symlink_items+=("$(list_files_recursive "$src_dir")")
    else
        _symlink_items+=("$(list_files_and_directories "$src_dir")")
    fi

    # Check if the target item already exists
    local _target_item
    local _items_to_symlink=()
    while IFS= read -r _item; do
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
            _items_to_symlink+=("${_item}")
        else
            _items_to_symlink+=("${_item}")
        fi
    done <<< "$_symlink_items"

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
        _symlink "${_src_dir}" "${target_dir}" $_opt_files
    done
}
