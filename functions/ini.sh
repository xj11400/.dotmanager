#!/usr/bin/env bash
#
# ini.sh
#
# ====================================================================================================


# Function _sed_i
# Brief: A wrapper function for `sed -i` to handle in-place editing across macOS and others.
# Usage: _sed_i <sed_command> <file>
_sed_i() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i "" "$@"
    else
        # Linux and other Unix-like systems
        sed -i "$@"
    fi
}

# Function get_ini_value
# Brief: Retrieves a value from an INI file based on section and key.
# Usage: get_ini_value <ini_file> <section> <key>
# Example: get_ini_value .config.ini "section_name" "key_name"
get_ini_value() {
    local file="$1"
    local section="$2"
    local key="$3"

    local value=$(awk -F '=' -v section="$section" -v key="$key" '
        $0 ~ "^\\[" section "\\]" { in_section=1; next }
        $0 ~ "^\\[" { in_section=0 }
        in_section && $1 ~ "^[ \t]*" key "[ \t]*$" {
            sub(/^[ \t]+/, "", $2); sub(/[ \t]+$/, "", $2);
            print $2; exit
        }
    ' "$file")

    echo "$value"
}

# Function get_keys_and_values_in_section
# Brief: Lists all keys and values within a specified section of an INI file.
# Usage: get_keys_and_values_in_section <ini_file> <section>
# Example: get_keys_and_values_in_section .config.ini "section_name"
get_keys_and_values_in_section() {
    local file="$1"
    local section="$2"

    # Use awk to list keys and values
    awk -F '=' -v section="$section" '
    $0 ~ "\\[" section "\\]" { in_section=1; next }
    in_section && /^[^#;]/ && !/^\[/{ print $1"="$2 }
    /^\[/{ in_section=0 }
  ' "$file"
}

# Function get_sections_in_ini
# Brief: Lists all sections in an INI file.
# Usage: get_sections_in_ini <ini_file>
# Example: get_sections_in_ini .config.ini
get_sections_in_ini() {
    local file="$1"

    # Use awk to list all sections in one line
    awk -F '[][]' '/^\[.*\]$/ {printf "%s%s", (NR>1 ? " " : ""), $2}' "$file"
    echo ""
}

# Function get_keys_in_section
# Brief: Lists all keys within a specified section of an INI file.
# Usage: get_keys_in_section <ini_file> <section>
# Example: get_keys_in_section .config.ini "section_name"
get_keys_in_section() {
    local file="$1"
    local section="$2"

    # Use awk to extract keys from the specified section
    awk -F '=' -v section="$section" '
    $0 ~ "\\[" section "\\]" { in_section=1; next }
    in_section && /^[^#;]/ && !/^\[/ { gsub(/^[ \t]+|[ \t]+$/, "", $1); print $1 }
    /^\[/{ in_section=0 }
  ' "$file"
}

# Function update_value
# Brief: Update a value in an INI file
# Usage: update_value "file.ini" "section" "key" "new_value"
update_value() {
    local file="$1"
    local section="$2"
    local key="$3"
    local new_value="$4"
    # Use awk to update the value for the specified key in the specified section
    awk -v section="$section" -v key="$key" -v value="$new_value" '
    BEGIN { in_section = 0; updated = 0 }
    /^\[/ { in_section = 0 }
    $0 ~ "\\[" section "\\]" { in_section = 1; print; next }
    in_section && $0 ~ "^"key"[[:space:]]*=" {
        print key " = " value
        updated = 1
        next
    }
    { print }
    END {
        if (!updated) {
            print "Error: Key not found in section" > "/dev/stderr"
            exit 1
        }
    }
    ' "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"

    # Check if the update was successful
    if [ $? -ne 0 ]; then
        echo "Error: Failed to update value in $file" >&2
        return 1
    fi
}

# Function remove_key
# Brief: Remove a key-value pair from an INI file
# Usage: remove_key "file.ini" "section" "key"
remove_key() {
    local file="$1"
    local section="$2"
    local key="$3"
    _sed_i "/\\[$section\\]/,/\\[.*\\]/{/^$key[[:space:]]*=/d;}" "$file"
}

# Function remove_section
# Brief: Remove an entire section from an INI file
# Usage: remove_section "file.ini" "section"
remove_section() {
    local file="$1"
    local section="$2"
    _sed_i "/\\[$section\\]/,/\\[.*\\]/{/\\[$section\\]/d; /\\[.*\\]/!d;}" "$file"
}

# Function is_key
# Brief: Check if a key exists in a section of an INI file
# Usage: if is_key "file.ini" "section" "key"; then echo "Key exists"; fi
is_key() {
    local file="$1"
    local section="$2"
    local key="$3"
    local value=$(get_ini_value "$file" "$section" "$key")
    if [ -n "$value" ]; then
        return 0
    else
        return 1
    fi
}

# Function append_key
# Brief: Append a key-value pair to a section in an INI file
# Usage: append_key "file.ini" "section" "key" "value"
append_key() {
    local file="$1"
    local section="$2"
    local key="$3"
    local value="$4"
    _sed_i "/\\[$section\\]/a\\
$key = $value\\
" "$file"
}

# Function is_section
# Brief: Check if a section exists in an INI file
# Usage: if is_section "file.ini" "section"; then echo "Section exists"; fi
is_section() {
    local file="$1"
    local section="$2"
    grep -q "^\[$section\]" "$file"
}

# Function add_section
# Brief: Add a new section to an INI file if it doesn't exist
# Usage: add_section "file.ini" "new_section"
add_section() {
    local file="$1"
    local section="$2"
    if ! is_section "$file" "$section"; then
        echo -e "\n[$section]" >>"$file"
    fi
}

# Function get_dir_sections_in_ini
# Brief: List sections in config file, without section start with '_'
get_dir_sections_in_ini(){
    local file="$1"

    # Use awk to list all sections that don't start with '_' and end with '_' in one line
    awk -F '[][]' '/^\[.*\]$/ && !/^\[_.*_\]$/ {printf "%s%s", (NR>1 ? " " : ""), $2}' "$file"
    echo ""

}

# Function get_dir_keys_in_section
# Brief: Retrieves keys from the specified section, excluding '_' item
get_dir_keys_in_section() {
    local file="$1"
    local section="$2"

    # Use awk to extract keys from the specified section, excluding '_' item
    awk -F '=' -v section="$section" '
    $0 ~ "\\[" section "\\]" { in_section=1; next }
    in_section && /^[^#;]/ && !/^\[/ {
        gsub(/^[ \t]+|[ \t]+$/, "", $1)
        if ($1 != "_") {
            print $1
        }
    }
    /^\[/{ in_section=0 }
    ' "$file"
}

# Function update_symlink_target
# Brief: Update config file symlink target
update_symlink_target() {
    local file="$1"
    local section="$2"
    local key="$3"
    local new_value="$4"
    local value=$(get_ini_value "$file" "$section" "$key")
    if [ -n "$value" ]; then
        # update_value "$file" "$section" "$key" "$new_value"
        # Check if the existing value contains the new_value
        # if [[ "$value" == *"$new_value"* ]]; then
        #     # cause error when vim and nvim
        #     # If it does, no need to update
        #     msg_sub_step "Value for $key already contains $new_value. No update needed."
        #     return 0
        # else
        #     # If it doesn't, update the value
        #     value="$value, $new_value"
        #     update_value "$file" "$section" "$key" "$value"
        #     msg_sub_step "Appended $new_value for $key"
        # fi

        value="$value, $new_value"
        update_value "$file" "$section" "$key" "$value"
        msg_sub_step "$key append $new_value"
    else
        append_key "$file" "$section" "$key" "$new_value"
        msg_sub_step "$key add $new_value"
    fi
}