# Modern CLI replacements

# Better ls
alias ls='eza --icons'

# Detailed listing
alias ll='eza -lhg --icons --git'

# Detailled listing including hidden files
alias la='eza -lahg --icons --git'

# Tree view
alias tree='eza --tree --icons'

# Cat to Bat
alias cat='bat'

# Use ls completion rules for eza (command options and arguments).
compdef eza=ls

# Core utilities

alias grep='rg --color=auto'
alias diff='diff --color=auto'
alias df='df -h'

# Navigation
# Use `-` as a shortcut to return to the previous directory visited (not the parent one)
alias -- -='cd -'

alias vim='nvim'
