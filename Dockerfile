FROM ubuntu:18.04

ADD public.key /
RUN apt-get update && \
    apt-get install -y gnupg2
RUN echo "deb http://archive.neon.kde.org/testing bionic main" >> /etc/apt/sources.list.d/neon.list
RUN echo "deb-src http://archive.neon.kde.org/testing bionic main" >> /etc/apt/sources.list.d/neon.list
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections && \
    echo keyboard-configuration keyboard-configuration/layout select 'English (US)' | debconf-set-selections && \
    echo keyboard-configuration keyboard-configuration/layoutcode select 'us' | debconf-set-selections && \
    echo "resolvconf resolvconf/linkify-resolvconf boolean false" | debconf-set-selections && \
    apt-key add /public.key && \
    rm /public.key && \
    apt-get update && \
    apt-get install -y ubuntu-minimal ubuntu-standard neon-desktop plasma-workspace-wayland kwin-wayland kwin-wayland-backend-x11 kwin-wayland-backend-wayland kwin && \
    apt-get dist-upgrade -y && \
    groupadd admin && \
    # Refresh apt cache once more now that appstream is installed \
    rm -r /var/lib/apt/lists/* && \
    apt-get update && \
    cp /usr/lib/x86_64-linux-gnu/libexec/kf5/start_kdeinit /root/ && \
    rm /usr/lib/x86_64-linux-gnu/libexec/kf5/start_kdeinit && \
    cp /root/start_kdeinit /usr/lib/x86_64-linux-gnu/libexec/kf5/start_kdeinit && \
    # Wayland bits \
    mkdir /run/neon
ENV DISPLAY=:0
ENV KDE_FULL_SESSION=true
ENV SHELL=/bin/bash

RUN useradd -G admin,video -ms /bin/bash kevin && \
    mkdir -p /home/kevin/.config/ && \
    echo "kevin:foo" | chpasswd && \
    chown -R kevin:kevin /home/kevin && \
    chmod -R 770 /home/kevin && \
    echo 'neon ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && \
    chown kevin:kevin /run/neon 

ENV XDG_RUNTIME_DIR=/run/neon

RUN apt-get install -y supervisor xrdp x11vnc xvfb dbus-x11 
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY xrdp.ini /etc/xrdp/xrdp.ini
COPY entry.sh /root/entry.sh
RUN chmod +x /root/entry.sh

RUN mkdir -p /var/log/supervisor
RUN dbus-uuidgen > /etc/machine-id

# Allow all users to connect via RDP.
RUN xrdp-keygen xrdp auto
RUN sed -i '/TerminalServerUsers/d' /etc/xrdp/sesman.ini && \
    sed -i '/TerminalServerAdmins/d' /etc/xrdp/sesman.ini
    
#USER kevin
COPY gitconfig /home/kevin/.gitconfig
WORKDIR /home/kevin

EXPOSE 3389
EXPOSE 5900
ENV PASSWORD=foo
ENV VNC_RES="1920x1080"

ENTRYPOINT ["/bin/bash", "/root/entry.sh"]
