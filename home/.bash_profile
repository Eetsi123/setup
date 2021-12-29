source ~/.bashrc

for D in ~/.local/bin ~/.cargo/bin
do
    [[ $PATH =~ "$D:" ]] || PATH="$D:$PATH"
done
export PATH

export _JAVA_AWT_WM_NONREPARENTING=1
export _JAVA_OPTIONS="-Dawt.useSystemAAFontSettings=on -Dswing.aatext=true"
