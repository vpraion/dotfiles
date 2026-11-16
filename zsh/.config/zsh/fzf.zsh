# =========================================================
# fzf
# =========================================================

export FZF_DEFAULT_COMMAND='fd --type f --hidden --strip-cwd-prefix'  # strip-cwd-prefix removes the leading ./ from results

# Ctrl-T uses fd
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

# UI
export FZF_DEFAULT_OPTS='
  --height=60%
  --layout=reverse
  --border=rounded
  --prompt="  "
  --pointer="  "
  --preview-window=right:65%:wrap:border-left
'

export _FZF_PREVIEW_CMD='bat --color=always --style=plain,numbers --line-range=:500 {}'
export FZF_CTRL_T_OPTS="--preview '$_FZF_PREVIEW_CMD'"

# Ctrl+F: file picker excluding hidden files
_fzf_file_no_hidden() {
  local cmd result
  cmd="${FZF_DEFAULT_COMMAND/--hidden /}"
  result=$(eval "${cmd:-find . -type f}" | fzf --preview "$_FZF_PREVIEW_CMD") \
    && LBUFFER+="$result"  # LBUFFER is the text left of the cursor
  zle reset-prompt
}
zle -N _fzf_file_no_hidden
bindkey '^F' _fzf_file_no_hidden

# Find In Files: interactive grep using ripgrep, fzf and bat preview
fif() {
  local target_dir="${1:-.}"
  local selection file line

  selection=$(rg --color=always --line-number --no-heading --smart-case "" "$target_dir" 2>/dev/null |
    fzf --ansi \
        --delimiter=':' \
        --preview='bat --color=always --style=numbers --highlight-line {2} {1}' \
        --preview-window='right:60%:+{2}-5' \
        --prompt='Search text > ')

  if [[ -n "$selection" ]]; then
    file=$(echo "$selection" | cut -d: -f1)
    line=$(echo "$selection" | cut -d: -f2)
    ${EDITOR:-nvim} "+$line" "$file"
  fi
}

# Ctrl+G: interactive ripgrep file content search
_fzf_grep() {
  local selection file line
  selection=$(rg --color=always --line-number --no-heading --smart-case "" . 2>/dev/null |
    fzf --ansi \
        --delimiter=':' \
        --preview='bat --color=always --style=numbers --highlight-line {2} {1}' \
        --preview-window='right:60%:+{2}-5' \
        --prompt='Grep > ')

  if [[ -n "$selection" ]]; then
    file=$(echo "$selection" | cut -d: -f1)
    line=$(echo "$selection" | cut -d: -f2)
    ${EDITOR:-nvim} "+$line" "$file"
  fi
  zle reset-prompt
}
zle -N _fzf_grep

