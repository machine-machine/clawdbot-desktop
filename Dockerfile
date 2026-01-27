# VNC + noVNC + Moltbot desktop worker (Pretty XFCE4 with macOS styling)
FROM nvidia/cuda:12.4.1-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    USER=developer \
    VNC_PASSWORD=clawdbot \
    DISPLAY=:1 \
    MOLTBOT_HOME=/moltbot_home \
    WORKSPACE=/workspace

# Base packages + XFCE4 desktop environment + theme build dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      locales \
      sudo \
      dbus-x11 \
      # VNC stack
      tigervnc-standalone-server tigervnc-tools \
      novnc websockify \
      x11-xserver-utils \
      # XFCE4 desktop environment (lightweight, VNC-friendly)
      xfce4 \
      xfce4-terminal \
      xfce4-taskmanager \
      xfce4-screenshooter \
      thunar \
      mousepad \
      # macOS-style dock
      plank \
      # Theme build dependencies (required for WhiteSur)
      sassc \
      libglib2.0-dev \
      libglib2.0-dev-bin \
      libxml2-utils \
      gtk2-engines-murrine \
      gtk2-engines-pixbuf \
      # Core utilities
      curl ca-certificates wget \
      git \
      bash \
      supervisor \
      htop \
      nano \
      # Browser for Claude Max / Moltbot browser auth
      chromium-browser \
      fonts-liberation fonts-dejavu-core fonts-noto-color-emoji \
      libnss3 libxss1 libasound2 \
      # VS Code dependencies (optional, for future)
      libsecret-1-0 \
    && locale-gen en_US.UTF-8 && \
    # Clean up
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* /tmp/*

# Create non-root user
RUN useradd -m -s /bin/bash ${USER} && \
    echo "${USER} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USER}

# Switch to developer user for theme installation (themes install to ~/.themes)
USER ${USER}
WORKDIR /home/${USER}

# Install WhiteSur themes (build continues even if themes fail)
RUN git clone https://github.com/vinceliuice/WhiteSur-gtk-theme.git --depth=1 && \
    cd WhiteSur-gtk-theme && \
    ./install.sh -c Dark || true; \
    cd /home/${USER} && rm -rf WhiteSur-gtk-theme; \
    \
    git clone https://github.com/vinceliuice/WhiteSur-icon-theme.git --depth=1 && \
    cd WhiteSur-icon-theme && \
    ./install.sh || true; \
    cd /home/${USER} && rm -rf WhiteSur-icon-theme; \
    \
    git clone https://github.com/vinceliuice/McMojave-cursors.git --depth=1 && \
    cd McMojave-cursors && \
    ./install.sh || true; \
    cd /home/${USER} && rm -rf McMojave-cursors; \
    \
    exit 0

# Download WhiteSur wallpaper
RUN mkdir -p ~/.local/share/backgrounds && \
    curl -sL "https://raw.githubusercontent.com/vinceliuice/WhiteSur-wallpapers/main/4k/WhiteSur-dark.png" \
    -o ~/.local/share/backgrounds/wallpaper.png || true

# Install Node 22 (via NodeSource) and Moltbot
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash - && \
    sudo apt-get update && \
    sudo apt-get install -y nodejs && \
    sudo rm -rf /var/lib/apt/lists/* && \
    curl -fsSL https://molt.bot/install.sh | bash

# Prepare directories
RUN sudo mkdir -p ${MOLTBOT_HOME} ${WORKSPACE} && \
    sudo chown -R ${USER}:${USER} ${MOLTBOT_HOME} ${WORKSPACE}

# Configure XFCE4 for VNC (disable compositing, set theme)
RUN mkdir -p /home/${USER}/.config/xfce4/xfconf/xfce-perchannel-xml && \
    mkdir -p /home/${USER}/.config/xfce4/panel && \
    mkdir -p /home/${USER}/.config/plank/dock1/launchers && \
    mkdir -p /home/${USER}/Desktop

VOLUME ["${MOLTBOT_HOME}", "${WORKSPACE}"]

# Copy configs
USER root
COPY scripts/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY scripts/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY scripts/xstartup /home/developer/.vnc/xstartup
COPY config/xfce4/ /home/developer/.config/xfce4/
COPY config/plank/ /home/developer/.config/plank/
COPY config/desktop/ /home/developer/Desktop/

RUN chmod +x /usr/local/bin/entrypoint.sh && \
    chmod +x /home/developer/.vnc/xstartup && \
    chown -R developer:developer /home/developer

# Create index.html redirect
RUN echo '<!DOCTYPE html><html><head><meta http-equiv="refresh" content="0; url=/vnc.html"></head></html>' > /usr/share/novnc/index.html

EXPOSE 18789 6080

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
