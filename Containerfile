### NOTE: common ###
FROM quay.io/fedora/fedora-silverblue:41 AS common
RUN dnf remove -y gnome-software{,-rpm-ostree} firefox{,-langpacks} yelp
WORKDIR /tmp

COPY patches/uname .
ENV PATH=/tmp:$PATH

ARG PIPX_GLOBAL_HOME=/usr/lib/pipx
ARG PIPX_GLOBAL_BIN_DIR=/usr/bin
ARG PIPX_MAN_DIR=/usr/share/man


### NOTE: kernel ###
#FIXME: add "module_blacklist=nouveau preempt=full" to cmdline
RUN rpm-ostree uninstall -y kernel{,-core} kernel-modules{,-core,-extra} virtualbox-guest-additions && \
    rpm-ostree   install -y kernel{,-modules-extra}-6.12.*                                          && \
    dnf versionlock add kernel-core

RUN dnf install -y kernel-devel-matched "kernel-headers <= $(rpm -q --qf %{version} kernel)" rpm-build

RUN dnf install -y https://zfsonlinux.org/fedora/zfs-release-2-6$(rpm -E %dist).noarch.rpm && \
    dnf install -y zfs                                                                     && \
    dkms autoinstall

RUN curl -sL https://github.com/BoukeHaarsma23/zenergy/archive/master.tar.gz | tar xz && \
    make -C zenergy-master -j modules{,_install} clean                                && \
    rm   -r zenergy-master

RUN dnf install -y https://github.com/winterheart/broadcom-bt-firmware/releases/latest/download/broadcom-bt-firmware-12.0.1.1105.rpm

RUN depmod $(rpm -q --qf %{version}-%{release}.%{arch} kernel)


### NOTE: userland ###
RUN dnf remove  -y ffmpeg-free libav{codec,format,filter,device,util}-free libsw{scale,resample}-free libpostproc-free && \
    dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-41.noarch.rpm                         \
                   https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-41.noarch.rpm                && \
    dnf install -y langpacks-fi gnome-tweaks cockpit{,-machines} libvirt-daemon  \
                   {h,b}top iotop-c nethogs nmap smartmontools sg3_utils         \
                   tmux nnn rclone neovim ripgrep fzf pwgen aria2                \
                   unrar p7zip-plugins bsdtar icoutils                           \
                   ffmpeg mediainfo                                              \
                   cargo fontconfig-devel pipx uv python3-devel cmake meson perf \
                   wireguard-tools msmtp golang-github-acme-lego                 \
                   gamescope mangohud vulkan-tools igt-gpu-tools freerdp      && \
    setcap CAP_PERFMON=ep /usr/bin/intel_gpu_top                              && \
    echo NoDisplay=true | tee -a /usr/share/applications/{nvim,htop}.desktop >/dev/null
RUN fix() { cat /etc/$1 >>/usr/lib/$1; cp /dev/null /etc/$1; } && \
    fix passwd                                                 && \
    fix group
RUN dnf install -y https://github.com/Open-Wine-Components/umu-launcher/releases/latest/download/umu-launcher-1.2.5.fc41.rpm

RUN --mount=type=bind,src=patches,dst=patches,relabel=shared \
    ./patches/patch-n-build                               && \
    dnf install -y *.rpm                                  && \
    rm             *.rpm

RUN curl -sL https://github.com/oven-sh/bun/releases/latest/download/bun-linux-x64.zip | bsdtar xC /usr/bin --strip-components=1 && \
    chmod 755 /usr/bin/bun

RUN CARGO_HOME=cargo-home cargo install --no-track --root=/usr dufs tokei fclones binwalk && \
    rm -r cargo-home

RUN pipx install --global yt-dlp[default,secretstorage,curl-cffi] ocrmypdf pgsrip \
                          pulsemixer liquidctl undervolt

RUN curl -sLo /usr/bin/kepubify https://github.com/pgaskin/kepubify/releases/latest/download/kepubify-linux-64bit

RUN curl -sLOOO -o date-menu-formatter@marcinjakubowski.github.com.strip.zip -o lan-ip-address@mrhuber.com.strip.zip                                  \
        https://github.com/Leleat/Tiling-Assistant/releases/download/v50/tiling-assistant@leleat-on-github.shell-extension.zip                        \
        https://github.com/stuarthayhurst/alphabetical-grid-extension/releases/latest/download/AlphabeticalAppGrid@stuarthayhurst.shell-extension.zip \
        https://github.com/mzur/gnome-shell-batime/releases/latest/download/batime@martin.zurowietz.de.zip                                            \
        https://github.com/marcinjakubowski/date-menu-formatter/archive/master.zip                                                                    \
        https://github.com/Josholith/gnome-extension-lan-ip-address/archive/master.zip                                                             && \
    for F in *.strip.zip; do D=/usr/share/gnome-shell/extensions/${F%.strip.zip};                    mkdir -p $D && bsdtar xf $F -C $D --strip-components=1; done && rm *.strip.zip && \
    for F in       *.zip; do D=/usr/share/gnome-shell/extensions/${F%.zip}; D=${D%.shell-extension}; mkdir -p $D && bsdtar xf $F -C $D;                      done && rm       *.zip && \
    glib-compile-schemas /usr/share/gnome-shell/extensions/AlphabeticalAppGrid@stuarthayhurst/schemas

RUN curl -sLO --output-dir /usr/share/fonts https://github.com/dmlls/whatsapp-emoji-linux/releases/latest/download/WhatsAppEmoji.ttf


### NOTE: base ###
FROM common AS base

RUN ! [ -f /usr/lib/udev/rules.d/60-persistent-hidraw.rules ]
ENV PATH=${PATH#/tmp:}
COPY files/ /
RUN rm uname && dconf update


### NOTE: nvidia ###
FROM common AS nvidia

ARG PIPX_GLOBAL_HOME=/usr/lib/pipx
ARG PIPX_GLOBAL_BIN_DIR=/usr/bin
ARG PIPX_MAN_DIR=/usr/share/man

RUN --mount=type=bind,src=files-nvidia/etc/nvidia/kernel.conf,dst=/etc/nvidia/kernel.conf,relabel=shared \
    curl -sLO --output-dir /etc/yum.repos.d https://negativo17.org/repos/fedora-nvidia.repo           && \
    dnf install -y nvidia-driver{,-libs.i686} dkms-nvidia cuda{,-cudnn}                                  \
                   nvidia-settings golang-github-nvidia-container-toolkit nvtop                       && \
    rm -f /etc/nvidia/kernel.conf.rpmnew                                                              && \
    echo NoDisplay=true >>/usr/share/applications/nvtop.desktop                                       && \
    dkms autoinstall

RUN python -m venv /usr/lib/nvidia-venv && /usr/lib/nvidia-venv/bin/pip install nvidia-ml-py

RUN dnf install -y python3.12 && \
    pipx install --global --python=python3.12 whisper-ctranslate2

RUN curl -sL https://github.com/ollama/ollama/releases/latest/download/ollama-linux-amd64.tgz \
        | tar xz --exclude={cuda_v11,rocm,cpu}_avx --exclude=libcu*.so*                    && \
    mv bin/ollama /usr/bin/ && mv lib/ollama /usr/lib/ && rm -r bin lib

RUN ! [ -f /usr/lib/udev/rules.d/60-persistent-hidraw.rules ]
ENV PATH=${PATH#/tmp:}
COPY files/ files-nvidia/ /
RUN rm uname && dconf update
