# vim:foldmethod=marker
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.

if [[ -z $DISPLAY ]] && [[ $(tty) = /dev/tty1 ]]; then
	exec startx
fi
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
	source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export EDITOR="nvim"
export PYTHONSTARTUP="$HOME/Repositories/Daiyaan_Dotfiles/ipython.py"
export PATH=/home/daiyaan/.local/bin/:$PATH
export PATH=/home/daiyaan/.local/share/gem/ruby/3.0.0/bin:$PATH
LS_COLORS='rs=0:di=01;34:ln=01;36:mh=00:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:mi=00:su=37;41:sg=30;43:ca=30;41:tw=30;42:ow=34;42:st=37;44:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arc=01;31:*.arj=01;31:*.taz=01;31:*.lha=01;31:*.lz4=01;31:*.lzh=01;31:*.lzma=01;31:*.tlz=01;31:*.txz=01;31:*.tzo=01;31:*.t7z=01;31:*.zip=01;31:*.z=01;31:*.dz=01;31:*.gz=01;31:*.lrz=01;31:*.lz=01;31:*.lzo=01;31:*.xz=01;31:*.zst=01;31:*.tzst=01;31:*.bz2=01;31:*.bz=01;31:*.tbz=01;31:*.tbz2=01;31:*.tz=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.war=01;31:*.ear=01;31:*.sar=01;31:*.rar=01;31:*.alz=01;31:*.ace=01;31:*.zoo=01;31:*.cpio=01;31:*.7z=01;31:*.rz=01;31:*.cab=01;31:*.wim=01;31:*.swm=01;31:*.dwm=01;31:*.esd=01;31:*.jpg=01;35:*.jpeg=01;35:*.mjpg=01;35:*.mjpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.svg=01;35:*.svgz=01;35:*.mng=01;35:*.pcx=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.m2v=01;35:*.mkv=01;35:*.webm=01;35:*.webp=01;35:*.ogm=01;35:*.mp4=01;35:*.m4v=01;35:*.mp4v=01;35:*.vob=01;35:*.qt=01;35:*.nuv=01;35:*.wmv=01;35:*.asf=01;35:*.rm=01;35:*.rmvb=01;35:*.flc=01;35:*.avi=01;35:*.fli=01;35:*.flv=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.yuv=01;35:*.cgm=01;35:*.emf=01;35:*.ogv=01;35:*.ogx=01;35:*.aac=00;36:*.au=00;36:*.flac=00;36:*.m4a=00;36:*.mid=00;36:*.midi=00;36:*.mka=00;36:*.mp3=00;36:*.mpc=00;36:*.ogg=00;36:*.ra=00;36:*.wav=00;36:*.oga=00;36:*.opus=00;36:*.spx=00;36:*.xspf=00;36:';
export LS_COLORS
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
export CLICOLOR=1
export QT_QPA_PLATFORMTHEME=qt5ct
export PATH=jdk/bin:$PATH

# ░█▀█░█▀▀░█░█░░░█░█░█▀▀░█▀▀░█▀▄
# ░█░█░█▀▀░█▄█░░░█░█░▀▀█░█▀▀░█▀▄
# ░▀░▀░▀▀▀░▀░▀░░░▀▀▀░▀▀▀░▀▀▀░▀░▀

# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=5120
SAVEHIST=5120
setopt autocd beep extendedglob nomatch notify
#setopt auto_pushd
# vim mode config
# ---------------

	# Activate vim mode.
	bindkey -v

	# Remove mode switching delay.
	KEYTIMEOUT=5

	# Change cursor shape for different vi modes.
	function zle-keymap-select {
	if [[ ${KEYMAP} == vicmd ]] ||
		[[ $1 = 'block' ]]; then
			echo -ne '\e[1 q'

		elif [[ ${KEYMAP} == main ]] ||
			[[ ${KEYMAP} == viins ]] ||
			[[ ${KEYMAP} = '' ]] ||
			[[ $1 = 'beam' ]]; then
					echo -ne '\e[5 q'
	fi
}
zle -N zle-keymap-select

	# Use beam shape cursor on startup.
	echo -ne '\e[5 q'

	# Use beam shape cursor for each new prompt.
	preexec() {
		echo -ne '\e[5 q'
	}

# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
zstyle :compinstall filename '/home/daiyaan/.zshrc'

