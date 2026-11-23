#!/usr/bin/env bash
set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DOTFILES_DIR"

echo "Init submodules..."
git submodule update --init --recursive

echo "Update submodules..."
git submodule update --remote --merge
