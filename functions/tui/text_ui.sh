#!/usr/bin/env bash
#
# text_ui
#
# ====================================================================================================

text_ui() {
    local _source="${BASH_SOURCE[0]}"
    while [ -h "$_source" ]; do
        local _dir="$(cd -P "$(dirname "$_source")" && pwd)"
        _source="$(readlink "$_source")"
        [[ $_source != /* ]] && _source="$_dir/$_source"
    done
    local _source_dir="$(cd -P "$(dirname "$_source")" && pwd)"

    # colors
    source "$_source_dir/colors.sh"

    # utils
    source "$_source_dir/platform_helpers.sh"
    source "$_source_dir/logger.sh"

    # messages
    source "$_source_dir/message.sh"

    # dummy functions for TUI elements to avoid errors if called
    checkbox_input() { :; }
    progress_bar_tag() { :; }
}

text_ui