autoload -Uz compinit promptinit
compinit

# case insensitive path-completion 
zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]} l:|=* r:|=*' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]} l:|=* r:|=*' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]} l:|=* r:|=*' 
promptinit

# End of lines added by compinstall

# ░█▀█░█▀▄░█▀▀░█░█░░░█░█░▀█▀░█░█░▀█▀
# ░█▀█░█▀▄░█░░░█▀█░░░█▄█░░█░░█▀▄░░█░
# ░▀░▀░▀░▀░▀▀▀░▀░▀░░░▀░▀░▀▀▀░▀░▀░▀▀▀

zstyle ':completion:*' menu select
zstyle ':completion:*' rehash true
zstyle ':completion::complete:*' gain-privileges 1
setopt COMPLETE_ALIASES
# create a zkbd compatible hash;
# to add other keys to this hash, see: man 5 terminfo
typeset -g -A key

key[Home]="${terminfo[khome]}"
key[End]="${terminfo[kend]}"
key[Insert]="${terminfo[kich1]}"
key[Backspace]="${terminfo[kbs]}"
key[Delete]="${terminfo[kdch1]}"
key[Up]="${terminfo[kcuu1]}"
key[Down]="${terminfo[kcud1]}"
key[Left]="${terminfo[kcub1]}"
key[Right]="${terminfo[kcuf1]}"
key[PageUp]="${terminfo[kpp]}"
key[PageDown]="${terminfo[knp]}"
key[Shift-Tab]="${terminfo[kcbt]}"

# setup key accordingly
[[ -n "${key[Home]}"      ]] && bindkey -- "${key[Home]}"       beginning-of-line
[[ -n "${key[End]}"       ]] && bindkey -- "${key[End]}"        end-of-line
[[ -n "${key[Insert]}"    ]] && bindkey -- "${key[Insert]}"     overwrite-mode
[[ -n "${key[Backspace]}" ]] && bindkey -- "${key[Backspace]}"  backward-delete-char
[[ -n "${key[Delete]}"    ]] && bindkey -- "${key[Delete]}"     delete-char
[[ -n "${key[Up]}"        ]] && bindkey -- "${key[Up]}"         up-line-or-history
[[ -n "${key[Down]}"      ]] && bindkey -- "${key[Down]}"       down-line-or-history
[[ -n "${key[Left]}"      ]] && bindkey -- "${key[Left]}"       backward-char
[[ -n "${key[Right]}"     ]] && bindkey -- "${key[Right]}"      forward-char
[[ -n "${key[PageUp]}"    ]] && bindkey -- "${key[PageUp]}"     beginning-of-buffer-or-history
[[ -n "${key[PageDown]}"  ]] && bindkey -- "${key[PageDown]}"   end-of-buffer-or-history
[[ -n "${key[Shift-Tab]}" ]] && bindkey -- "${key[Shift-Tab]}"  reverse-menu-complete

# Finally, make sure the terminal is in application mode, when zle is
# active. Only then are the values from $terminfo valid.
if (( ${+terminfo[smkx]} && ${+terminfo[rmkx]} )); then
	autoload -Uz add-zle-hook-widget
	function zle_application_mode_start { echoti smkx }
	function zle_application_mode_stop { echoti rmkx }
	add-zle-hook-widget -Uz zle-line-init zle_application_mode_start
	add-zle-hook-widget -Uz zle-line-finish zle_application_mode_stop
fi
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

[[ -n "${key[Up]}"   ]] && bindkey -- "${key[Up]}"   up-line-or-beginning-search
[[ -n "${key[Down]}" ]] && bindkey -- "${key[Down]}" down-line-or-beginning-search

key[Control-Left]="${terminfo[kLFT5]}"
key[Control-Right]="${terminfo[kRIT5]}"

[[ -n "${key[Control-Left]}"  ]] && bindkey -- "${key[Control-Left]}"  backward-word
[[ -n "${key[Control-Right]}" ]] && bindkey -- "${key[Control-Right]}" forward-word

autoload -Uz add-zsh-hook

