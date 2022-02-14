REPOS="void-repo-multilib void-repo-nonfree void-repo-multilib-nonfree"

PACKAGES="base-system grub-x86_64-efi seatd socklog-void

          curl git rsync miniupnpc monero
          neovim nnn ripgrep scc
          htop iotop nethogs lm_sensors dmidecode
          gcc pkg-config rustup rust-analyzer go pnpm python3-pip shellcheck

          bash-completion xtools chrony python3-Twisted pwgen pngquant
          zip unzip lz4 zstd p7zip squashfs-tools
          ntfs-3g fuse-sshfs jmtpfs parted smartmontools compsize
          nmap binwalk python3-matplotlib strace bind-utils libva-utils

          mesa-dri vulkan-loader Vulkan-Tools mesa-demos glxinfo
          pipewire pulsemixer pulseaudio-utils
          xdg-utils terminus-font
          sway wev i3status j4-dmenu-desktop
          alacritty grimshot mpv zathura-pdf-mupdf scrcpy
          firefox torbrowser-launcher libreoffice gimp gparted ghidra
          steam libgcc-32bit libstdc++-32bit libdrm-32bit libglvnd-32bit mesa-dri-32bit

          youtube-dl instaloader spotify-tui
          pfetch pipes.c"

SRC="discord spotify android-studio"

CARGO="ncspot" PACKAGES="$PACKAGES dbus-devel libxcb-devel openssl-devel ncurses-devel"
PIP=

FIREFOX="ublock-origin i-dont-care-about-cookies clear-site-cookies
         new-tab-override vimium-ff matte-black-red
         cliget simple-translate fastforwardteam netflix-1080p-firefox proxy-toggle single-file"


SERVICES="acpid socklog-unix nanoklogd seatd dbus"

shopt -s expand_aliases
alias M="lsmod | grep -q"
alias U="lsusb | grep -q"

A() { V=$1; shift; eval "$V=\"${!V} $*\"" ;}
alias AP="A PACKAGES"
alias AS="A SERVICES"

M     iwlwifi                         && { AP iwd;                                                                              AS iwd             ;}
M     btusb                           && { AP bluez libspa-bluetooth;                                                           AS bluetoothd      ;}
M     i915                            && { AP light intel-video-accel igt-gpu-tools mesa-vulkan-intel{,-32bit} intel-undervolt; AS intel-undervolt ;}
[[ -d /sys/class/power_supply/BAT0 ]] &&   AP upower
M -E '(nouveau|nvidia)'               &&   AP nvidia nvidia-libs-32bit nvtop
U     NZXT                            && { AP python3-{devel,setuptools,docopt,usb} libusb;                                     A PIP liquidctl    ;}
