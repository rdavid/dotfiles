# Setup fzf
# ---------
if [[ ! "$PATH" == */usr/local/opt/fzf/bin* ]]; then
  export PATH="${PATH:+${PATH}:}/usr/local/opt/fzf/bin"
fi

# Auto-completion
# ---------------
[[ $- == *i* ]] && source "$FZF_PATH/fzf/shell/completion.zsh" 2> /dev/null

# Key bindings
# ------------
source "$FZF_PATH/fzf/shell/key-bindings.zsh"
