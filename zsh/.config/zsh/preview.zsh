#!/usr/bin/env zsh
# ==============================================================================
# Universal preview dispatcher for fzf (preview.zsh)
# Powered by Kitty, bat, eza, ffmpeg/ffprobe, and native archive inspection
# ==============================================================================

local target="${1:-}"

# Clear any lingering Kitty terminal graphics from previous preview
clear_graphics() {
    if [[ -n "$KITTY_WINDOW_ID" || "$TERM" == *kitty* ]]; then
        printf "\033_Ga=d,d=A\033\\"
    fi
}

if [[ -z "$target" || ! -e "$target" ]]; then
    clear_graphics
    echo "No file or directory selected"
    exit 0
fi

# 1. Directories (visual tree via eza)
if [[ -d "$target" ]]; then
    clear_graphics
    if command -v eza >/dev/null 2>&1; then
        eza --tree --level=2 --icons --color=always "$target" | head -n 100
    else
        ls -la "$target" | head -n 100
    fi
    exit 0
fi

# Lowercased filename and MIME type
local filename="${target:t:l}"
local mime
mime=$(file --mime-type -bL "$target" 2>/dev/null || echo "")

# Helper to render images using Kitty icat protocol
display_image() {
    local img="$1"
    local cols="${FZF_PREVIEW_COLUMNS:-80}"
    local lines="${FZF_PREVIEW_LINES:-30}"

    if command -v kitty >/dev/null 2>&1; then
        kitty +kitten icat --clear --transfer-mode=memory --stdin=no --align center --place="${cols}x${lines}@0x0" "$img"
    else
        file -b "$img"
        if command -v sips >/dev/null 2>&1; then
            echo ""
            sips -g pixelWidth -g pixelHeight "$img" 2>/dev/null
        fi
    fi
}

# 2. Archives (in-memory streaming inspection - zero disk writes)
case "$filename" in
    *.zip)
        clear_graphics
        echo -e "\033[1;34m📦 ZIP Archive Contents (in-memory):\033[0m\n"
        if command -v zipinfo >/dev/null 2>&1; then
            zipinfo -l "$target" | head -n 100
        else
            unzip -l "$target" | head -n 100
        fi
        exit 0
        ;;
    *.tar|*.tar.gz|*.tgz|*.tar.bz2|*.tbz2|*.tar.xz|*.txz)
        clear_graphics
        echo -e "\033[1;34m📦 TAR Archive Contents (in-memory):\033[0m\n"
        tar -tvf "$target" | head -n 100
        exit 0
        ;;
    *.gz)
        clear_graphics
        echo -e "\033[1;34m📦 GZIP Compressed File (in-memory):\033[0m\n"
        gzip -l "$target" 2>/dev/null || file -b "$target"
        exit 0
        ;;
    *.7z)
        clear_graphics
        echo -e "\033[1;34m📦 7-Zip Archive (in-memory):\033[0m\n"
        if command -v 7z >/dev/null 2>&1; then
            7z l "$target" | head -n 100
        else
            file -b "$target"
        fi
        exit 0
        ;;
esac

# 3. PDF Documents
if [[ "$filename" == *.pdf || "$mime" == "application/pdf" ]]; then
    clear_graphics
    echo -e "\033[1;31m📄 PDF Document\033[0m\n"
    if command -v pdftotext >/dev/null 2>&1; then
        pdftotext -l 5 -nopgbrk -q "$target" - | head -n 80
    else
        file -b "$target"
        echo -e "\n\033[33mInstall 'poppler' (pdftotext) to preview PDF contents in terminal:\033[0m"
        echo "  - macOS: brew install poppler"
        echo "  - Linux: sudo apt install poppler-utils / sudo pacman -S poppler"
    fi
    exit 0
fi

# 4. Images (Kitty icat)
case "$mime" in
    image/*)
        display_image "$target"
        exit 0
        ;;
esac

case "$filename" in
    *.png|*.jpg|*.jpeg|*.gif|*.webp|*.svg|*.bmp|*.ico)
        display_image "$target"
        exit 0
        ;;
esac

# 5. Videos (metadata + frame thumbnail without sound)
case "$mime" in
    video/*)
        clear_graphics
        echo -e "\033[1;35m🎬 Video Information\033[0m\n"
        if command -v ffprobe >/dev/null 2>&1; then
            ffprobe -v error -select_streams v:0 \
                -show_entries stream=width,height,codec_name,r_frame_rate \
                -show_entries format=duration,size,bit_rate \
                -of default=noprint_wrappers=1 "$target" 2>/dev/null
            echo ""
        else
            file -b "$target"
        fi

        # Extract silent thumbnail preview if ffmpeg is available
        if command -v ffmpeg >/dev/null 2>&1; then
            local thumb="/tmp/fzf-vthumb-$$.jpg"
            ffmpeg -ss 00:00:01 -i "$target" -vframes 1 -f image2 -y "$thumb" >/dev/null 2>&1
            if [[ -f "$thumb" ]]; then
                echo -e "\033[1;36mFrame Thumbnail (00:00:01):\033[0m"
                display_image "$thumb"
                rm -f "$thumb"
            fi
        fi
        exit 0
        ;;
esac

# 6. Plain text, code, configs (bat)
if [[ "$mime" =~ "^text/" || "$mime" == "application/json" || "$mime" == "application/xml" || "$mime" == "application/javascript" || -z "$mime" ]]; then
    clear_graphics
    if command -v bat >/dev/null 2>&1; then
        bat --color=always --style=plain,numbers --line-range=:500 "$target"
    else
        head -n 100 "$target"
    fi
    exit 0
fi

# 7. Unknown Binary (hexdump)
clear_graphics
echo -e "\033[1;33m⚙️  Binary File\033[0m\n"
file -b "$target"
echo -e "\n\033[1;34m--- Hexdump Preview ---\033[0m"
hexdump -C "$target" 2>/dev/null | head -n 40
