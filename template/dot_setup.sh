#!/bin/bash

# Check if .dot folder exists in the same directory
if [ ! -d "./.dotmanager" ]; then
    echo "cloning .dotmanager"
    git clone --depth 1 https://github.com/xj11400/.dotmanager.git .dotmanager
fi

# source ./.dotmanager/xdots dot --config_file=<config_file_path> --target_dir=<target_dir_path> --silent
source ./.dotmanager/xdots dot
