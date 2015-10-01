[ -e ~/.myzshrc ] && source ~/.myzshrc # load user file if any


# setup zsh #

TERM="xterm-256color" && [[ $(tput colors) == 256 ]] || echo "can't use xterm-256color :/" # check if xterm-256 color is available, or if we are in a retarded shell

# useful vars #

PERIOD=5			  # period used to hook periodic function (in sec)
PWD_FILE=~/.pwd					# last pwd sav file
CA_FILE=~/.ca					# cd aliases sav file
OS="$(uname)"					# get the os name
UPDATE_TERM_TITLE=""			# set to update the term title according to the path and the currently executed line
TO_PULL="~/zsh-config:~/emacs-config" # git repo paths to pull
SC=$(tput sc);
RC=$(tput rc);
YELLOWU_C=$(tput setaf 226; tput smul);
DEF_C=$(tput sgr0);

# PS1 FUNCTIONS #

function check_git_repo()		# check if pwd is a git repo
{
	git rev-parse > /dev/null 2>&1 && REPO=1 || REPO=0
}

function update_pwd_datas()		# update the numbers of files and dirs in .
{
	local v
	v=$(ls -pA1)
	NB_FILES=$(echo $v | grep -v /$ | wc -l | tr -d ' ')
	NB_DIRS=$(echo $v | grep /$ | wc -l | tr -d ' ')
}

function update_pwd_save()		# update the $PWD_FILE
{
	[[ $PWD != ~ ]] && echo $PWD > $PWD_FILE
}

function set_git_char()			# set the $GET_GIT_CHAR variable for the prompt
{
	if [ $REPO -eq 1 ];		# if in git repo, get git infos
	then
		local STATUS
		STATUS=$(git status 2> /dev/null)
		if [[ $STATUS =~ "Changes not staged" ]];
		then GET_GIT="%F{196}+"	# if git diff, wip
		else
			if [[ $STATUS =~ "Changes to be committed" ]];
			then GET_GIT="%F{214}+" # changes added
			else
				if [[ $STATUS =~ "is ahead" ]];
				then GET_GIT="%F{46}+" # changes commited
				else GET_GIT="%F{46}=" # changes pushed
				fi
			fi
		fi
	else
		GET_GIT="%F{240}o"		# not in git repo
	fi
}

function clock()
{
	echo -ne $SC
	tput cup 0 $(( $(tput cols) - 10));
	echo "$YELLOWU_C$(date +"%T")$DEF_C";
	echo -ne $RC
}

# CALLBACK FUNCTIONS #

function chpwd()				# chpwd hook
{
	check_git_repo
	update_pwd_datas
	update_pwd_save
}

function periodic()				# every $PERIOD secs - triggered by promt print
{	
	check_git_repo
	update_pwd_datas
	update_pwd_save
}

function preexec()				# pre execution hook
{
	[ -z $UPDATE_TERM_TITLE ] || print -Pn "\e]2;$PWD : $1\a" # set 'pwd + cmd' set term title
}

function precmd()				# pre promt hook
{
	clock
	[ -z $UPDATE_TERM_TITLE ] || print -Pn "\e]2;$PWD\a"		# set pwd as term title
	
	set_git_char
}


# USEFUL USER FUNCTIONS #

function ca()					# add cd alias (ca <alias_name> || ca <alias_name> <aliased path>)
{
	local a
	local p
	p=$(pwd)
	if [ "$#" -ne 1 ] && [ "$#" -ne 2 ]; then
		echo "Usage: ca alias (path)";
		return;
	fi;
	if [ "$#" -eq 2 ]; then
		[ ${2:0:1} = '/' ] && p="$2" || p+="/$2"
	fi;
	a=$1
	touch $CA_FILE;
	if [ "$(grep "^$a=" $CA_FILE)" != "" ]; then
		echo "replacing old '$a' alias"
		sed -i "s/^$a=.*$//g" $CA_FILE;
		sed -i "/^$/d" $CA_FILE;
	fi;
	echo "$a=$p" >> $CA_FILE;
}

