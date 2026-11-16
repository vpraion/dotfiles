#!/bin/sh

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
RESET='\033[0m'

# Core required dependencies from DEPENDENCIES.md
MISSING_CORE=""

check_dep() {
    bin_names="$1"
    pkg_name="$2"
    found=false
    for b in $bin_names; do
        if which "$b" >/dev/null 2>&1; then
            found=true
            break
        fi
    done
    if [ "$found" = false ]; then
        MISSING_CORE="${MISSING_CORE} $pkg_name"
    fi
}

check_dep "zsh" "zsh"
check_dep "git" "git"
check_dep "stow" "stow"
check_dep "fzf" "fzf"
check_dep "fd fdfind" "fd"
check_dep "bat batcat" "bat"
check_dep "eza" "eza"
check_dep "rg" "ripgrep"
check_dep "zoxide" "zoxide"
check_dep "nvim" "nvim"
check_dep "starship" "starship"
check_dep "kitty" "kitty"
check_dep "ffprobe" "ffmpeg"
check_dep "col" "col"
check_dep "mdcat" "mdcat"


if [ -z "$MISSING_CORE" ]; then
    printf "${GREEN}${BOLD}✓ All required dependencies are installed.${RESET}\n"
    exit 0
fi

# If any required dependencies are missing
printf "\n${RED}${BOLD}⚠️  Warning: Missing required dependencies:${RESET}${RED}%s${RESET}\n" "$MISSING_CORE"

OS="$(uname -s)"
printf "Please install them first:\n"
if [ "$OS" = "Darwin" ]; then
    printf "  ${BOLD}brew install%s${RESET}\n\n" "$MISSING_CORE"
elif command -v apt-get >/dev/null 2>&1; then
    printf "  ${BOLD}sudo apt update && sudo apt install%s${RESET}\n\n" "$MISSING_CORE"
elif command -v pacman >/dev/null 2>&1; then
    printf "  ${BOLD}sudo pacman -S%s${RESET}\n\n" "$MISSING_CORE"
else
    printf "  Install: %s via your distribution package manager.\n\n" "$MISSING_CORE"
fi

if [ -t 0 ] || [ -c /dev/tty ]; then
    if [ ! -t 0 ] && [ -c /dev/tty ]; then
        exec < /dev/tty
    fi
    printf "${BOLD}Do you want to continue anyway? [y/N] ${RESET}"
    read -r PROCEED
    case "$PROCEED" in
        [yY]|[yY][eE][sS])
            exit 0
            ;;
        *)
            printf "\n${RED}Setup aborted.${RESET}\n\n"
            exit 1
            ;;
    esac
else
    exit 1
fi
