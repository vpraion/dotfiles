#!/usr/bin/env sh
set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DOTFILES_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
RESET='\033[0m'

printf "\n${BLUE}${BOLD}=== Dotfiles Setup ===${RESET}\n\n"

# 1. Check dependencies
if [ -f "$DOTFILES_DIR/check-dependencies.sh" ]; then
    "$DOTFILES_DIR/check-dependencies.sh" || exit 1
fi

# 2. Initialize and update submodules
if [ -d "$DOTFILES_DIR/.git" ]; then
    printf "\n${BOLD}==> Initializing Git submodules...${RESET}\n"
    git -C "$DOTFILES_DIR" submodule update --init --recursive
    printf "\n${BOLD}==> Updating Git submodules...${RESET}\n"
    git submodule update --remote
fi

# 3. Git identity configuration (config.local)
GIT_CONFIG_DIR="$DOTFILES_DIR/git/.config/git"
GIT_LOCAL_CONFIG="$GIT_CONFIG_DIR/config.local"

mkdir -p "$GIT_CONFIG_DIR"

configure_git_identity=true

if [ -f "$GIT_LOCAL_CONFIG" ]; then
    CURRENT_LOCAL_NAME="$(git config -f "$GIT_LOCAL_CONFIG" user.name 2>/dev/null || echo "")"
    CURRENT_LOCAL_EMAIL="$(git config -f "$GIT_LOCAL_CONFIG" user.email 2>/dev/null || echo "")"
    printf "\nExisting Git identity found: ${BOLD}%s <%s>${RESET}\n" "$CURRENT_LOCAL_NAME" "$CURRENT_LOCAL_EMAIL"
    printf "Do you want to reconfigure it? [y/N] "
    read -r RECONFIGURE
    case "$RECONFIGURE" in
        [yY]|[yY][eE][sS])
            configure_git_identity=true
            ;;
        *)
            configure_git_identity=false
            ;;
    esac
fi

if [ "$configure_git_identity" = true ]; then
    printf "\n${BOLD}==> Configuring Git identity...${RESET}\n"
    printf "Are you vpraion? [Y/n] "
    read -r IS_VPRAION
    IS_VPRAION="${IS_VPRAION:-y}"

    case "$IS_VPRAION" in
        [yY]|[yY][eE][sS])
            GIT_NAME="vpraion"
            GIT_EMAIL="vpraion@proton.me"
            ;;
        *)
            DEFAULT_NAME="$(git config --global user.name 2>/dev/null || echo "")"
            DEFAULT_EMAIL="$(git config --global user.email 2>/dev/null || echo "")"

            printf "Enter your Git name [%s]: " "$DEFAULT_NAME"
            read -r INPUT_NAME
            GIT_NAME="${INPUT_NAME:-$DEFAULT_NAME}"

            printf "Enter your Git email [%s]: " "$DEFAULT_EMAIL"
            read -r INPUT_EMAIL
            GIT_EMAIL="${INPUT_EMAIL:-$DEFAULT_EMAIL}"
            ;;
    esac

    if [ -n "$GIT_NAME" ] && [ -n "$GIT_EMAIL" ]; then
        cat << EOF > "$GIT_LOCAL_CONFIG"
[user]
	name = $GIT_NAME
	email = $GIT_EMAIL
EOF
        printf "${GREEN}✓ Identity saved to: git/.config/git/config.local (${BOLD}%s <%s>${RESET}${GREEN})${RESET}\n" "$GIT_NAME" "$GIT_EMAIL"
    fi
fi

# 4. Check for existing directories or conflicting files in $HOME
printf "\n${BOLD}==> Checking target files and directories in %s...${RESET}\n" "$HOME"
EXISTING_TARGETS=""
CONFLICTING_FILES=""