function dca()					# delete cd alias (dca <alias 1> <alias 2> ... <alias n>)
{
	local a
	if [ -e $CA_FILE ] && [ "$#" -gt 0 ]; then
		for a in "$@"
		do
			sed -i "s/^$a=.*$//g" $CA_FILE;
		done
		sed -i "/^$/d" $CA_FILE;
	fi
}

function sca()					# show cd aliases
{
	[ -e $CA_FILE ] && cat $CA_FILE | egrep --color=auto "^[^=]+" || echo "No cd aliases yet";
}

function cd()					# cd wrap to use aliases - priority over real path instead of alias
{
	local a
	local p
	if [ -e $CA_FILE ] && [ "$#" -eq 1 ] && [ ! -d $1 ]; then
		a="$(grep -o "^$1=.*$" $CA_FILE)";
		if [ "$a" != "" ]; then
			p="$(echo $a | cut -d'=' -f2)"
			builtin cd $p 2> /dev/null && echo $p || echo "Invalid alias '$a'" 1>&2;
			return 0;
		fi;
	fi;
	builtin cd "$@" 2> /dev/null || echo "Nope" 1>&2;
}
export cd						# replace the old boring cd by my wrap

function showcolors()			# display the 256 colors by shades - useful to get pimpy colors
{
	for c in {0..15}; do tput setaf $c ; echo -ne " $c "; done
	echo
	for s in {16..51}; do
		for ((i = $s; i < 232; i+=36)); do
			tput setaf $i ; echo -ne " $i ";
		done;
		echo
	done
	for c in {232..255}; do tput setaf $c ; echo -ne " $c "; done
	echo
}

function error()				# give error nb to get error string
{
	python -c "import os; print os.strerror($?)";
}

function join_others_shells()	# ask for joining path specified in $PWD_FILE if not already in it
{
	if [[ -e $PWD_FILE ]] && [[ $(pwd) != $(cat $PWD_FILE) ]]; then
		read -q "?Go to $(tput setaf 3)$(cat $PWD_FILE)$(tput setaf 7) ? (Y/n):"  && cd "$(cat $PWD_FILE)"
	fi
}

function loop()					# loop parameter command every $LOOP_INT seconds (default 1)
{
	local d
	[ -z "$LOOP_INT" ] && LOOP_INT=1
	while true
	do
		clear
		d=$(date +%s)
		$@
		while [ "$(( $(date +%s) - d ))" -lt "$LOOP_INT" ]; do; sleep 0.1; done
	done
}

function extract				# extract muy types of archives
{
	if [ -z "$1" ]; then
		# display usage if no parameters given
		echo "Usage: extract <path/file_name>.<zip|rar|bz2|gz|tar|tbz2|tgz|Z|7z|xz|ex|tar.bz2|tar.gz|tar.xz>"
	else
		if [ -f $1 ] ; then
			# NAME=${1%.*}
			# mkdir $NAME && cd $NAME
			case $1 in
				*.tar.bz2)   tar xvjf ../$1    ;;
				*.tar.gz)    tar xvzf ../$1    ;;
				*.tar.xz)    tar xvJf ../$1    ;;
				*.lzma)      unlzma ../$1      ;;
				*.bz2)       bunzip2 ../$1     ;;
				*.rar)       unrar x -ad ../$1 ;;
				*.gz)        gunzip ../$1      ;;
				*.tar)       tar xvf ../$1     ;;
				*.tbz2)      tar xvjf ../$1    ;;
				*.tgz)       tar xvzf ../$1    ;;
				*.zip)       unzip ../$1       ;;
				*.Z)         uncompress ../$1  ;;
				*.7z)        7z x ../$1        ;;
				*.xz)        unxz ../$1        ;;
				*.exe)       cabextract ../$1  ;;
				*)           echo "extract: '$1' - unknown archive method" ;;
			esac
		else
			echo "$1 - file does not exist"
		fi
	fi
}

function pc()			  # percent of the home taken by this dir/file
{
	local subdir
	local dir

	if [ "$#" -eq 0 ]; then
		subdir=.
		dir=$HOME
	else if [ "$#" -eq 1 ]; then
			 subdir=$1
			 dir=$HOME
		 else if [ "$#" -eq 2 ]; then
				  subdir=$1
				  dir=$2
			  else
				  echo "Usage: pc <dir/file a>? <dir b>? to get the % of the usage of b by a"
				  return 1
			  fi
		 fi
	fi
	echo "$(($(du -sx $subdir | cut -f1) * 100 / $(du -sx $dir | cut -f1)))" "%"
}

