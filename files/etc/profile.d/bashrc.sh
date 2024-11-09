[ -n $BASH_VERSION ] || exit

PROMPT_COMMAND+=('PS1u=$([[ $UID -eq 0 ]] && printf 31 || printf 32)')
PS1='\[\e[1;${PS1u}m\]\u@\h\[\e[0m\] \[\e[1;34m\]\w\[\e[0m\] $(printf "%.*s" $(($? * 100)) "\[\e[1;31m\]($?)\[\e[0m\] ")\$ '

export HISTCONTROL=ignorespace
export EDITOR=nvim

#### aliases ####
alias d="lsblk -do NAME,SIZE,TRAN,MODEL,SERIAL,WWN"
alias l="ls -lh --color=auto --hyperlink=auto"
alias r="rsync -havP --append --mkpath --timeout=30"
alias s="ssh $s"
alias t="s -N -D8080 -L8008:localhost:8008"
alias y="yt-dlp --add-metadata --embed-subs --sub-lang=en,fi,fi-FI --retries=30 --retry-sleep=10"

alias ga="git add"
alias gc="git commit"
alias gd="git diff"
alias gl="git log"
alias gr="git rebase"
alias gs="git status"
alias la="l -a"
alias pm="pulsemixer"


#### functions ####
b() { ("$@" &>/dev/null & disown) ;}
fs() {
    local F="$1" N="${1##*/}" VC=${2:-hevc} Q=${3:-30} S="${4/#[1-9]*/-vf scale_cuda=&:-1}" L=4

    [[ -z $S ]] && ((L--))
    shift $(( $# < $L ? $# : $L ))

    ffmpeg -loglevel error -stats -hwaccel cuda -hwaccel_output_format cuda -i "$F" -map 0 \
        -c:v ${VC}_nvenc -cq $Q -preset p7 $S                                              \
        -c:a libopus -b:a 96k -ac 2 -c:s copy -strict unofficial "$@" "${N%.*}-fs.mkv"
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

        SC="mov_text -tag:v hvc1"
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
        -strict unofficial "$NAME-ff.$EXT" "${PR[@]}"

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
    NNN_RCLONE="rclone mount --vfs-cache-mode=writes --vfs-cache-max-age=20m --vfs-cache-max-size=512M" \
        NNN_PLUG='m:-!|/usr/lib/nnn/plugins/md5sum "$nnn"' nnn -d "$@"

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


#### completions ####
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
cw  r rsync _rsync -onospace
cw  s ssh   _ssh

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
