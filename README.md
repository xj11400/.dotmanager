# .DotManager

A simple dotfiles manager written in shell script for environments without nix or stow.
It creates symbolic links to the target directory.

## Usage

To use DotManager with your dotfiles:

### Using Configuration and Setup Script

1. Copy the files from the [template](./template) directory to your root dotfiles directory:

   - [.config.ini](./template/.config.ini) ( **`.config.ini` file is optional.** )
   - [dot_setup.sh](./template/dot_setup.sh)

2. Modify the `.config.ini` file to suit your needs following [the instructions](./template/README.md).
3. Execute the `dot_setup.sh` script.

### Using Repository Only

- Clone the repository to your exist dotfiles directory.
- Execute the `xdots` script under the repository.

### Execute xdots

- `xdots [OPTIONS]`

  ```
  Usage: xdots [OPTIONS]

  Options:
    dot                   Dot Manager
    symlink               Create symbolic links
    update                Update specified directories
    dot-update            Update .dotmanager
    --help, -h            Display this help message
  ```

- `xdots dot [OPTIONS]`

  ```
  Usage:
    xdots dot [OPTIONS]

  (no options)
    Clone and update repositories in config file (if exists), and
    create symbolic links under dotfiles directory to target path.

  Options:
    --update              Clone and update repositories in config file
    --repos-update        Update all repositories without recreating symlinks
    --silent              Run in silent mode, without interactive
    --help, -h            Display this help message

  Specify options:
    --source_dir=<path>   Specify a custom dotfiles directory
    --target_dir=<path>   Specify a custom target directory
    --config_file=<path>  Specify a custom configuration file path

  Default values:
    dotfiles directory: caller path
    target directory: the parent of dotfiles directory
    config file: .config.ini under the dotfiles directory
  ```

- `xdots symlink [OPTIONS]`

  ```
  Usage: $0 [OPTIONS] <directory>

  Options:
    --files               Create a symlink for each file in the directory
    --resymlink           Resymlink existing symlinks or create new symlinks
    --help, -h            Display this help message

  Specify options:
    --source=<path>  Specify a custom dotfiles directory
    --target=<path>  Specify a custom target directory
  ```

- `xdots update [OPTIONS]`

  ```
  Usage: xdots update [DIRECTORIES...]
  ```

## Directory Structure

When running `sh dot_setup.sh` under `~/.dotfiles` and specifying the `~/.dotfiles/zsh` directory to link, it will create the symbolic links as follows:

`target_dir` : `$HOME` (The default is the parent directory of the caller.)
`dotfiles_dir` : `$HOME/.dotfiles`

```
$HOME/
├── .config
│   └── zsh
│       ├── .zsh_plugins.txt -> .dotfiles/zsh/.config/.zsh_plugins.txt
│       └── .zshrc -> .dotfiles/zsh/.config/.zshrc
├── .zshenv -> .dotfiles/zsh/.zshenv
│
├── .dotfiles
│   ├── zsh
│   │   ├── .zshenv
│   │   └── .config
│   │       ├── .zsh_plugins.txt
│   │       └── .zshrc
│   │
│   ├── .dotmanager/*             # .DotManager directory
│   │── .config.ini               # configuration file (optional)
│   └── dot_setup.sh              # setup script (optional)
│
└── template/
```
