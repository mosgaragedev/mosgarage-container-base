# ── Key bindings ──────────────────────────────────────────────────────────────
# Loaded from ~/.zshrc on top of the oh-my-zsh defaults.

# Ctrl+Left / Ctrl+Right — move by word in the current prompt line
bindkey '^[[1;5D' backward-word
bindkey '^[[1;5C' forward-word

# Home / End
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line

# Delete forward
bindkey '^[[3~' delete-char

# Ctrl+R keeps history searching, Ctrl+G aborts it
bindkey '^G' send-break

# Up/Down search history by prefix when text has already been typed
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search
