# Template

Download the files from this directory to your root dotfiles directory.

- [.config.ini](.config.ini)
- [dot_setup.sh](dot_setup.sh)

## Configuration

it has three parts in the file:
- `[_configs_]` : configuration for the dotfiles
- `[_symlinks_]` : symbolic links for the dotfiles
- `[...]` : packages

```ini
; -- configs --
; target_dir : the directory to create symbolic links (default: $HOME) (optional)
; pkg_dirs : which directory under dotfiles directory has packages to scan which is not in the declared below (optional)
[_configs_]
;target_dir = $HOME
pkg_dirs = utils, apps, packages, custom

; -- symbolic links --
; key : the name of the repository directory
;       if the key is '_', it means the root of the dotfiles directory
;       the key should be the name of section name that given below or declared in the pkg_dirs
; value : packages been selected under the repository directory
;
; options: (separated by '|' and added to the front of the list)
;    --files : every files will be linked.
;    otherwise, will link files and directories under the target directory.
[_symlinks_]
; _ : the underline means the root of the dotfiles directory
; 'repo_only': the package been selected under key directory
_ = repo_only
; packages means there have a repository directory under the dotfiles directory named packages
; 'zsh, nvim, ...' : the packages been selected under the packages directory
packages=--files | zsh, nvim, tmux, git, lazygit
; 'custom' means there have a repository directory under the dotfiles directory named custom
; 'ranger, wezterm...' : the packages been selected under the custom directory
custom= ranger, wezterm


; -- packages --
; [pkg_dir] : the name of the directory will be created under the dotfiles directory
; key = value
;
;  key : the name of the repository directory and the repository will be cloned to the directory under the pkg_dir
;        if the key is '_', it means the root of the pkg_dir
;  value : the url of the repository
;
; ! NOTE ! If this is a packages directory, add it to [_configs_] pkg_dirs

; packages
[packages]
_ = https://github.com/xj11400/.dotfiles.git
zsh = https://github.com/xj11400/dot-zsh.git
; following the url, can give the branch name as git command
nvim = https://github.com/xj11400/dot-nvim.git --branch=zx
tmux = https://github.com/xj11400/dot-tmux.git

[custom]
_ = https://github.com/xj11400/dot_custom.git
wezterm = https://github.com/xj11400/dot-wezterm.git
x_deploy = https://github.com/xj11400/dot_deploy.git

[repo_only]
_ = https://github.com/xj11400/dot-tmux.git

[folder_only]
custom = https://github.com/xj11400/dot-tmux.git

```

## Directory Structure

```
.dotfiles                             # the root directory of the dotfiles
├── _fonts/                           # won't be scanned with name prefix with '_' and '.'
├── utils/                            # directory under the root directory
├── apps/                             # directory under the root directory
│
├── .config.ini                       # configuration for the dotfiles
├── dot_setup.sh                      # setup script
├── .dot/...                          # DotManager clone by the dot_setup.sh
│
├── packages                          # packages in xj11400/.dotfiles.git
│   ├── git/.config/git/
│   ├── lazygit/.config/lazygit/
│   ├── ranger/.config/ranger/
│   ├──       .
│   ├──       .
│   ├──       . 
│   │
│   ├── nvim/.config/nvim/            # packages in xj11400/.dot-nvim.git
│   ├── tmux/.config/tmux/            # packages in xj11400/.dot-tmux.git
│   └── zsh/.config/zsh/              # packages in xj11400/.dot-zsh.git
│
├── custom                            # packages in xj11400/.dot_custom.git
│   ├── ranger/.config/ranger/
│   ├──       .
│   ├──       .
│   ├──       . 
│   │
│   ├── x_deploy/...                  # packages in xj11400/.dot_deploy.git
│   └── wezterm/.config/wezterm/      # packages in xj11400/.dot-wezterm.git
│
├── repo_only                         # packages in xj11400/.dot-tmux.git
│   └── .config/tmux/
│
├── folder_only
│   └── tmux/.config/tmux/            # packages in xj11400/.dot-tmux.git
│
└── README.md
```

