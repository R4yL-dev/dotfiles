### .zshrc
# created by : R4yL
# version : 1.0
# date : 16/06/24

# Run TMUX
if [ -z "$TMUX" ] && [ -n "$PS1" ]; then
	tmux
fi

# Run zinit
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [ ! -d "$ZINIT_HOME" ]; then
	mkdir -p "$(dirname $ZINIT_HOME)"
	git clone https://github.com/zdharma-continuum/zinit "$ZINIT_HOME"
fi
source "${ZINIT_HOME}/zinit.zsh"

# Setup ice
zinit ice as"command" from"gh-r" \
          atclone"./starship init zsh > init.zsh; ./starship completions zsh > _starship" \
          atpull"%atclone" src"init.zsh"

# Load plugins
zinit light starship/starship
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions

# Load snippets
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::command-not-found

# Setup auto completion
autoload -U compinit && compinit

# Recommended by documentation
zinit cdreplay -q

# Keybinding
bindkey '^f' autosuggest-accept
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward

# History
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_find_no_dups

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Export
export WINE="/usr/bin/wine"
export WINETRICKS="/usr/bin/winetricks"
export PATH=$PATH:/usr/local/go/bin
export PATH=$PATH:/home/luca/go/bin

# Alias
alias ls='ls --color'
alias la='ls -a'
alias lla='ls -la'
alias c='clear'
### End of Zinit's installer chunk
export PATH=~/.npm-global/bin:$PATH
export PATH="$HOME/.local/bin:$PATH"
