### NOTE: base ###
FROM quay.io/fedora/fedora-silverblue:41
RUN rpm-ostree override remove gnome-software{,-rpm-ostree} firefox{,-langpacks} yelp
RUN rpm-ostree install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-41.noarch.rpm \
                       https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-41.noarch.rpm
WORKDIR /tmp


### NOTE: kernel ###
#FIXME: add "module_blacklist=nouveau preempt=full" to cmdline
RUN rpm -q --qf '%{version}-%{release}.%{arch}' kernel >/usr/kernel

RUN curl -sLO --output-dir /etc/yum.repos.d https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo && \
    rpm-ostree install kmod-nvidia && runuser -u akmods -- akmodsbuild -k $(cat /usr/kernel) /usr/src/akmods/nvidia-kmod.latest   && \
    rpm-ostree install kmod-nvidia-*.x86_64.rpm nvidia-container-toolkit nvtop                                                    && \
    rm                 kmod-nvidia-*.x86_64.rpm

ARG ZFS_VERSION=2.2.7
RUN curl -sL https://github.com/openzfs/zfs/releases/download/zfs-$ZFS_VERSION/zfs-$ZFS_VERSION.tar.gz | tar xz          && \
    rpm-ostree install   libtool ncompress {python3,systemd}-devel lib{aio,attr,blkid,curl,ffi,tirpc,uuid}-devel         && \
    cd zfs-$ZFS_VERSION                                                                                                  && \
    ./configure --with-linux=/usr/src/kernels/$(cat /usr/kernel) && make -j rpm-kmod rpm-utils                           && \
    rpm-ostree uninstall libtool ncompress {python3,systemd}-devel lib{aio,attr,blkid,curl,ffi,tirpc,uuid}-devel         && \
    rpm-ostree install {kmod-zfs-$(cat /usr/kernel),zfs,libzfs5,libzpool5,libnvpair3,libuutil3}-$ZFS_VERSION*.x86_64.rpm && \
    cd .. && rm -r zfs-$ZFS_VERSION

RUN curl -sL https://github.com/BoukeHaarsma23/zenergy/archive/master.tar.gz | tar xz && \
    cd zenergy-master                                     && \
    export KDIR=/usr/lib/modules/$(cat /usr/kernel)/build && \
    make -j && make modules_install && make clean         && \
    cd .. && rm -r zenergy-master

RUN depmod $(cat /usr/kernel)

RUN rpm-ostree install https://github.com/winterheart/broadcom-bt-firmware/releases/latest/download/broadcom-bt-firmware-12.0.1.1105.rpm


### NOTE: userland ###
RUN --mount=type=bind,src=patches/gnome-shell/2230-multiseat.patch,dst=ms \
    mkdir rpmbuild && cd rpmbuild                                      && \
    V=$(rpm -q --qf %{version} gnome-shell) R=$(rpm -q --qf %{release} gnome-shell) P=100.fc41            && \
    curl -sLO https://kojipkgs.fedoraproject.org/packages/gnome-shell/$V/$R/src/gnome-shell-$V-$R.src.rpm && \
    rpm -D "_topdir $PWD" -i gnome-shell-*.src.rpm && rpm -qa --qf "%{name}\n" >before   && \
    grep -oP "BuildRequires: +\K[^ ]+" SPECS/gnome-shell.spec | xargs rpm-ostree install && \
    sed -i "s/%autorelease/$P\nPatch: ms/" SPECS/gnome-shell.spec && cp ../ms SOURCES/   && \
    rpmbuild -D "_topdir $PWD" -bb SPECS/gnome-shell.spec                                && \
    rpm -qa --qf "%{name}\n" | grep -vFxf before | xargs rpm-ostree uninstall            && \
    rpm-ostree override replace RPMS/x86_64/gnome-shell-$V-$P.x86_64.rpm                 && \
    cd .. && rm -r rpmbuild

RUN rpm-ostree uninstall ffmpeg-free libav{codec,format,filter,device,util}-free libsw{scale,resample}-free libpostproc-free && \
    rpm-ostree install langpacks-fi cockpit cockpit-machines             \
                       htop iotop-c nethogs nmap smartmontools sg3_utils \
                       tmux nnn rclone neovim ripgrep fzf pwgen aria2    \
                       unrar p7zip-plugins bsdtar icoutils               \
                       ffmpeg mediainfo                                  \
                       cargo fontconfig-devel pipx python3-devel         \
                       msmtp golang-github-acme-lego                     \
                       mangohud vulkan-tools freerdp                  && \
    curl -sL https://github.com/Open-Wine-Components/umu-launcher/releases/latest/download/umu-launcher-rpm-41.zip | bsdtar x && \
    rpm-ostree install umu-launcher-*.noarch.rpm                                                                              && \
    rm                 umu-launcher-*.noarch.rpm

RUN CARGO_HOME=/tmp/cargo cargo install --no-track --root=/usr dufs tokei fclones binwalk && \
    rm -r /tmp/cargo

RUN export PIPX_GLOBAL_HOME=/usr/lib/pipx PIPX_GLOBAL_BIN_DIR=/usr/bin PIPX_MAN_DIR=/usr/share/man && \
    pipx install --global pulsemixer liquidctl yt-dlp ocrmypdf pgsrip                              && \
    pipx inject  --global yt-dlp secretstorage                                                     && \
    python -m venv /usr/lib/nvidia-ml-py && /usr/lib/nvidia-ml-py/bin/pip install nvidia-ml-py

RUN curl -sLOO -o date-menu-formatter@marcinjakubowski.github.com.github.zip -o lan-ip-address@mrhuber.com.github.zip                                 \
        https://github.com/Leleat/Tiling-Assistant/releases/latest/download/tiling-assistant@leleat-on-github.shell-extension.zip                     \
        https://github.com/stuarthayhurst/alphabetical-grid-extension/releases/latest/download/AlphabeticalAppGrid@stuarthayhurst.shell-extension.zip \
        https://github.com/marcinjakubowski/date-menu-formatter/archive/master.zip                                                                    \
        https://github.com/Josholith/gnome-extension-lan-ip-address/archive/master.zip                                                             && \
    cd /usr/share/gnome-shell/extensions                                                                                                           && \
    for F in /tmp/*.shell-extension.zip; do D=${F##*/} D=${D%.shell-extension.zip}; mkdir -p $D && bsdtar xf $F                      -C $D; done   && \
    for F in /tmp/*.github.zip;          do D=${F##*/} D=${D%.github.zip};          mkdir -p $D && bsdtar xf $F --strip-components=1 -C $D; done   && \
    rm /tmp/*.{shell-extension,github}.zip                                                                                                         && \
    glib-compile-schemas /usr/share/gnome-shell/extensions/AlphabeticalAppGrid@stuarthayhurst/schemas

RUN curl -sLO --output-dir /usr/share/fonts https://github.com/dmlls/whatsapp-emoji-linux/releases/latest/download/WhatsAppEmoji.ttf


### NOTE: configuration ###
COPY files/ /
RUN dconf update && echo "NoDisplay=true" | tee -a /usr/share/applications/{nvim,htop,nvtop,nvidia-settings}.desktop >/dev/null
