FROM jlesage/baseimage-gui:ubuntu-22.04-v4@sha256:51c11dd8405ec18c65b85808ede782e548d8233705c7fb3a62d0dcf0abca55c3

ENV WINEPREFIX /config/wine/
ENV LANG en_US.UTF-8
ENV APP_NAME="Avaya Remote Administration"
ENV FORCE_LATEST_UPDATE="true"
ENV DISABLE_AUTOUPDATE="true"
ENV DISABLE_VIRTUAL_DESKTOP="false"
ENV DISPLAY_WIDTH="900"
ENV DISPLAY_HEIGHT="700"
# Disable WINE Debug messages
ENV WINEDEBUG -all
# Set DISPLAY to allow GUI programs to be run
ENV DISPLAY=:0

RUN apt-get update && \
    apt-get install -y curl software-properties-common gnupg2 winbind xvfb && \
    dpkg --add-architecture i386 && \
    curl -O https://dl.winehq.org/wine-builds/winehq.key && \
    apt-key add winehq.key && \
    add-apt-repository 'deb https://dl.winehq.org/wine-builds/ubuntu/ jammy main' && \
    apt-get install -y winehq-stable=9.0* && \
    apt-get install -y winetricks && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y locales && \
    sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8

EXPOSE 5900

COPY root/ /
RUN chmod +x /startapp.sh