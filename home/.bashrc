#### environment ####
source ~/.config/s

export s=${s:-undefined}
export HISTCONTROL=ignorespace
export EDITOR=nvim

for D in /usr/sbin ~/.local/bin ~/.cargo/bin ~/.go/bin ~/.bun/bin
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
alias y="yt-dlp --add-metadata --embed-subs --sub-lang=en,fi,fi-FI --retries=30 --retry-sleep=10"

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

fc() {
    OUTPUT="$1"
    shift

    ffmpeg -f concat -safe 0                 \
        -i <(printf "file $PWD/%s\n" "$@")   \
        -c copy -strict unofficial "$OUTPUT"
}
fl() {
    ffmpeg -loglevel error -stats -hwaccel cuda -hwaccel_output_format cuda -i "$1" -map 0 \
        -c:v h264_nvenc -vf scale_cuda=-1:1080 -cq 17 -preset p7                           \
        -c:a copy -c:s copy -strict unofficial "$2"
}
fs() {
    ffmpeg -loglevel error -stats -hwaccel cuda -hwaccel_output_format cuda -i "$1" -map 0 \
        -c:v hevc_nvenc -vf scale_cuda=-1:${3:-720} -cq ${4:-30} -preset p7                \
        -c:a libopus -b:a 96k -ac 2 -c:s copy -strict unofficial "$2"
}
ft() {
    local T C R
    readarray -t T < <(mediainfo --inform=file://<(echo -e "Video;V: %HDR_Format/String%\\\n\nAudio;A: %Format%\\\n") "$1")

    [[ "${T[@]}" =~ V:\ Dolby\ Vision     ]] && C=true R+=( video )
    [[ "${T[@]}" =~ A:\ (AAC|AC-3|E-AC-3) ]] || C=true R+=( audio )

    local IFS=+
    [[ -n $C ]] && echo "needs conversion: ${R[*]}"
}
ff() {
    local TRACKS TRACKS_A TRACKS_S TRACKS_P NAME EXT L T P AM AC SM SC PL PR
    NAME="${1##*/}" NAME="${NAME%.*}" MI="%StreamOrder%_%StreamKind%_%Format%_%Language/String2%_%Title%"

    readarray -t TRACKS < <(mediainfo \
        --inform=file://<(echo -e "Video;%StreamOrder%_Video_%HDR_Format%\\\n\nAudio;${MI}_%ServiceKind/String%\\\n\nText;${MI}_%Forced%\\\n") "$1" \
              | rg -vi "commentary|^$" | rg "_(Video|en|fi)_")

    readarray -t TRACKS_A < <(printf "%s\n" "${TRACKS[@]}" | rg "^[0-9]+_Audio_(AAC|AC-3|E-AC-3)")
    readarray -t TRACKS_S < <(printf "%s\n" "${TRACKS[@]}" | rg "^[0-9]+_Text")

    for L in $(rg -oP "_Text_[^_]*_\K[^_]+" <<< "${TRACKS_S[@]}" | sort | uniq)
    do
        for F in "forced|_Yes$" "sdh"
        do
            readarray -t T < <(printf "%s\n" "${TRACKS_S[@]}" | rg -vi "_${L}_.*($F)")
            rg -q "_${L}_" <<< "${T[@]}" && TRACKS_S=( "${T[@]}" )
        done
    done

    if rg -q "[0-9]_Video_Dolby Vision" <<< "${TRACKS[@]}"
    then
        readarray -t TRACKS_P < <(printf "%s\n" "${TRACKS_S[@]}" | rg     "_PGS_")
        readarray -t TRACKS_S < <(printf "%s\n" "${TRACKS_S[@]}" | rg -v  "_PGS_")
        readarray -t PL       < <(printf "%s\n" "${TRACKS_P[@]}" | rg -oP "_Text_[^_]*_\K[^_]+" | sort | uniq)
        T=()

        # NOTE: Pick the first PGS subtitle of each language.
        for L in "${PL[@]}"
        do
            T+=( "$(printf "%s\n" "${TRACKS_P[@]}" | rg -m1 "_${L}_")" )
        done
        TRACKS_P=( "${T[@]}" )

        for P in "${TRACKS_P[@]}"
        do
            mkdir -p /tmp/ff

            IFS=_ read P _ _ L _ <<< "$P"
            PR+=( -map 0:$P -c copy /tmp/ff/"$NAME.$L".sup )
        done

        SC=mov_text
        EXT=mp4
    else
        EXT=mkv
    fi

    if [[ -n $TRACKS_A ]]
    then
        AM=$(rg -oPr '-map 0:$0' "[0-9]+(?=_Audio)" <<< "${TRACKS_A}")
    else
        AM="-map 0:a:0 -metadata:s:a:0 title="
        AC="ac3 -b:a 320k -ac 2"
    fi

    SM=$(rg -oPr '-map 0:$0' "[0-9]+(?=_Text)" <<< "${TRACKS_S}")

    if [[ $2 = "d" ]]
    then
        printf "%s\n" EXT: $EXT "" TRACKS_A: "${TRACKS_A[@]}" "" \
                                   TRACKS_S: "${TRACKS_S[@]}" "" \
                                   TRACKS_P: "${TRACKS_P[@]}" "" \
                                   TRACKS:   "${TRACKS[@]}"
        return
    fi

    ffmpeg -loglevel error -stats -i "$1" \
        -map 0:v -c:v copy                \
        $AM      -c:a ${AC:-copy}         \
        $SM      -c:s ${SC:-copy}         \
        -strict unofficial "$NAME".$EXT "${PR[@]}"

    if [[ -n $PL ]]
    then
        for L in "${PL[@]}"
        do
            pgsrip /tmp/ff/"$NAME.$L".sup &
        done

        wait
        mv "${PL[@]/*//tmp/ff/$NAME.&.srt}" .
        rm -r /tmp/ff
    fi
}
n() {
    NNN_PLUG="p:-preview;n:-!nsxiv -apt . &*;m:-md5sum" \
        NNN_SSHFS="$HOME/.config/nnn/sshfs" nnn -ade "$@"
    if [[ -f   ~/.config/nnn/.lastd ]]
    then
        source ~/.config/nnn/.lastd
        rm     ~/.config/nnn/.lastd
    fi
}
m() {
    ip route show default | column -tH4,6,7,8

    echo
    local IFS=$'\n'
    select C in $(nmcli -t -f DEVICE,NAME connection show --active | rg -v "^lo:")
    do
        read -p "metric: " M
        sudo nmcli connection modify "${C#*:}" ipv4.route-metric "$M"
        sudo nmcli connection up     "${C#*:}"
        break
    done
}
w() {
    LD_LIBRARY_PATH=~/.local/pipx/venvs/whisper-ctranslate2/lib/python3.11/site-packages/nvidia/cudnn/lib \
        whisper-ctranslate2 --model=large-v2 --vad_filter=True --word_timestamps=True --print_colors=True \
                            --max_line_width=42 --max_line_count=2 "$@"

    local ARG
    for ARG in "$@"
    do
        [[ -f $ARG ]] && rm "${ARG%.*}".{vtt,tsv,json}
    done
}


#### completions ####
if ! source /usr/share/bash-completion/bash_completion 2>/dev/null
then
    echo "can't load completions"
    return 0
fi
complete -F _longopt l la
complete -r w

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
