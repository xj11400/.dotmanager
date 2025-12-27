# Template

Download the files from this directory to your root dotfiles directory.

- [.config.ini](.config.ini)
- [dot_setup.sh](dot_setup.sh)

## Configuration

The `.config.ini` file controls how `dotmanager` manages your dotfiles effectively.

### Structure Overview

The configuration is divided into three main parts:

- `[_configs_]` : Global configuration blocks (currently optional/placeholders).
- `[_repos_]` : Marker for repository definitions. All sections following this are treated as repositories to clone/update.
- `[_symlinks_]` : Marker for symlink tasks. All sections following this are independent **Tasks**.

### 1. Repositories `[_repos_]`

Define git repositories to clone. The section name determines the directory structure.

```ini
[_repos_]

; Clone into .dotfiles/packages/
[packages]
zsh = https://github.com/xj11400/dot-custom.git
dev = https://github.com/xj11400/dot-custom.git --branch=dev

; Clone into .dotfiles/custom/
[custom]
_ = https://github.com/xj11400/dot-custom.git
```

### 2. Symlink Tasks `[_symlinks_]`

After `[_symlinks_]`, each section (e.g., `[main]`, `[local]`) defines a separate symlinking task with its own scope.

#### Task Options

Always place these options at the top of the task section:

- `target_dir`: Where to create symlinks (e.g., `$HOME`, `$HOME/.config`). Defaults to parent of dotfiles dir.
- `pkg_dirs`: Which subdirectories in `.dotfiles/` to scan for items.
  - `_` : Represents the root `.dotfiles/` directory.
  - Directories starting with `_` or `.` are ignored by default unless explicitly listed here.
- `silent`: Set to `true` to skip interactive selection for this task.
- `direct`: Set to `true` to enable Direct Mode.
  - In Direct Mode, items are linked into a subdirectory of `target_dir` matching the item name (GNU Stow-style).
  - Example: `pkg_dirs/_/git` linked to `target_dir` will result in `target_dir/git/...`.
  - Without Direct Mode, contents are linked directly into `target_dir` (flattened).

#### Link Rules

Define what to link using the format:
`group = [options |] item1, item2...`

- **Group**: Matches a directory in `pkg_dirs` (e.g., `_`, `_user`, `packages`).
- **Options**:
  - `--files`: Link individual files inside the directory instead of the directory itself.
  - `--skip`: Skip if target already exists (don't error).
  - `--resymlink`: Force re-creation of symlinks.

### Example

```ini
[_symlinks_]

[dotfiles]
target_dir = $HOME
pkg_dirs = _, _user
silent = false

; Link 'fsh' and 'git' from root (_) dir, linking individual files
_ = --files | fsh, git

; Link 'nvim' from '_user' dir
_user = nvim
```

## Directory Structure

```text
.dotfiles                             # the root directory of the dotfiles
│
│                                     # ----- only need to create these two files  -----
├── .config.ini                       # configuration for the dotfiles
├── dot_setup.sh                      # setup script
│
│                                     # ----- downloaded by the dot_setup.sh -----------
├── .dotmanager/...                   # DotManager clone by the dot_setup.sh
│
│                                     # ----- already exists in the root directory -----
├── _fonts/                           # won't be scanned with name prefix with '_' and '.'
├── utils/                            # directory under the root directory
├── apps/                             # directory under the root directory
│
│                                     # ----- downloaded by the .dotmanager ------------
├── packages                          # packages in xj11400/.dotfiles.git
│   ├── git/.config/git/
│   ├── lazygit/.config/lazygit/
│   ├── ranger/.config/ranger/
│   ├──       .
│   ├──       .
│   ├──       . 
│   │
│   ├── nvim/.config/nvim/            # packages in xj11400/.dot-custom.git
│   ├── tmux/.config/tmux/            # packages in xj11400/.dot-custom.git
│   └── zsh/.config/zsh/              # packages in xj11400/.dot-custom.git
│
├── custom                            # packages in xj11400/.dot-custom.git
│   ├── zsh/.config/zsh/
│   ├──       .
│   ├──       .
│   ├──       .
│   │
│   ├── foo/...                       # packages in xj11400/.dot-custom.git
│   └── bar/...                       # packages in xj11400/.dot-custom.git
│
├── folder_only
│   └── xxx/...                       # packages in xj11400/.dot-custom.git
│
└── README.md
```
