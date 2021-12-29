export             EDITOR=nvim
export MOZ_ENABLE_WAYLAND=1
export                PS1="\w $ "
export                  S=eetsi123.duckdns.org

alias  d="diff -u --color"
alias  l="ls -lh --color=auto"
alias la="l -a"

alias ad="adb devices"
alias am="adb shell svc usb setFunctions mtp"
alias ap="adb tcpip 5555"
alias ar="adb shell 'svc wifi disable && svc usb setFunctions rndis'"
alias bb="bp; bluetoothctl connect 60:3A:AF:56:51:B5"
alias bo="bluetoothctl power off"
alias bp="bluetoothctl power on"
alias  m="mpv --hwdec=auto-safe"
alias ma="jmtpfs -o allow_root      /mnt/removable/"
alias ms="sshfs  -o allow_root $S:/ /mnt/sshfs"
alias  p="cpipes -p40 -r0.6 -m300"
alias pm="pulsemixer"
alias  r="rsync -haviP --append --timeout=30"
alias rf="rg --files | rg"
alias  s="ssh $S"
alias  S="~/src/setup/setup"
alias st="s -N -D8080 -L8008:localhost:8008"
alias ur="umount /mnt/removable 2>/dev/null || sudo umount /mnt/removable"
alias us="umount /mnt/sshfs"
alias  z="zathura --fork"

b()  { ("$@" &>/dev/null & disown)  ;}
h()  { twistd -n web --path ${1:-.} ;}
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
    S=NB1GAD4782102091
    A=$(ip r s default | cut -d' ' -f3)
    [[ $A = 192.168.66.1 ]] && A=192.168.66.8
    adb connect $A:5555     && S=$A
    scrcpy -s $S -b4M -m1920 -Sw "$@"
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