DIRSTACKFILE="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/dirs"
if [[ -f "$DIRSTACKFILE" ]] && (( ${#dirstack} == 0 )); then
	dirstack=("${(@f)"$(< "$DIRSTACKFILE")"}")
	[[ -d "${dirstack[1]}" ]] && cd -- "${dirstack[1]}"
fi
chpwd_dirstack() {
	print -l -- "$PWD" "${(u)dirstack[@]}" > "$DIRSTACKFILE"
}
add-zsh-hook -Uz chpwd chpwd_dirstack

DIRSTACKSIZE='20'

setopt AUTO_PUSHD PUSHD_SILENT PUSHD_TO_HOME

## Remove duplicate entries
setopt PUSHD_IGNORE_DUPS

## This reverts the +/- operators.
setopt PUSHD_MINUS

ncmpcppShow() {
	BUFFER="ncmpcpp"
	zle accept-line
}
zle -N ncmpcppShow
bindkey '^[\' ncmpcppShow

cdUndoKey() {
	popd
	zle       reset-prompt
	print
	ls
	zle       reset-prompt
}

cdParentKey() {
	pushd ..
	zle      reset-prompt
	print
	ls
	zle       reset-prompt
}

zle -N                 cdParentKey
zle -N                 cdUndoKey
bindkey '^[[1;3A'      cdParentKey
bindkey '^[[1;3D'      cdUndoKey

# <END> Random stuff I took from the ArchWiki

# Plugins {{{
# Antigen Installation ---> curl -L git.io/antigen > antigen.zsh
# Antigen Plugins
source ~/antigen.zsh
antigen bundle "MichaelAquilina/zsh-auto-notify"
antigen bundle hlissner/zsh-autopair
antigen bundle zsh-users/zsh-autosuggestions
antigen bundle zsh-users/zsh-completions
# antigen bundle unixorn/autoupdate-antigen.zshplugin
antigen bundle ael-code/zsh-colored-man-pages
antigen bundle joel-porquet/zsh-dircolors-solarized.git
antigen bundle "MichaelAquilina/zsh-you-should-use"
antigen theme romkatv/powerlevel10k
antigen bundle qoomon/zsh-lazyload
antigen bundle Aloxaf/fzf-tab
#antigen bundle denysdovhan/spaceship-prompt
antigen apply
# Antigen end

# Git                       ------> git clone https://github.com/davidde/git.git
source ~/Repositories/Zsh-plugins/git/git.plugin.zsh
# Bash completion fallback  ------> git clone https://github.com/3v1n0/zsh-bash-completions-fallback.git
source ~/Repositories/Zsh-plugins/zsh-bash-completions-fallback/zsh-bash-completions-fallback.plugin.zsh
# History Substring search  ------> git clone https://github.com/zsh-users/zsh-history-substring-search.git
source ~/Repositories/Zsh-plugins/zsh-history-substring-search/zsh-history-substring-search.zsh
# Fast Syntax Highlighting  ------> git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git
source ~/Repositories/Zsh-plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
# Startup timer             ------> git clone
# source ~/Repositories/Zsh-plugins/zsh-startup-timer/startup-timer.plugin.zsh
#}}}


# Aliases {{{
#alias ls='colorls -goAl --gs --sd '
alias ls='lsd -FAlX1 --group-dirs first --date relative --blocks permission --blocks size --blocks date --blocks name'
alias ll='lsd -FAl --total-size --group-dirs first --sort extension'
alias tree='lsd --tree'
alias c="clear"
alias v="~/Repositories/Daiyaan_Dotfiles/OpenWithMetadata.sh"
alias freespace='df --sync -h /'
alias n="neofetch --source ~/.config/neofetch/ascii.txt"
alias ip='ip -c'
alias f='fzf'
alias polybar='bash ~/.config/polybar/launch.sh'
alias grep='grep --line-number -i --color=always'
alias p='~/.config/i3/screenshot.sh'
alias u='unipicker --copy'
alias d='dirs -v'
alias rm='rm -rfv'
alias make='make -s'
alias python='python -q'
alias bat='bat --theme=TwoDark'
alias dmenu_run="dmenu_run -fn JetBrainsMono:style=bold:size=12 -nb '#000000' -nf '#fffefe' -sb '#0a7aca' -sf '#fffefe'"
#}}}

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
autoload edit-command-line; zle -N edit-command-line
bindkey -M vicmd v edit-command-line
setopt EXTENDED_GLOB

# cd ~/Projects
setxkbmap -option caps:escape
source /usr/share/nvm/init-nvm.sh