function tmp()					# TODO: invoque new subshell in /tmp
{
	env STARTUP_CMD="cd /tmp" zsh;
}

function -()					# if 0 params, acts like 'cd -', else, act like the regular '-'
{
	[[ $# -eq 0 ]] && cd - || builtin - "$@"
}

function ff()					# faster find allowing parameters in disorder (ff [type|name|root]+)
{
	local p
	local name=""
	local type=""
	local root="."
	for p in "$@"; do
		if $(echo $p | grep -q "^[bcdflps]$"); # is it a type ?
		then
			type+=$([ -z $type ] && echo " -type $p" || echo " -or -type $p")
		else if [ -d $p ];		# is it a path ?
			 then
				 root=$p
			 else				# then its a name !
				 name+=$([ -z $name ] && echo " -name $p" || echo " -or -name $p");
			 fi
		fi
	done
	find $(echo $root $name $type | sed 's/ +/ /g') 2>/dev/null # re split all to spearate parameters
}

function +()					# send params to bc -l (-l to alloe floating point operations)
{
	echo "$@" | bc -l
}

function gitcheck()				# check all the git repos set in 
{
	SAVPWD=$(pwd)
	for repo in $(echo $TO_PULL | tr : \\n); do
		cd $repo
		git pull&
	done
	cd $SAVPWD
}

function colorcode()			# get the code to set the corresponding fg color
{
	for c in "$@"; do
		tput setaf $c;
		echo -e "\"$(tput setaf $c | cat -v)\""
	done
}

function colorize() # cmd | colorize <exp1> <color1> <exp2> <color2> ... to colorize expr with color
{					# maybe change the syntax to <regex>:fg:bg?:mod? ...
	local i
	local last
	local params
	local col
	i=0
	params=""
	col=""
	for c in "$@"; do
		case $c in
			"black") 	col=0;;
			"red") 		col=1;;
			"green") 	col=2;;
			"yellow") 	col=3;;
			"blue") 	col=4;;
			"purple") 	col=5;;
			"cyan") 	col=6;;
			"white") 	col=7;;
			*) 			col=$c;;
		esac
		if [ "$((i % 2))" = "1" ]; then
			params+=" -e s/($last)/$(tput setaf $col)\1$(tput sgr0)/g"
		else
			last=$c
		fi
		i=$(( i + 1))
	done
	if [ "$c" = "$last" ]; then
		echo "Usage: cmd | colorize <exp1> <color1> <exp2> <color2> ..."
		return
	fi
	sed -r $(echo $params) 2>/dev/null || echo "Usage: cmd | colorize <exp1> <color1> <exp2> <color2> ..."
}

# LESS USEFUL USER FUNCTIONS #

function race()					# race between logins given in parameters
{
    cat /dev/urandom | egrep --line-buffered -ao "$(echo $@ | sed "s/[^A-Za-z0-9]/\|/g")" | nl
}

function work()					# work simulation
{
	clear;
	cat /dev/zero | head -c $COLUMNS | tr '\0' '='
	text="$(cat $(find -type f -name "*.cpp" 2>/dev/null | head -n1) | sed ':a;$!N;$!ba;s/\/\*[^​*]*\*\([^/*​][^*]*\*\|\*\)*\///g')"
	arr=($(echo $text))
	i=0
	while true
	do
		read -qs;
		echo -n ${text[$i]};
		i=$(( i + 1 ))
	done
	echo
}

function hack()					# hollywood hacker cat
{
	cat $@ | pv -qL 25
}

function window()				# prints weather info
{
	curl -s "http://www.wunderground.com/q/zmw:00000.37.07156" | grep "og:title" | cut -d\" -f4 | sed 's/&deg;/ degrees/';
}


# PS1 VARIABLES #

SEP_C="%F{242}"					# separator color
ID_C="%F{33}"					# id color
PWD_C="%F{165}"					# pwd color
NBF_C="%F{46}"					# files number color
NBD_C="%F{26}"					# dir number color
TIM_C="%U%B%F{220}"				# time color

