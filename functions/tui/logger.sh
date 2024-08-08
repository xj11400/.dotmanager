#!/usr/bin/env bash
#
# logger
#
# ====================================================================================================

# Log levels
LOG_LEVEL_DEBUG=0
LOG_LEVEL_INFO=1
LOG_LEVEL_WARN=2
LOG_LEVEL_ERROR=3

# Set the default log level (change this as needed)
LOG_LEVEL=$LOG_LEVEL_ERROR

# Set the log level
# Usage:
#   set_log_level "ERROR"
#   set_log_level $LOG_LEVEL_ERROR
#   set_log_level 3
set_log_level() {
    local level="$1"
    local parsed

    case "${level}" in
    info | INFO) parsed=$LOG_LEVEL_INFO ;;
    debug | DEBUG) parsed=$LOG_LEVEL_DEBUG ;;
    warn | WARN) parsed=$LOG_LEVEL_WARN ;;
    error | ERROR) parsed=$LOG_LEVEL_ERROR ;;
    $LOG_LEVEL_DEBUG) parsed=$LOG_LEVEL_DEBUG ;;
    $LOG_LEVEL_INFO) parsed=$LOG_LEVEL_INFO ;;
    $LOG_LEVEL_WARN) parsed=$LOG_LEVEL_WARN ;;
    $LOG_LEVEL_ERROR) parsed=$LOG_LEVEL_ERROR ;;
    *) parsed=-1 ;;
    esac

    export LOG_LEVEL="${parsed}"
}

# Function to log messages
log_message() {
    local level=$1
    local message=$2
    local color=""

    if [[ $level -lt ${LOG_LEVEL:-$LOG_LEVEL_INFO} ]]; then
        return
    fi

    # Compare log levels and print the message if the log level is greater than or equal to the current log level
    if [ $level -ge $LOG_LEVEL ]; then
        case $level in
        $LOG_LEVEL_INFO)
            level="INFO"
            color='\033[1;34m'
            ;;
        $LOG_LEVEL_DEBUG)
            level="DEBUG"
            color='\033[1;32m'
            ;;
        $LOG_LEVEL_WARN)
            level="WARN"
            color='\033[0;33m'
            ;;
        $LOG_LEVEL_ERROR)
            level="ERROR"
            color='\033[0;31m'
            ;;
        *)
            level="UNKNOWN"
            color='\033[0;37m'
            ;;
        esac
    fi

    # Get the current timestamp
    # Check if a custom timestamp format is provided
    if [ -n "$3" ]; then
        if [ "$3" == "timestamp" ]; then
            local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
        else
            local timestamp=$(date +"$3")
        fi
    else
        local timestamp=""
    fi

    printf "[${color}%-5s\033[0m] \033[1;30m%s\033[0m %s\n" "${level}" "${timestamp}" "${message}" >&2
}

# Wrapper functions
log_debug() {
    log_message $LOG_LEVEL_DEBUG "$1"
}

log_info() {
    log_message $LOG_LEVEL_INFO "$1"
}

log_warn() {
    log_message $LOG_LEVEL_WARN "$1"
}

log_error() {
    log_message $LOG_LEVEL_ERROR "$1"
}

log_debug_t() {
    log_message $LOG_LEVEL_DEBUG "$1" "timestamp"
}

log_info_t() {
    log_message $LOG_LEVEL_INFO "$1" "timestamp"
}

log_warn_t() {
    log_message $LOG_LEVEL_WARN "$1" "timestamp"
}

log_error_t() {
    log_message $LOG_LEVEL_ERROR "$1" "timestamp"
}
