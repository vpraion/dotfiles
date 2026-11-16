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

# Helper to render images using Kitty icat protocol with unicode placeholder
display_image() {
    local img="$1"
    local top_offset="${2:-0}"
    local cols="${FZF_PREVIEW_COLUMNS:-80}"
    local total_lines="${FZF_PREVIEW_LINES:-30}"
    local available_lines=$(( total_lines - top_offset ))
    if (( available_lines < 3 )); then
        available_lines=3
    fi

    if command -v kitty >/dev/null 2>&1; then
        local dim="${cols}x${available_lines}"
        kitty +kitten icat --clear --transfer-mode=memory --unicode-placeholder --stdin=no --align center --place="$dim@0x0" "$img" | sed '$d' | sed $'$s/$/\e[m/'
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
        display_image "$target" 0
        exit 0
        ;;
esac

case "$filename" in
    *.png|*.jpg|*.jpeg|*.gif|*.webp|*.svg|*.bmp|*.ico)
        display_image "$target" 0
        exit 0
        ;;
esac

# 5. Videos (metadata + frame thumbnail at 25% without sound)
local is_video=false
case "$mime" in
    video/*) is_video=true ;;
esac
case "$filename" in
    *.mp4|*.mkv|*.mov|*.avi|*.webm|*.flv|*.m4v) is_video=true ;;
esac

if [[ "$is_video" == true ]]; then
    clear_graphics

    local width="" height="" codec="" duration_raw="" size_bytes=""
    local formatted_duration="" formatted_size="" seek_time="00:00:01"

    if command -v ffprobe >/dev/null 2>&1; then
        width=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of default=noprint_wrappers=1:nokey=1 "$target" 2>/dev/null)
        height=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of default=noprint_wrappers=1:nokey=1 "$target" 2>/dev/null)
        codec=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "$target" 2>/dev/null)
        duration_raw=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$target" 2>/dev/null)
        size_bytes=$(ffprobe -v error -show_entries format=size -of default=noprint_wrappers=1:nokey=1 "$target" 2>/dev/null)

        # Calculate 25% seek time and format duration
        if [[ -n "$duration_raw" && "$duration_raw" != "N/A" ]]; then
            local dur_float=${duration_raw}
            local quarter_sec=$(( dur_float * 0.25 ))
            seek_time=$(printf "%.2f" "$quarter_sec")

            local total_secs=${duration_raw%.*}
            local hrs=$(( total_secs / 3600 ))
            local mins=$(( (total_secs % 3600) / 60 ))
            local secs=$(( total_secs % 60 ))
            if (( hrs > 0 )); then
                formatted_duration=$(printf "%02d:%02d:%02d" "$hrs" "$mins" "$secs")
            else
                formatted_duration=$(printf "%02d:%02d" "$mins" "$secs")
            fi
        fi

        # Format human-readable size
        if [[ -n "$size_bytes" && "$size_bytes" != "N/A" ]]; then
            if (( size_bytes > 1073741824 )); then
                formatted_size=$(printf "%.1f GB" "$(( size_bytes / 1073741824.0 ))")
            elif (( size_bytes > 1048576 )); then
                formatted_size=$(printf "%.1f MB" "$(( size_bytes / 1048576.0 ))")
            elif (( size_bytes > 1024 )); then
                formatted_size=$(printf "%.1f KB" "$(( size_bytes / 1024.0 ))")
            fi
        fi
    fi

    # Print compact 2-line header
    local res="${width}x${height}"
    [[ -z "$width" ]] && res="Video"
    local info_line="${res}"
    [[ -n "$codec" ]] && info_line="${info_line} • ${codec}"
    [[ -n "$formatted_duration" ]] && info_line="${info_line} • ${formatted_duration}"
    [[ -n "$formatted_size" ]] && info_line="${info_line} • ${formatted_size}"

    echo -e "\033[1;35m🎬 ${info_line}\033[0m"
    echo -e "\033[90m────────────────────────────────────────────────────────────\033[0m"

    local header_lines=2

    # Extract silent thumbnail preview at 25% with cache if ffmpeg is available
    if command -v ffmpeg >/dev/null 2>&1; then
        local cache_dir="/tmp/fzf-vthumb-cache"
        mkdir -p "$cache_dir"
        local file_stat
        file_stat=$(stat -f "%m-%z" "$target" 2>/dev/null || stat -c "%Y-%s" "$target" 2>/dev/null || echo "0")
        local thumb="$cache_dir/${target:t:r}_${file_stat}.jpg"

        if [[ ! -f "$thumb" ]]; then
            ffmpeg -ss "$seek_time" -i "$target" -vframes 1 -f image2 -y "$thumb" >/dev/null 2>&1
        fi

        if [[ -f "$thumb" ]]; then
            display_image "$thumb" "$header_lines"
        fi
    fi
    exit 0
fi

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
