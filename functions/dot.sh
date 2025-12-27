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
# - Sets up necessary path variables
# - Loads required functions from separate files
# - Parses command-line arguments
# - Reads and processes the configuration file
# - Executes the appropriate actions based on the mode and configuration

function process_symlink_task() {
    local _task_name="$1"
    local _target_dir="$2"
    local _pkg_dirs_str="$3"
    local _silent_mode="$4"
    local _config_file="$5"
    local _dotfiles_dir="$6"
    local _direct_mode="$7"

    msg_title "Task: $_task_name"
    log_info "Processing Task: $_task_name"
    log_info "  Target Dir : $_target_dir"
    log_info "  Pkg Dirs   : $_pkg_dirs_str"
    log_info "  Silent     : $_silent_mode"
    log_info "  Direct Mode: $_direct_mode"

    #
    # Parse pkg_dirs
    #
    local _pkg_dirs=()
    if [ -n "$_pkg_dirs_str" ]; then
        IFS=',' read -ra _pkg_dirs_array <<<"$_pkg_dirs_str"
        for dir in "${_pkg_dirs_array[@]}"; do
            dir=$(echo "$dir" | xargs)
            [ -n "$dir" ] && _pkg_dirs+=("$dir")
        done
    fi

    #
    # Scan directories to find available items
    #
    local _available_items=() # Format: group/item

    # If pkg_dirs IS set, scan those.
    # Requirement: "pkg_dirs ... specific the package directories can be search"

    if [ ${#_pkg_dirs[@]} -gt 0 ]; then
        msg_sub_step "Scanning directories..."
        for pkg_dir in "${_pkg_dirs[@]}"; do
            local search_path="$_dotfiles_dir/$pkg_dir"

            # Special handling for root package '_'
            if [[ "$pkg_dir" == "_" ]]; then
                search_path="$_dotfiles_dir"
            fi

            if [ -d "$search_path" ]; then
                log_debug "Scanning $pkg_dir"
                _scan_dirs=$(scan_dirs "$search_path")
                for item in $_scan_dirs; do
                    _available_items+=("$pkg_dir/$item")
                done
            else
                log_debug "Directory not found: $pkg_dir"
            fi
        done
    else
        log_debug "No pkg_dirs specified."
    fi

    #
    # Load existing configuration for this task
    #
    local _selected_items=()     # List of items selected for linking (group/item)
    local _item_opts=()          # Parallel array: options for selected items
    local _group_default_opts=() # Map-like: group -> default options (parallel arrays)
    local _group_names=()        # Keys for default opts

    # helper arrays for config reconstruction
    local _config_map_keys=()
    local _config_map_values=()

    # Read all pairs in section to handle duplicate keys
    local _pairs=$(get_keys_and_values_in_section "$_config_file" "$_task_name")

    while IFS= read -r pair; do
        [ -z "$pair" ] && continue

        # Split key=value (limit 2 parts)
        # Check ini.sh get_keys_and_values_in_section implementation.

        IFS='=' read -r key value <<<"$pair"
        key=$(echo "$key" | xargs)
        value=$(echo "$value" | xargs)

        # Skip reserved keys
        [[ "$key" == "target_dir" || "$key" == "pkg_dirs" || "$key" == "silent" || "$key" == "direct" ]] && continue
        [ -z "$key" ] && continue

        # Parse value: options | item1, item2...
        local _parsed_items=$(parse_symlink_items "$value")
        local _parsed_opt=$(parse_symlink_opt "$value")

        # Store for write-back/default tracking
        _group_names+=("$key")
        _group_default_opts+=("$_parsed_opt")

        # Add explicitly listed items to selection
        for item in $_parsed_items; do
            local full_item="${key}/${item}"
            _selected_items+=("$full_item")
            _item_opts+=("$_parsed_opt")
        done
    done <<<"$_pairs"

    #
    # Interactive Selection (if not silent and pkg_dirs is present)
    #
    # If silent=true, NO checkbox.
    # If pkg_dirs is set, and NOT silent, show checkbox.

    local _interactive=true
    if [[ "$_silent_mode" == "true" ]]; then
        _interactive=false
    fi
    # override global silent? passed in as argument.

    if [[ "$_interactive" == "true" ]]; then
        if [ ${#_available_items[@]} -gt 0 ]; then
            # We need to present _available_items.
            # Pre-select those that are already in _selected_items.

            # Since checkbox_input modifies the array, we need a separate array for selection
            local _choices=("${_available_items[@]}")
            local _pre_selected=()

            # Match available items with selected items
            for avail in "${_choices[@]}"; do
                for sel in "${_selected_items[@]}"; do
                    if [[ "$avail" == "$sel" ]]; then
                        _pre_selected+=("$avail")
                        break
                    fi
                done
            done

            # If nothing selected yet, maybe select all?
            # Existing behavior: user selects.

            # Since checkbox_input modifies the array, we must backup original opts
            local _orig_selected=("${_selected_items[@]}")
            local _orig_opts=("${_item_opts[@]}")

            checkbox_input "Task: $_task_name" "Select items to link" _choices _pre_selected

            # Update _selected_items based on user choice
            _selected_items=("${_pre_selected[@]}")

            # Re-map options for newly selected items
            # If item was already selected, keep opt. If new, use group default.
            local _new_opts=()
            for sel in "${_selected_items[@]}"; do
                local group="${sel%%/*}"
                local found=false
                local best_opt=""

                # Try to find in original selection (Preserve specific options)
                for i in "${!_orig_selected[@]}"; do
                    if [[ "${_orig_selected[$i]}" == "$sel" ]]; then
                        best_opt="${_orig_opts[$i]}"
                        found=true
                        break
                    fi
                done

                # If not found (newly selected), use group default
                if [ "$found" = false ]; then
                    for i in "${!_group_names[@]}"; do
                        if [[ "${_group_names[$i]}" == "$group" ]]; then
                            best_opt="${_group_default_opts[$i]}"
                            break
                        fi
                    done
                fi
                _new_opts+=("$best_opt")
            done
            _item_opts=("${_new_opts[@]}")

        else
            msg_warning "No items found to select in defined pkg_dirs."
        fi
    else
        msg_step "Silent mode: using configuration..."
    fi

    #
    # Perform Linking
    #
    msg_step "Linking files to $_target_dir"
    mkdir -p "$_target_dir"

    local _idx=0
    local _total=$(( ${#_selected_items[@]} + 1 ))

    # Structure for Write-back: parallel arrays
    # Identifier (key+opt), Item List
    local _wb_identifiers=()
    local _wb_items=()
    local _wb_keys=()
    local _wb_opts=()

    for i in "${!_selected_items[@]}"; do
        local item="${_selected_items[$i]}"
        local opt="${_item_opts[$i]}"
        local group="${item%%/*}"
        local subitem="${item#*/}"

        # Link
        # Strip '_/' prefix if present (maps to root)
        local link_path="${item#_/}"

        local _current_target_dir="$_target_dir"
        if [[ "$_direct_mode" == "true" ]]; then
            _current_target_dir="$_target_dir/$subitem"
        fi

        # if not text mode... handle UI
        progress_bar_tag "$link_path" 50 $((_idx + 1)) $_total
        symlink --target="$_current_target_dir" $opt "$_dotfiles_dir/$link_path"

        # Prepare for Config Write-back
        # Group by "Key|Option" to preserve option grouping
        local identifier="${group}|${opt}"
        local k_idx=-1
        for k in "${!_wb_identifiers[@]}"; do
            if [[ "${_wb_identifiers[$k]}" == "$identifier" ]]; then
                k_idx=$k
                break
            fi
        done

        if [ $k_idx -eq -1 ]; then
            _wb_identifiers+=("$identifier")
            _wb_items+=("$subitem")
            _wb_keys+=("$group")
            _wb_opts+=("$opt")
        else
            _wb_items[$k_idx]="${_wb_items[$k_idx]}, $subitem"
        fi

        ((_idx++))
    done
    progress_bar_tag "done" 50 $_total $_total

    #
    # Write Back to Config
    #
    msg_step "Updating config for task: $_task_name"

    # Read existing options to preserve/reorder
    local _raw_target_dir=$(get_ini_value "$_config_file" "$_task_name" "target_dir")
    local _raw_pkg_dirs=$(get_ini_value "$_config_file" "$_task_name" "pkg_dirs")
    local _raw_silent=$(get_ini_value "$_config_file" "$_task_name" "silent")
    local _raw_direct=$(get_ini_value "$_config_file" "$_task_name" "direct")

    # Remove ALL existing keys in section (to force reordering)
    local _existing_keys=$(get_keys_in_section "$_config_file" "$_task_name")
    while IFS= read -r key; do
        [ -z "$key" ] && continue
        remove_key "$_config_file" "$_task_name" "$key"
    done <<<"$_existing_keys"

    # Append new groups
    local _wb_count=${#_wb_identifiers[@]}
    for ((i = _wb_count - 1; i >= 0; i--)); do
        local grp="${_wb_keys[$i]}"
        local items="${_wb_items[$i]}"
        local opt="${_wb_opts[$i]}"

        local val="$items"
        [ -n "$opt" ] && val="$opt | $items"

        append_key "$_config_file" "$_task_name" "$grp" "$val"
    done

    # Append Options
    # Desired order: target_dir, pkg_dirs, silent...
    # --> append: silent (bottom), pkg_dirs, target_dir (top)
    [ -n "$_raw_direct" ] && append_key "$_config_file" "$_task_name" "direct" "$_raw_direct"
    [ -n "$_raw_silent" ] && append_key "$_config_file" "$_task_name" "silent" "$_raw_silent"
    [ -n "$_raw_pkg_dirs" ] && append_key "$_config_file" "$_task_name" "pkg_dirs" "$_raw_pkg_dirs"
    [ -n "$_raw_target_dir" ] && append_key "$_config_file" "$_task_name" "target_dir" "$_raw_target_dir"
}

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
            --text)
                _text_mode=true
                _silent=true
                shift
                ;;
            --help | -h)
                # Help message (kept concise)
                echo "Usage: $0 [OPTIONS]"
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                exit 1
                ;;
            esac
        done
        # Default mode if not set (e.g. only flags passed)
        MODE=${MODE:-"init"}
    fi

    # check if forced into text mode by xdots
    if [ "$_force_text_mode" = true ]; then
        _text_mode=true
        _silent=true
    fi

    msg_title "Check Config File"
    CONFIG_FILE=${CONFIG_FILE:="$DOTFILES_DIR/.config.ini"}
    DEFAULT_TARGET_DIR=${TARGET_DIR:="$(dirname "$DOTFILES_DIR")"}

    if [ ! -f "$CONFIG_FILE" ]; then
        if [ "$MODE" = "update" ]; then
            msg_error "update mode require .config.ini"
            exit 1
        fi
        msg_warning "Config file not found. ($CONFIG_FILE)"
        # Create empty if needed or just exit?
        # Proceed to Init? Without config, nothing to do.
        exit 0
    fi

    #
    # Main Logic Loop
    #
    local _sections=$(get_sections_in_ini "$CONFIG_FILE")
    local _state="NONE" # NONE, REPOS, SYMLINKS

    for _section in $_sections; do

        # State Transitions
        if [[ "$_section" == "_repos_" ]]; then
            _state="REPOS"
            msg_title "Repositories"
            continue
        elif [[ "$_section" == "_symlinks_" ]]; then
            _state="SYMLINKS"
            # Tasks follow
            continue
        elif [[ "$_section" == "_configs_" ]]; then
            # Optional Global Configs (Not fully implemented per spec, skipping)
            continue
        fi

        # Process Sections based on State
        if [[ "$_state" == "REPOS" ]]; then
            # Only process repos in update modes
            if [ "$MODE" = "init" ] || [ "$MODE" = "update" ] || [ "$MODE" = "repos-update" ]; then
                # The section name is the 'package' or 'repo group' name
                # iterate keys (submodules or main repo)
                _repo_keys=$(get_keys_in_section "$CONFIG_FILE" "$_section")
                for _k in $_repo_keys; do
                    _url=$(get_ini_value "$CONFIG_FILE" "$_section" "$_k")
                    _path="$DOTFILES_DIR/$_section"
                    [ "$_k" != "_" ] && _path="$_path/$_k"

                    if [ -n "$_url" ]; then
                        msg_sub_step "Repo: $_section/$_k"
                        clone_and_update_repos "$_url" "$_path" "$repo_opt"
                    fi
                done
            fi

        elif [[ "$_state" == "SYMLINKS" ]]; then
            # This is a Task Section
            if [ "$MODE" != "repos-update" ]; then
                # Read task attributes
                _t_target=$(get_ini_value "$CONFIG_FILE" "$_section" "target_dir")
                _t_target=${_t_target:-$DEFAULT_TARGET_DIR}
                _t_target="${_t_target/\$HOME/$HOME}"

                _t_pkg_dirs=$(get_ini_value "$CONFIG_FILE" "$_section" "pkg_dirs")
                _t_silent=$(get_ini_value "$CONFIG_FILE" "$_section" "silent")
                _t_direct=$(get_ini_value "$CONFIG_FILE" "$_section" "direct")

                # Apply Global Silent logic if not overridden by task?
                # Usually command line flag overrides config.
                _eff_silent=$_t_silent
                [ "$_silent" == "true" ] && _eff_silent="true"

                process_symlink_task "$_section" "$_t_target" "$_t_pkg_dirs" "$_eff_silent" "$CONFIG_FILE" "$DOTFILES_DIR" "$_t_direct"
            fi
        fi
    done

    msg_title "Report"
    msg_success "Done"
}
