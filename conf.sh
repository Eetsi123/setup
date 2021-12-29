REPOS="void-repo-multilib void-repo-nonfree void-repo-multilib-nonfree"

PACKAGES="base-system grub-x86_64-efi seatd socklog-void bluez zramen

          curl git rsync
          neovim nnn ripgrep scc
          htop lm_sensors
          gcc pkg-config rustup rust-analyzer go pnpm shellcheck

          bash-completion xtools chrony python3-Twisted pngquant
          zip unzip lz4 zstd squashfs-tools
          fuse-sshfs jmtpfs
          nmap binwalk strace bind-utils libva-utils

          light iwd intel-video-accel igt-gpu-tools mesa-vulkan-intel mesa-vulkan-intel-32bit intel-undervolt
          nvidia nvidia-libs-32bit nvtop

          mesa-dri vulkan-loader Vulkan-Tools mesa-demos glxinfo
          pipewire libspa-bluetooth pulsemixer pulseaudio-utils
          xdg-utils terminus-font
          sway wev i3status j4-dmenu-desktop
          alacritty grimshot mpv zathura-pdf-mupdf scrcpy
          firefox torbrowser-launcher libreoffice gimp gparted ghidra
          steam libgcc-32bit libstdc++-32bit libdrm-32bit libglvnd-32bit mesa-dri-32bit

          youtube-dl instaloader spotify-tui
          pfetch pipes.c"

SRC="discord spotify"

CARGO="ncspot" PACKAGES="$PACKAGES dbus-devel libxcb-devel openssl-devel ncurses-devel"

FIREFOX="ublock-origin universal-bypass proxy-toggle
         cliget vimium-ff simple-translate single-file
         new-tab-override matte-black-red"


SERVICES="acpid socklog-unix nanoklogd seatd zramen dbus iwd bluetoothd intel-undervolt"
