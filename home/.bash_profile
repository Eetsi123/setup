export      EDITOR=nvim
export HISTCONTROL=ignorespace
export         PS1="\h \w $ "

export      XDG_RUNTIME_DIR=/tmp/$UID-runtime-dir
mkdir -p   $XDG_RUNTIME_DIR
chmod 0700 $XDG_RUNTIME_DIR

export S=eetu.duckdns.org

export GOPATH=~/.go

export MOZ_ENABLE_WAYLAND=1

export _JAVA_AWT_WM_NONREPARENTING=1
export _JAVA_OPTIONS="-Dawt.useSystemAAFontSettings=on -Dswing.aatext=true"

export ANDROID_SDK_ROOT=~/.android-sdk
export ANDROID_HOME=$ANDROID_SDK_ROOT  # deprecated

source ~/.bashrc

for D in ~/.local/bin ~/.cargo/bin
do
    [[ $PATH =~ "$D:" ]] || PATH="$D:$PATH"
done
export PATH
