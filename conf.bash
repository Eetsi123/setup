GROUP="input kvm"

APT="task-english task-finnish firmware-linux sudo
     gcc python-is-python3 r-base
     meson cmake autoconf libtool pkg-config r-cran-haven r-cran-rcpp
     flatpak podman containers-storage pipx npm wine wine32

     htop iotop sysstat smartmontools nethogs powertop usbutils vainfo
     zram-tools rfkill pulsemixer adb cups
     fdisk gdisk gddrescue
     chrony wireguard sshfs

     bash-completion ripgrep tmux nnn catimg neovim git rsync
     apt-file debsums pwgen sox shellcheck
     telnet ssh aria2 nmap knot-dnsutils
     zip unrar libarchive-tools
     mediainfo exiftool exiftran tesseract-ocr-fin jq binwalk

     gnome-session gnome-tweaks xdg-desktop-portal-gnome
     chromium zathura mpv mangohud spotify-client
     libreoffice libreoffice-gnome onlyoffice-desktopeditors
     nsxiv darktable gimp inkscape
     alacritty code gparted easyeffects
     x11-apps x11-utils wev vulkan-tools

     chromium-l10n libreoffice-l10n-fi libreoffice-voikko"
APT_BACKPORTS="linux-image-amd64 linux-headers-amd64
               zfs-dkms cockpit cockpit-podman cockpit-machines
               golang"
APT_BLOCK="udisks2 avahi-daemon ifupdown
           nvidia-kernel-dkms"

SERVICE_RESTART="NetworkManager"

DEB="https://zoom.us/client/6.1.11.1545/zoom_amd64.deb
     http://code-industry.net/public/master-pdf-editor-4.3.89_qt5.amd64.deb
     https://github.com/notion-enhancer/notion-repackaged/releases/download/v2.0.18-1/notion-app_2.0.18-1_amd64.deb

     https://download1.rstudio.org/electron/jammy/amd64/rstudio-2024.04.2-764-amd64.deb
     https://github.com/webosbrew/dev-manager-desktop/releases/download/v1.13.3/web-os-dev-manager_1.13.3_amd64.deb
     https://github.com/fastfetch-cli/fastfetch/releases/download/2.23.0/fastfetch-linux-amd64.deb

     https://github.com/lutris/lutris/releases/download/v0.5.17/lutris_0.5.17_all.deb
     https://launcher.mojang.com/download/Minecraft.deb
     https://github.com/LizardByte/Sunshine/releases/download/v0.23.1/sunshine-debian-bookworm-amd64.deb

     https://github.com/winterheart/broadcom-bt-firmware/releases/download/v12.0.1.1105_p4/broadcom-bt-firmware-12.0.1.1105.deb"

FLATPAK="com.github.tchx84.Flatseal
         org.gnome.dspy

         net.ankiweb.Anki
         org.gnome.Loupe
         net.werwolv.ImHex
         io.github.nroduit.Weasis

         org.freedesktop.Platform.VulkanLayer.MangoHud/x86_64/23.08
         com.moonlight_stream.Moonlight
         info.cemu.Cemu
         org.ryujinx.Ryujinx
         net.pcsx2.PCSX2
         net.rpcs3.RPCS3"

CARGO="dufs
       tokei
       fclones

       cargo-outdated
       cargo-deps
       cargo-expand"

GO="github.com/go-acme/lego/v4/cmd/lego@v4.18.0"

PIPX="yt-dlp
      ocrmypdf
      whisper-ctranslate2

      plex-mpv-shim
      esptool"
PIPX_YT_DLP="secretstorage"
PIPX_WHISPER_CTRANSLATE2="nvidia-cudnn-cu12==8.9.7.29"

BIN="https://github.com/oven-sh/bun/releases/latest/download/bun-linux-x64.zip
     https://github.com/pgaskin/kepubify/releases/download/v4.0.4/kepubify-linux-64bit"

FONT="https://github.com/dmlls/whatsapp-emoji-linux/releases/download/2.24.8.85-1/WhatsAppEmoji.ttf"
GNOME_EXTENSION="lan-ip-address@mrhuber.com
                 tiling-assistant@leleat-on-github
                 bluetooth-quick-connect@bjarosze.gmail.com
                 batime@martin.zurowietz.de"
VSCODE_EXTENSION="vscodevim.vim
                  ms-python.debugpy
                  rust-lang.rust-analyzer
                  svelte.svelte-vscode"

if lscpu | grep -q GenuineIntel
then
    APT="$APT i7z"
    PIPX="$PIPX undervolt"
fi


if lsmod | grep -q i915
then
    APT="$APT intel-media-va-driver-non-free intel-gpu-tools"
fi

if lsmod | grep -qE "(nouveau|nvidia)"
then
    APT="$APT nvidia-container-toolkit nvtop"
fi

if lsusb | grep -q "NZXT Kraken"
then
    APT="$APT liquidctl"
fi
