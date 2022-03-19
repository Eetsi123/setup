alias  d="diff -u --color"
alias  l="ls -lh --color=auto"
alias la="l -a"

alias ad="adb devices"
alias ae="$ANDROID_SDK_ROOT/emulator/emulator -gpu host"
alias am="adb shell svc usb setFunctions mtp"
alias ap="adb tcpip 5555"
alias ar="adb shell 'svc wifi disable && svc usb setFunctions rndis'"
alias bb="bp; bluetoothctl connect 60:3A:AF:56:51:B5"
alias bo="bluetoothctl power off"
alias bp="bluetoothctl power on"
alias  h="miniserve -p 8888"
alias  m="mpv --hwdec=auto-safe --demuxer-max-bytes=8GiB"
alias ma="jmtpfs -o allow_root      /mnt/removable/"
alias ms="sshfs  -o allow_root $S:/ /mnt/sshfs"
alias  p="cpipes -p40 -r0.6 -m300"
alias pm="pulsemixer"
alias  r="rsync -havP --append --timeout=30 --compress-choice=zstd --compress-level=15"
alias rf="rg --files | rg"
alias rp="pkill -x 'pipewire(-pulse)?' && b pipewire && sleep 0.1 && b pipewire-pulse"
alias  s="ssh $S"
alias  S="~/src/setup/setup"
alias st="s -N -D8080 -L8008:localhost:8008 -L8009:localhost:8009"
alias ur="umount /mnt/removable 2>/dev/null || sudo umount /mnt/removable"
alias us="umount /mnt/sshfs"
alias  z="zathura --fork"

b()  { ("$@" &>/dev/null & disown)  ;}
il() { instaloader -sGCl $1 --highlights --tagged --igtv $2 ;}
mr() { sudo mount /dev/${1:-sdb1} /mnt/removable ;}

n() {
    NNN_PLUG='x:tx;s:!sudoedit $nnn' nnn -due "$@"
    if [[ -f   ~/.config/nnn/.lastd ]]
    then
        source ~/.config/nnn/.lastd
        rm     ~/.config/nnn/.lastd
    fi
}
sc() {
    adb disconnect
    local S=NB1GAD4782102091 A=$(ip r s default | cut -d' ' -f3)
    [[ $A = 192.168.100.1 ]] && ping -c1 -W0.6 192.168.100.12 >/dev/null && A=192.168.100.12
    adb connect $A            | rg   -Fq 'connected to'                  && S=$A
    scrcpy -s $S -b4M -m1920 -Sw "$@"
}
sm() {
    if [[ $# -eq 0 ]]
    then
        swaymsg -pt get_outputs | rg --color=never '(O|C|P|Av|    |^$)'
        return
    fi

    local J=$(swaymsg -t get_outputs) O X=0
    for O in $(jq -r .[].name <<< "$J")
    do
        if printf '%s\n' "$@" | rg -Fxq "$O"
        then
            swaymsg output "$O" enable
        else
            swaymsg output "$O" disable
        fi
    done
    J=$(swaymsg -t get_outputs)
    for O in "$@"
    do
        swaymsg output "$O" pos $X 0
        (( X += $(jq ".[] | select(.name == \"$O\").rect.width" <<< "$J") ))
    done
}
sw() {
    [[ -z $XDG_RUNTIME_DIR ]] && export XDG_RUNTIME_DIR=/tmp/$UID-runtime-dir

    mkdir -p   $XDG_RUNTIME_DIR
    chmod 0700 $XDG_RUNTIME_DIR
    sway --unsupported-gpu "$@"
    rm -rf /tmp/$UID-runtime-dir
}
tl() {
    if sed '2q;d' /etc/acpi/handler.sh | rg -q lid-disabled
    then
        sudo sed -i 2d /etc/acpi/handler.sh
        echo "lid enabled"
    else
        sudo sed -i '2s/^/[ "$1" = button\/lid ] \&\& exit # lid-disabled\n/' /etc/acpi/handler.sh
        echo "lid disabled"
    fi
}

complete  -F _longopt diff l la
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
cw  m mpv     _mpv
cw  n nnn     _nnn     -ofilenames
cw  r rsync   _rsync   -onospace
cw rf rg      _rg
cw  s ssh     _ssh
cw sw sway    _sway
cw  z zathura _zathura
