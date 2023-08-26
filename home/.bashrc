#### environment ####
source ~/.config/s

export s=${s:-undefined}
export HISTCONTROL=ignorespace
export EDITOR=nvim

for D in /usr/sbin ~/.local/bin ~/.cargo/bin ~/.go/bin
do
    [[ $PATH =~ "$D:" ]] || PATH="$D:$PATH"
done
export PATH

export GOPATH=~/.go
export ANDROID_HOME=~/.android-sdk

PS1='\[\e]2;$PWD\a\]\[\033[01;32m\]\u@\h\[\033[00m\] \[\033[01;34m\]\w\[\033[00m\] \$ '


#### aliases ####
alias d="lsblk -do NAME,SIZE,TRAN,MODEL,SERIAL,WWN"
alias S="~/src/setup/setup"
alias l="ls -lh --color=auto"
alias r="rsync -havP --append --mkpath --timeout=30"
alias s="ssh $s"
alias t="s -N -D8080 -L8008:localhost:8008"
alias z="zathura --fork"
alias y="yt-dlp --add-metadata --embed-subs --write-auto-subs --sub-lang=en,fi --retries=30 --retry-sleep=10"

alias bw="sudo efibootmgr -qn \$(efibootmgr | rg -oP '^Boot0*\K[0-9A-F]+(?=\*? Windows)') && sudo reboot"
alias ga="git add"
alias gc="git commit"
alias gd="git diff"
alias gl="git log"
alias gr="git rebase"
alias gs="git status"
alias la="l -a"
alias pm="pulsemixer"
alias wn="play -n synth brownnoise synth pinknoise mix synth sine amod 0.05 70"


#### functions ####
b() { ("$@" &>/dev/null & disown)  ;}

n() {
    NNN_PLUG="p:-preview;n:-!nsxiv -apt . &*;m:-md5sum" \
        NNN_SSHFS="$HOME/.config/nnn/sshfs" nnn -ade "$@"
    if [[ -f   ~/.config/nnn/.lastd ]]
    then
        source ~/.config/nnn/.lastd
        rm     ~/.config/nnn/.lastd
    fi
}


#### completions ####
if ! source /usr/share/bash-completion/bash_completion 2>/dev/null
then
    echo "can't load completions"
    return 0
fi
complete -F _longopt l la

# lazy loading completion wrapper
# $1 -> command
# $2 -> original command
# $3 -> completion
# $4 -> additional complete options
cw() {
    eval "_$1() {
        unset -f _$1
        [[ \$(type -t $3) = function ]] || source /usr/share/bash-completion/completions/$2
        complete $4 -F $3 $1
        $3 \"\$@\"
    }"
    complete $4 -F _$1 $1
}
cw  r rsync   _rsync   -onospace
cw  s ssh     _ssh
cw  z zathura _zathura

# lazy loading completion wrapper variant for git aliases
# $1 -> alias
# $2 -> subcommand
cwg() {
    eval "_$1() {
        unset -f _$1
        [[ \$(type -t __git_complete) = function ]] || source /usr/share/bash-completion/completions/git
        __git_complete $1 _git_$2
        __git_wrap_git_$2 \"\$@\"
    }"
    complete -F _$1 $1
}
cwg ga add
cwg gc commit
cwg gd diff
cwg gl log
cwg gr rebase
cwg gs status
