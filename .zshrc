[ -e ~/.myzshrc ] && source ~/.myzshrc

export PS1="%n@%m [%~] %#> "
export RPS1="%t"

HISTFILE=~/.zshrc_history
SAVEHIST=512
HISTSIZE=512

setopt inc_append_history
setopt share_history

alias e="emacs"
alias q="emacs -q"

alias ss="du -a . | sort -n -r | head -n 10"

source ~/.mouse.zsh
# zle-toggle-mouse_	to enable mouse

autoload -U colors && colors

export EDITOR="emacs -q"
export VISUAL="emacs -q"

autoload -U compinit && compinit # enable completion
zmodload zsh/complist			# load compeltion list
zstyle ":completion:*" menu select # select menu completion

zstyle ':completion:*' list-colors '' # enable colors in completion

zstyle ":completion:*" group-name "" # group completion

zstyle ":completion:*:warnings" format "Nope !" # custom error

zstyle ":completion:::::" completer _complete _approximate # approx completion after regular one
# zstyle ":completion:*:approximate:*" max-errors 2		   # complete 2 errors max
zstyle ":completion:*:approximate:*" max-errors "reply=( $(( ($#PREFIX+$#SUFFIX)/3 )) numeric )" # allow one error each 3 characters

alias -s c=emacs				# alias {}.c=emacs{file}.c
alias -s h=emacs
alias -s cpp=emacs
alias -s hpp=emacs
alias -s py=emacs
alias -s el=emacs
alias -s emacs=emacs

alias l="ls -lFh"
alias la="ls -lAFh"
alias lt="ls -ltFh"
alias ll="ls -l"
alias grep="grep --color"

alias ressource="source ~/.zshrc"

setopt histignoredups			# ignore dups in history

bindkey -e 						# emacs style

autoload -z edit-command-line
zle -N edit-command-line

bindkey "^X^E" edit-command-line # edit line with $EDITOR
bindkey "^w" kill-region		 # emacs-like kill
bindkey -s "\el" "ls\n"			 # run ls
bindkey -s "^X^X" "emacs\n"		 # run emacs
bindkey -s "^X^M" "make\n"		 # make

if [[ "${terminfo[kcuu1]}" != "" ]]; then
	bindkey "${terminfo[kcuu1]}" up-line-or-search # smart search if line is not empty when keyup
fi

if [[ "${terminfo[kcud1]}" != "" ]]; then
	bindkey "${terminfo[kcud1]}" down-line-or-search # same for keydown
fi

