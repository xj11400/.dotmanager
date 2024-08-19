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
- Execute the `dot.sh` script under the repository.

### Esecute dot.sh

```
Usage:
  ./dot.sh [OPTIONS]

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

## Directory Structure

`target_dir` : default is `$HOME`
`dotfiles_dir` : `$HOME/.dotfiles`

If `~/.dotfiles/zsh` directory is specified to link, it will create the symbolic links as follows:

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
