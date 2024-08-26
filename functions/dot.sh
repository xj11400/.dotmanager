#!/usr/bin/env bash
# dot.sh
#
# This script is the main entry point for the dotfiles management system.
# It handles initialization, configuration parsing, and various operations
# related to managing dotfiles and packages.
#
# Usage:
#   ./dot.sh [OPTIONS]
#
# (no options)
#   Clone and update repositories in config file (if exists), and
#   create symbolic links under dotfiles directory to target path.
#
# Options:
#   --update              Clone and update repositories in config file
#   --repos-update        Update all repositories without recreating symlinks
#   --silent              Run in silent mode, without interactive
#   --help, -h            Display this help message
#
# Specify options:
#   --source_dir=<path>   Specify a custom dotfiles directory
#   --target_dir=<path>   Specify a custom target directory
#   --config_file=<path>  Specify a custom configuration file path
#
# Default values:
#   dotfiles directory: caller path
#   target directory: the parent of dotfiles directory
#   config file: .config.ini under the dotfiles directory
#
# The script performs the following main tasks:
# 1. Sets up necessary path variables
# 2. Loads required functions from separate files
# 3. Parses command-line arguments
# 4. Reads and processes the configuration file
# 5. Executes the appropriate actions based on the mode and configuration

function dot() {
    # path variable
    DOTFILES_DIR=${DOTFILES_DIR:=$(pwd)}

    #
    # parse arguments
    #
    if [ $# -eq 0 ]; then
        MODE="init"
    else
        while [[ $# -gt 0 ]]; do
            case $1 in
            --config_file=*)
                CONFIG_FILE="${1#*=}"
                MODE="init"
                shift
                ;;
            --target_dir=*)
                TARGET_DIR="${1#*=}"
                shift
                ;;
            --source_dir=*)
                DOTFILES_DIR="${1#*=}"
                shift
                ;;
            --update)
                repo_opt="update"
                MODE=${MODE:-"update"}
                shift
                ;;
            --repos-update)
                repo_opt="update"
                MODE=${MODE:-"repos-update"}
                shift
                ;;
            --silent)
                _silent=true
                shift
                ;;
            --help | -h)
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "(no options)"
                echo "  Clone and update repositories in config file (if exists), and"
                echo "  create symbolic links under dotfiles directory to target path."
                echo ""
                echo "Options:"
                echo "  --update              Clone and update repositories in config file"
                echo "  --repos-update        Update all repositories without recreating symlinks"
                echo "  --silent              Run in silent mode, without interactive"
                echo "  --help, -h            Display this help message"
                echo ""
                echo "Specify options:"
                echo "  --source_dir=<path>  Specify a custom dotfiles directory"
                echo "  --target_dir=<path>  Specify a custom target directory"
                echo "  --config_file=<path>  Specify a custom configuration file path"
                echo ""
                echo "Default values:"
                echo "  dotfiles directory: caller path"
                echo "  target directory: the parent of dotfiles directory"
                echo "  config file: .config.ini under the dotfiles directory"
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                exit 1
                ;;
            esac
        done
    fi

    msg_title "Check Config File"
    #
    # Config File
    #
    CONFIG_FILE=${CONFIG_FILE:="$DOTFILES_DIR/.config.ini"}

    # check .config.ini is exist
    if [ ! -f "$CONFIG_FILE" ]; then
        # update mode require .config.ini
        if [ "$MODE" = "update" ]; then
            msg_error "update mode require .config.ini"
            exit 1
        fi

        msg_warning "Config file not found. ($CONFIG_FILE)"
    else
        # clone and update repositories in .config.ini
        if [ "$MODE" = "init" ] || [ "$MODE" = "update" ] || [ "$MODE" = "repos-update" ]; then
            msg_step "clone and update"
            _pkgs=$(get_dir_sections_in_ini "$CONFIG_FILE")
            if [ ! -z "$_pkgs" ]; then
                log_info "found: $_pkgs"
                for pkg in $_pkgs; do
                    msg_sub_step "Processing package: $pkg"
                    url=$(get_ini_value "$CONFIG_FILE" "$pkg" "_")
                    if [ -n "$url" ]; then
                        msg_sub_step "  url for $pkg: $url"
                        clone_and_update_repos "$url" "$DOTFILES_DIR/$pkg" "$repo_opt"
                    fi
                    _sub_dirs=$(get_dir_keys_in_section "$CONFIG_FILE" "$pkg")
                    for _sub_dir in $_sub_dirs; do
                        msg_sub_step "Processing sub directory: $_sub_dir"
                        url=$(get_ini_value "$CONFIG_FILE" "$pkg" "$_sub_dir")
                        if [ -n "$url" ]; then
                            msg_sub_step "  url for $_sub_dir: $url"
                            clone_and_update_repos "$url" "$DOTFILES_DIR/$pkg/$_sub_dir" "$repo_opt"
                        fi
                    done
                done
            fi
            # exit after cloning and updating
            [ "$MODE" = "repos-update" ] && exit 0
        fi

        # get target_dir from [_configs_] section
        config_target_dir=$(get_ini_value "$CONFIG_FILE" "_configs_" "target_dir")
        if [ -n "$config_target_dir" ]; then
            log_info "target_dir value from [_configs_] section: $config_target_dir"
            TARGET_DIR=${TARGET_DIR:="$config_target_dir"}

            # Resolve TARGET_DIR if it contains $HOME
            if [[ "$TARGET_DIR" == *"\$HOME"* ]]; then
                TARGET_DIR="${TARGET_DIR/\$HOME/$HOME}"
            fi
        fi

        # get pkg_dirs from [_configs_] section
        pkg_dirs_value=$(get_ini_value "$CONFIG_FILE" "_configs_" "pkg_dirs")
        if [ -n "$pkg_dirs_value" ]; then
            log_info "pkg_dirs value from [_configs_] section: $pkg_dirs_value"
            # Parse pkg_dirs_value and add each item to _pkg_dirs
            IFS=',' read -ra pkg_dirs_array <<<"$pkg_dirs_value"
            for dir in "${pkg_dirs_array[@]}"; do
                # Trim leading and trailing whitespace
                dir=$(echo "$dir" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
                if [ -n "$dir" ]; then
                    _pkg_dirs+=("$dir")
                    log_debug "  - Added $DOTFILES_DIR/$dir to _pkg_dirs"
                fi
            done
        fi

        # Scan package directories
        # Iterate through _pkg_dirs if not empty
        if [ ${#_pkg_dirs[@]} -gt 0 ]; then
            log_info "Processing package directories:"
            for pkg_dir in "${_pkg_dirs[@]}"; do
                if [ -d "$DOTFILES_DIR/$pkg_dir" ]; then
                    log_info "[$pkg_dir] - processing"
                    _scan_dirs=$(scan_dirs "$DOTFILES_DIR/$pkg_dir")
                    for item in $_scan_dirs; do
                        _dirs+=("$pkg_dir/$item")
                    done
                else
                    log_info "[$pkg_dir] - not found"
                fi
            done
        else
            log_debug "No package directories to process."
        fi

        # get selected items from [_symlinks_] section
        _selected_dirs=()
        _symlink_opt_dirs=()
        _symlink_opts=()
        _symlink_default_dirs=()
        _symlink_default_opts=()
        _symlinks_items=$(get_keys_and_values_in_section "$CONFIG_FILE" "_symlinks_")
        if [ -n "$_symlinks_items" ]; then
            log_info "symlinks value from [_symlinks_] section:"
            while IFS= read -r _sym_item; do
                log_debug "  - $_sym_item"

                IFS='=' read -r key value <<<"$_sym_item"
                log_info "  - $key : $value"
                key=$(echo "$key" | xargs)
                value=$(echo "$value" | xargs)

                _parsed_items=$(parse_symlink_items "$value")
                _parsed_opt=$(parse_symlink_opt "$value")
                log_info "    parsed items: $_parsed_items"
                for item in $_parsed_items; do
                    item="${key}/${item}"
                    _selected_dirs+=("${item}")
                    _symlink_opt_dirs+=("${item}")
                    _symlink_opts+=("${_parsed_opt}")
                    log_info "      add selected dir :${item} ($_parsed_opt)"
                done

                # default options
                if [[ " ${_symlink_default_dirs[@]} " =~ " $key " ]]; then
                    for i in "${!_symlink_default_dirs[@]}"; do
                        if [[ "$key" == "${_symlink_default_dirs[$i]}" && "$_parsed_opt" != "${_symlink_default_opts[$i]}" ]]; then
                            _symlink_default_opts[$i]=""
                        fi
                    done
                else
                    _symlink_default_dirs+=("${key}")
                    _symlink_default_opts+=("${_parsed_opt}")
                fi
            done <<<"$_symlinks_items"
        fi
    fi

    TARGET_DIR=${TARGET_DIR:="$(dirname "$DOTFILES_DIR")"}

    #
    # Show information
    #

    # Print declared variables
    msg_title ".DotManager"
    echo "Dotfiles Directory : $DOTFILES_DIR"
    echo "Target Directory   : $TARGET_DIR"
    echo "Config File        : $CONFIG_FILE"
    echo "Silent Mode        : ${_silent:-"false"}"
    echo "Mode               : $MODE"

    #
    # Select Items
    #
    msg_title "Select Items"

    # DEBUG: Display items in _selected_dirs
    log_info "Items in _selected_dirs:"
    if [ ${#_selected_dirs[@]} -gt 0 ]; then
        for item in "${_selected_dirs[@]}"; do
            log_info "  - $item"
        done
    else
        log_info "  (empty)"
    fi

    # DEBUG: Display items in _symlink_opt_dirs and _symlink_opts
    log_info "Items in _symlink_opt_dirs and _symlink_opts:"
    if [ -n "$_symlink_opt_dirs" ] && [ ${#_symlink_opts[@]} -gt 0 ]; then
        for i in "${!_symlink_opt_dirs[@]}"; do
            log_info "  - ${_symlink_opt_dirs[$i]} : ${_symlink_opts[$i]}"
        done
    fi

    # List folders under $DOTFILES_DIR but exclude items in $_pkg_dirs
    log_info "Listing folders under $DOTFILES_DIR (excluding package directories):"
    _dot_root_dirs=()
    for dir in "$DOTFILES_DIR"/*; do
        if [ -d "$dir" ]; then
            dir_name=$(basename "$dir")
            # Check if the directory is not in $_pkg_dirs and doesn't start with '.' or '_'
            if ! printf '%s\0' "${_pkg_dirs[@]}" | grep -qFxz "$dir_name" && [[ ! "$dir_name" =~ ^[._] ]]; then
                log_info "  - $dir_name"
                _dirs+=("$dir_name")
                _dot_root_dirs+=("$dir_name")
            fi
        fi
    done

    # DEBUG: directories to link
    if [ ${#_dirs[@]} -gt 0 ]; then
        log_info "Directories to link:"
        for dir in "${_dirs[@]}"; do
            log_info "- $dir"
        done
    fi

    # list and select items
    if [ "$_silent" != true ]; then
        # remove _ in $_selected_dirs
        for i in "${!_selected_dirs[@]}"; do
            _selected_dirs[$i]="${_selected_dirs[$i]#_/}"
        done

        # check box
        checkbox_input "select config" "(select packages to link)" _dirs _selected_dirs

        # add _
        for i in "${!_selected_dirs[@]}"; do
            if [[ " ${_dot_root_dirs[@]} " =~ " ${_selected_dirs[$i]} " ]]; then
                _selected_dirs[$i]="_/${_selected_dirs[$i]}"
            fi
        done
    fi

    #
    # Symbolic Link
    #
    msg_title "Symbolic Link"
    # Check if TARGET_DIR exists
    if [ ! -e "$TARGET_DIR" ]; then
        # If it doesn't exist, create the directory
        mkdir -p "$TARGET_DIR"
        msg_step "Created directory: $TARGET_DIR"
    elif [ ! -d "$TARGET_DIR" ]; then
        # If it exists but is not a directory, exit with an error
        msg_error "Error: $TARGET_DIR exists but is not a directory"
        exit 1
    fi

    # link selected items
    _config_label=()
    _config_items=()
    _idx=0
    _opts_count=$((${#_selected_dirs[@]}))
    for _selected_dir in "${_selected_dirs[@]}"; do
        IFS='/' read -r key value <<<"$_selected_dir"
        key=$(echo "$key" | xargs)
        value=$(echo "$value" | xargs)

        # defalut opt
        _symlink_opt=""
        _found=false

        if [ -n "$_symlink_opt_dirs" ]; then
            for i in "${!_symlink_opt_dirs[@]}"; do
                if [[ "$_selected_dir" == "${_symlink_opt_dirs[$i]}" ]]; then
                    _symlink_opt=${_symlink_opts[$i]}
                    _found=true
                    break
                fi
            done

            # dir opt
            if [ "$_found" = false ] && [ -n "$_symlink_default_dirs" ]; then
                for i in "${!_symlink_default_dirs[@]}"; do
                    [[ "$key" == "${_symlink_default_dirs[$i]}" ]] && _symlink_opt=${_symlink_default_opts[$i]}
                done
            fi
        fi

        # save config
        _label="${key}=${_symlink_opt}"
        if ! [[ " ${_config_label[@]} " =~ " ${_label} " ]]; then
            _config_label+=("$_label")
            _config_items+=("${value}")
        else
            for j in "${!_config_label[@]}"; do
                if [[ "${_label}" == "${_config_label[$j]}" ]]; then
                    _config_items[$j]="${_config_items[$j]}, ${value}"
                    break
                fi
            done
        fi

        # Remove '_/' prefix if present
        _selected_dir=${_selected_dir#_/}
        log_debug " >>>> opt=$_symlink_opt | $DOTFILES_DIR/$_selected_dir"
        # Symlink
        progress_bar_tag $_selected_dir 50 $_idx ${_opts_count}
        symlink --target=$TARGET_DIR $_symlink_opt "$DOTFILES_DIR/$_selected_dir"
        _idx=$((_idx + 1))
    done
    progress_bar_tag "done" 50 $_idx ${_opts_count}

    if [ "$_silent" == true ]; then
        msg_success "done"
        exit 0
    fi

    #
    # Write config file
    #
    msg_title "Write config file"
    if [ ! -f "$CONFIG_FILE" ]; then
        msg_step "create $CONFIG_FILE"
        touch"$CONFIG_FILE"
    fi

    # Check if _configs_ section exists
    # !! Don't modify _configs_ section
    # if ! is_section "$CONFIG_FILE" "_configs_"; then
    #     # If it doesn't exist, add the section and the target_dir key
    #     append_section "$CONFIG_FILE" "_configs_"
    #     append_key "$CONFIG_FILE" "_configs_" "target_dir" "$TARGET_DIR"
    #     msg_step "Added _configs_ section with target_dir to $CONFIG_FILE"
    # else
    #     # If it exists, check if target_dir key exists
    #     if ! is_key "$CONFIG_FILE" "_configs_" "target_dir"; then
    #         # If it doesn't exist, add it to the config file
    #         append_key "$CONFIG_FILE" "_configs_" "target_dir" "$TARGET_DIR"
    #         msg_step "Added target_dir to _configs_ section in $CONFIG_FILE"
    #     else
    #         # If it exists, update its value
    #         update_value "$CONFIG_FILE" "_configs_" "target_dir" "$TARGET_DIR"
    #         msg_step "Updated target_dir in _configs_ section in $CONFIG_FILE"
    #     fi
    # fi

    # Check if _symlinks_ section exists
    if ! is_section "$CONFIG_FILE" "_symlinks_"; then
        # If it doesn't exist, add the section
        append_section "$CONFIG_FILE" "_symlinks_"
        msg_step "Added _symlinks_ section to $CONFIG_FILE"
    else
        # remove old symlink target option
        msg_step "Removing previous keys in _symlinks_ section"
        while IFS= read -r _sym_item; do
            remove_key "$CONFIG_FILE" "_symlinks_" "$_sym_item"
        done <<<"$(get_keys_in_section "$CONFIG_FILE" "_symlinks_")"
    fi

    if [ -n "$_config_label" ] && [ ${#_config_items[@]} -gt 0 ]; then
        msg_step "Writing [_symlinks_] :"
        for i in "${!_config_label[@]}"; do
            IFS='=' read -r key value <<<"${_config_label[$i]}"
            key=$(echo "$key" | xargs)
            value=$(echo "$value" | xargs)

            msg_sub_step "key: ${key}, opt: ${value}, dirs: ${_config_items[$i]}"

            [ -n "$value" ] && _config_items[$i]="${value} | ${_config_items[$i]}"
            append_key "$CONFIG_FILE" "_symlinks_" "${key}" "${_config_items[$i]}"
        done
    fi
    msg_success "done"
}
