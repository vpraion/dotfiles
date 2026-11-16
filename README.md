# Dotfiles

My minimalist, portable, and modern dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/) and following the [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html).

---

## ⚡ Quick Start

Clone the repository and run the setup script:

```sh
git clone https://github.com/vpraion/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./setup.sh
```

The `setup.sh` script will:
1. Verify required dependencies using `./check-dependencies.sh`.
2. Configure your Git identity in a local, unversioned `config.local` (keeping the repository clean).
3. Safely check for existing files/directories in `$HOME` before linking.
4. Symlink all configuration packages into your `$HOME` directory using `stow`.

---

## 🧰 Features & Structure

Each top-level directory mirrors the destination layout relative to `$HOME`:

```text
~/.dotfiles/
├── git/
│   └── .config/git/
│       ├── config              # Global Git settings & include for config.local
│       ├── commit-template.txt # Conventional Commits template
│       ├── ignore              # Global gitignore (.DS_Store, Thumbs.db, etc.)
│       └── hooks/
│           ├── commit-msg      # POSIX hook enforcing Conventional Commits
│           └── pre-commit      # Safety hook (secrets, merge conflicts, large files)
├── zsh/
│   ├── .zshenv                 # Sets XDG paths and environment
│   └── .config/zsh/            # Aliases, keybindings, plugins, prompt, zoxide
├── check-dependencies.sh       # Standalone dependency validator
└── setup.sh                    # Interactive setup & stow orchestrator
```

### Git Highlights
- **Conventional Commits**: Enforced out-of-the-box via a pure POSIX `commit-msg` hook (zero Node.js/npm dependencies).
- **Safety Pre-Commit Hook**: Interactively warns before committing private keys, `.env` files, unresolved merge conflicts, or large files (> 10 MB) on their initial introduction.
- **Commit Template**: Provides an in-editor cheatsheet with allowed commit types and formatting rules.
- **Clean Local Identity**: Machine-specific identity is stored in `git/.config/git/config.local` (ignored by Git).

---

## 📦 Dependencies

### Core (Required)

| Tool | Purpose |
| :--- | :--- |
| [zsh](https://www.zsh.org/) | Primary shell |
| [git](https://git-scm.com/) | Version control |
| [stow](https://www.gnu.org/software/stow/) | Symlink manager |
| [fzf](https://github.com/junegunn/fzf) | Fuzzy finder |
| [fd](https://github.com/sharkdp/fd) | Fast `find` alternative |
| [bat](https://github.com/sharkdp/bat) | Syntax-highlighted cat and man pager |
| [eza](https://github.com/eza-community/eza) | Modern `ls` replacement |
| [ripgrep](https://github.com/burntsushi/ripgrep) | Fast `grep` replacement |
| [zoxide](https://github.com/ajeetdsouza/zoxide) | Smarter directory navigation |
| [nvim](https://neovim.io/) | Text editor |
| [col](https://linuxcommandlibrary.com/man/col) | Utlized by `MANPAGER` configuration |
### Optional

| Tool | Purpose |
| :--- | :--- |
| [kitty](https://sw.kovidgoyal.net/kitty/) | GPU-accelerated terminal emulator |

---

## 🔄 Maintenance & Updates

You can safely re-run `./setup.sh` at any time to refresh symlinks or update configurations:

```sh
./setup.sh
```
