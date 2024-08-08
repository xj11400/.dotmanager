#!/usr/bin/env bash
#
# tui
#
# ====================================================================================================

tui() {
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

    # progress bar
    source "$_source_dir/progress_bar.sh"

    # prompts
    # shellcheck disable=SC1091
    source "$_source_dir/message.sh"
    source "$_source_dir/question.sh"

    # interactive prompts
    # modified from: https://github.com/kahkhang/Inquirer.sh
    source "$_source_dir/general.sh"
    source "$_source_dir/checkbox_input.sh"
    source "$_source_dir/list_input.sh"
    source "$_source_dir/text_input.sh"

}

tui

#
# Examples
#
# # logger
# log_debug "debug message"
# log_info "info message"
# log_warn "warn message"
# log_error "error message"
# log_debug_t "debug message with timestamp"
# log_info_t "info message with timestamp"
# log_warn_t "warn message with timestamp"
# log_error_t "error message with timestamp"
# # message
# msg_error "This is an error message"
# msg_success "This is a success message"
# msg_warning "This is a warning message"
# msg_hint "This is a hint message"
# msg_question "This is a question message"
# msg_step "This is a step message"
# msg "This is a message"
# question
# pass=$(password "Enter password to use")
# echo $pass
# ans=$(confirm "Are you sure?")
# echo $ans
# ans=$(confirm "Are you sure?" "y")
# echo $ans

# # text input
# text_input "Enter text" text "default_value"
# echo $text

# # items for checkbox, list and progress bar
# items=("A" "B" "C" "D" "E" "F" "G" "H" "I" "J")
# # checkbox input
# chk_selected=("E" "H")
# checkbox_input "Select items" "x" items chk_selected
# echo $chk_selected
# checkbox_input_indices "Select items" "x" items chk_selected
# echo $chk_selected
# # list input
# list_selected=""
# list_input "Select items" "x" items list_selected
# echo $list_selected
# list_input_index "Select items" "x" items list_selected
# echo $list_selected
# # progress bar
# _idx=0
# _opts_count=$((${#items[@]}))
# for _item in "${items[@]}"; do
#     progress_bar_tag $_item 50 $_idx ${_opts_count}
#     sleep 0.1
#     _idx=$((_idx + 1))
# done
# progress_bar_tag "done" 50 $_idx ${_opts_count}