GET_SHLVL="$([[ $SHLVL -gt 9 ]] && echo "+" || echo $SHLVL)" # get the shell level (0-9 or + if > 9)

GET_SSH="$([[ $(echo $SSH_TTY$SSH_CLIENT$SSH_CONNECTION) != '' ]] && echo ssh$SEP_C:)" # 'ssh:' before username if logged in ssh

PS1=''							# simple quotes for post evaluation
PS1+='$ID_C$GET_SSH'			# 'ssh:' if in ssh
PS1+='$ID_C%n${SEP_C}@$ID_C%m'	# user@machine
PS1+='${SEP_C}[$PWD_C%~${SEP_C}|' # current short path
PS1+='$NBF_C$NB_FILES${SEP_C}/$NBD_C$NB_DIRS${SEP_C}]' # nb of files and dirs in .
PS1+=' %(0?.%F{82}o.%F{196}x)' # return status of last command (green O or red X)
PS1+='$GET_GIT'	# git status (red + -> dirty, orange + -> changes added, green + -> changes commited, green = -> changed pushed)
PS1+='%(1j.%(10j.%F{208}+.%F{226}%j).%F{210}%j)' # number of running/sleeping bg jobs
PS1+='%F{205}$GET_SHLVL'						 # static shlvl
PS1+='%(0!.%F{196}#.%F{26}\$)'					 # static user level
PS1+='${SEP_C}>%f%k '

# RPS1="$TIM_C%T%u%f%b"		# right part of the PS1



bindkey "$(echotc kl)" backward-char # dunno why but everybody is doing it
bindkey "$(echotc kr)" forward-char	 # looks like termcaps stuff
bindkey "$(echotc ku)" up-line-or-history # arrows keys compatibility on dumb terms maybe ?
bindkey "$(echotc kd)" down-line-or-history

# SETTING STUFF #

EDITOR="emacs"					# variables set for git editor and edit-command-line
VISUAL="emacs"

HISTFILE=~/.zshrc_history
SAVEHIST=4096
HISTSIZE=4096

CLICOLOR=1
case "$UNAME" in				# there is different LS_COLORS syntaxes according to OS :/
	*Darwin*)
		LS_COLORS='exfxcxdxbxexexabagacad'
		alias ls="ls -G";;
	*linux*|*cygwin*|*)
		LS_COLORS='fi=1;32:di=1;34:ln=35:so=32:pi=0;33:ex=32:bd=34;46:cd=34;43:su=0;41:sg=0;46:tw=1;34:ow=1;34:'
		alias ls="ls --color=auto";;
esac


# (UN)SETTING ZSH (COOL) OPTIONS #

setopt promptsubst				# compute PS1 at each prompt print
setopt inc_append_history
setopt share_history
setopt histignoredups			# ignore dups in history
setopt hist_expire_dups_first	# remove all dubs in history when full
setopt auto_remove_slash		# remove slash when pressing space in auto completion
setopt nullglob					# remove pointless globs
setopt auto_cd					# './dir' = 'cd dir'
setopt cbases					# c-like bases conversions
setopt emacs
setopt flow_control				# enable C-q and C-s to control the flooow
setopt rm_star_silent			# ask for confirmation if 'rm *'... why not ?
setopt completeinword			# complete from anywhere
# setopt print_exit_value			# print exit value if non 0

unsetopt beep					# no disturbing sounds


# ZSH FUNCTIONS LOAD #

autoload zed					# zsh editor

# autoload predict-on				# fish like suggestion (with bundled lags !)
# predict-on

autoload -z edit-command-line	# edit command line with $EDITOR
zle -N edit-command-line

autoload -U colors && colors	# cool colors

autoload -U compinit && compinit # enable completion
zmodload zsh/complist			 # load compeltion list


# SETTING UP ZSH COMPLETION STUFF #

zstyle ':completion:*:rm:*' ignore-line yes # remove suggestion if already in selection
zstyle ':completion:*:mv:*' ignore-line yes # same
zstyle ':completion:*:cp:*' ignore-line yes # same

zstyle ':completion::complete:*' use-cache on
zstyle ':completion::complete:*' cache-path .zcache

zstyle ":completion:*" menu select # select menu completion

zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}