is_already_stowed() {
    target_path="$1"
    # Case 1: The target itself is a symlink pointing to .dotfiles
    if [ -L "$target_path" ]; then
        link="$(readlink "$target_path" 2>/dev/null || echo "")"
        case "$link" in
            *".dotfiles"*) return 0 ;;
        esac
    fi

    # Case 2: The target is a directory containing files already symlinked to .dotfiles
    if [ -d "$target_path" ]; then
        for f in "$target_path"/* "$target_path"/.[!.]*; do
            [ -L "$f" ] || continue
            link="$(readlink "$f" 2>/dev/null || echo "")"
            case "$link" in
                *".dotfiles"*) return 0 ;;
            esac
        done
    fi

    return 1
}

for pkg_dir in "$DOTFILES_DIR"/*/; do
    [ -d "$pkg_dir" ] || continue
    pkg="$(basename "$pkg_dir")"
    case "$pkg" in
        .git|.github|node_modules)
            continue
            ;;
    esac

    # Check top-level items and subdirectories
    for item in "$pkg_dir"/* "$pkg_dir"/.[!.]*; do
        [ -e "$item" ] || continue
        rel_path="${item#$pkg_dir/}"
        target="$HOME/$rel_path"

        if [ "$rel_path" = ".config" ] && [ -d "$item" ]; then
            for sub_item in "$item"/*; do
                [ -e "$sub_item" ] || continue
                sub_rel="${sub_item#$pkg_dir/}"
                sub_target="$HOME/$sub_rel"
                if [ -e "$sub_target" ] || [ -L "$sub_target" ]; then
                    if ! is_already_stowed "$sub_target"; then
                        EXISTING_TARGETS="${EXISTING_TARGETS}  - $sub_target\n"
                    fi
                fi
            done
        else
            if [ -e "$target" ] || [ -L "$target" ]; then
                if ! is_already_stowed "$target"; then
                    EXISTING_TARGETS="${EXISTING_TARGETS}  - $target\n"
                fi
            fi
        fi
    done

    # Check for direct conflicting regular files (e.g. non-symlink .zshrc)
    while IFS= read -r src_file; do
        [ -n "$src_file" ] || continue
        rel_file="${src_file#$pkg_dir/}"
        dest_file="$HOME/$rel_file"
        if [ -f "$dest_file" ] && [ ! -L "$dest_file" ]; then
            CONFLICTING_FILES="${CONFLICTING_FILES}$dest_file\n"
        fi
    done <<EOF
$(find "$pkg_dir" -type f 2>/dev/null)
EOF
done

if [ -n "$EXISTING_TARGETS" ] || [ -n "$CONFLICTING_FILES" ]; then
    printf "${YELLOW}${BOLD}⚠️  Warning: The following target directories/files already exist in \$HOME:${RESET}\n"
    if [ -n "$EXISTING_TARGETS" ]; then
        printf "$EXISTING_TARGETS"
    fi
    if [ -n "$CONFLICTING_FILES" ]; then
        printf "$CONFLICTING_FILES" | sed 's/^/  - /'
    fi
    printf "\nStow will link your dotfiles into or over these existing locations.\n"
    printf "${BOLD}Do you want to continue and override/link them? [y/N] ${RESET}"
    read -r PROCEED_OVERRIDE
    case "$PROCEED_OVERRIDE" in
        [yY]|[yY][eE][sS])
            printf "${YELLOW}Proceeding with symlinks...${RESET}\n"
            # Remove any conflicting regular files so stow can create clean symlinks
            if [ -n "$CONFLICTING_FILES" ]; then
                printf "%b" "$CONFLICTING_FILES" | while IFS= read -r f; do
                    [ -f "$f" ] && [ ! -L "$f" ] && rm -f "$f"
                done
            fi
            ;;
        *)
            printf "\n${RED}Setup aborted by user.${RESET}\n\n"
            exit 1
            ;;
    esac
fi

# 5. Stow all packages into $HOME
printf "\n${BOLD}==> Stowing packages to %s...${RESET}\n" "$HOME"

for dir in "$DOTFILES_DIR"/*/; do
    [ -d "$dir" ] || continue
    package="$(basename "$dir")"

    case "$package" in
        .git|.github|node_modules)
            continue
            ;;
    esac

    printf "  -> Stowing ${BOLD}%s${RESET}... " "$package"
    stow -d "$DOTFILES_DIR" -t "$HOME" -R "$package"
    printf "${GREEN}done${RESET}\n"
done

# 6. Prompt to set Zsh as default shell if needed
ZSH_BIN="$(which zsh 2>/dev/null || echo "")"
CURRENT_SHELL_NAME="$(basename "${SHELL:-}" 2>/dev/null || echo "")"

if [ -n "$ZSH_BIN" ] && [ "$CURRENT_SHELL_NAME" != "zsh" ]; then
    printf "\n${YELLOW}${BOLD}Current default shell is: %s${RESET}\n" "${SHELL:-unknown}"
    printf "${BOLD}Do you want to set Zsh as your default shell (chsh -s %s)? [y/N] ${RESET}" "$ZSH_BIN"
    read -r SET_ZSH
    case "$SET_ZSH" in
        [yY]|[yY][eE][sS])
            if chsh -s "$ZSH_BIN"; then
                printf "${GREEN}✓ Default shell changed to %s.${RESET}\n" "$ZSH_BIN"
            else
                printf "${RED}[WARN] Could not change shell automatically. You can run manually: chsh -s %s${RESET}\n" "$ZSH_BIN"
            fi
            ;;
        *)
            printf "Keeping current default shell.\n"
            ;;
    esac
fi

printf "\n${GREEN}${BOLD}✓ Setup complete! All configurations are linked.${RESET}\n\n"