zstyle ":completion:*" group-name "" # group completion

zstyle ":completion:*:warnings" format "Nope !" # custom error

zstyle ":completion:::::" completer _complete _approximate # approx completion after regular one
# zstyle ":completion:*:approximate:*" max-errors 2		   # complete 2 errors max
zstyle ":completion:*:approximate:*" max-errors "(( ($#PREFIX+$#SUFFIX)/3 ))" # allow one error each 3 characters

zle -C complete-file complete-word _generic
zstyle ':completion:complete-file::::' completer _files


# ZSH KEY BINDINGS #

bindkey -e 						# emacs style key binding

if (( ${+terminfo[smkx]} )) && (( ${+terminfo[rmkx]} )); then
	function zle-line-init() { echoti smkx }
	function zle-line-finish() { echoti rmkx }
	zle -N zle-line-init
	zle -N zle-line-finish
fi

# SHELL COMMANDS BINDS #
# 'cat -v' to get the keycode
bindkey -s "^[j" "^Ujoin_others_shells\n" # join_others_shells user function
bindkey -s "^[r" "^Uressource\n"		  # source ~/.zshrc
bindkey -s "^[e" "^Uerror\n"			  # run error user function
bindkey -s "^[s" "^Asudo ^E"	# insert sudo
bindkey -s "\el" "^Uls\n"		# run ls
bindkey -s "^X^X" "^Uemacs\n"	# run emacs
bindkey -s "^X^M" "^Umake\n"	# make


# ZSH FUNCTIONS BINDS #

bindkey "[/" complete-file		# complete files only
bindkey "^X^E" edit-command-line # edit line with $EDITOR
bindkey "^x^T" zle-toggle-mouse

bindkey "^[[1;3C" emacs-forward-word # alt + keys to navigate between words
bindkey "^[[1;3D" emacs-backward-word
bindkey "^[[1;5D" backward-word	# same with ctrl
bindkey "^[[1;5C" forward-word

bindkey "^[k" kill-word
bindkey "^w" kill-region		 # emacs-like kill

if [[ "${terminfo[kcbt]}" != "" ]]; then
	bindkey "${terminfo[kcbt]}" reverse-menu-complete # shift tab for backward completion
fi

if [[ "${terminfo[kcuu1]}" != "" ]]; then
	bindkey "${terminfo[kcuu1]}" up-line-or-search # smart search if line is not empty when keyup
fi

if [[ "${terminfo[kcud1]}" != "" ]]; then
	bindkey "${terminfo[kcud1]}" down-line-or-search # same for keydown
fi


# USEFUL ALIASES #

alias l="ls -lFh"				# list + classify + human readable
alias la="ls -lAFh"				# l with hidden files
alias lt="ls -ltFh"				# l with modification date sort
alias ll="ls -l"				# simple list
alias .="ls"

alias mkdir="mkdir -pv"			# create all the needed parent directories + inform user about creations

alias grep="grep --color"
alias egrep="egrep --color=auto"
alias tree="tree -C"

alias ressource="source ~/.zshrc"
alias res="source ~/.zshrc"

alias xemacs="emacs"
alias emax="emacs"
alias x="emacs"
alias emacs="emacs -nw"
alias e="emacs"
alias qmacs="emacs -q"
alias q="emacs -q"

alias ss="du -a . | sort -nr | head -n10" # get the 10 biggest files
alias df="df -Tha --total"		# disk usage infos
alias fps="ps | head -n1  && ps aux | grep -v grep | grep -i -e VSZ -e " # fps <processname> to get ps infos only for the matching processes

alias roadtrip='while true; do cd $(ls -pa1 | grep "/$" | grep -v "^\./$" | sort --random-sort | head -n1); echo -ne "\033[2K\r>$(pwd)"; done' # visit your computer

case "$UNAME" in
	*Darwin*)
		alias update="brew update && brew upgrade";;
	*linux*|*)
		alias update="sudo apt-get update && sudo apt-get upgrade";;
esac

check_git_repo
update_pwd_datas
update_pwd_save
set_git_char
rehash							# hash commands in path

# join_others_shells				# ask for joining others shells

[ "$STARTUP_CMD" != "" ] && eval $STARTUP_CMD && unset STARTUP_CMD

