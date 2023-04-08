FROM menci/archlinuxarm:latest@sha256:4c544d2b55dcf13e4c11373a76826ece387073f0dd76f1a079291e0407f00af8

ARG BOARD=rpi4
ENV BOARD $BOARD

ARG ARCH=arm
ENV ARCH $ARCH

ARG PLATFORM=v2-hdmiusb
ENV PLATFORM $PLATFORM

ARG PIKVM_REPO_KEY=912C773ABBD1B584
ENV PIKVM_REPO_KEY $PIKVM_REPO_KEY

ARG PIKVM_REPO_URL=https://files.pikvm.org/repos/arch/
ENV PIKVM_REPO_URL $PIKVM_REPO_URL

RUN pacman-key --init \
    && pacman-key --populate archlinuxarm

RUN ( \
        mkdir -p /etc/gnupg \
        && echo standard-resolver >> /etc/gnupg/dirmngr.conf \
        && ( \
            pacman-key --keyserver hkps://keyserver.ubuntu.com:443 -r $PIKVM_REPO_KEY \
            || pacman-key --keyserver hkps://keys.gnupg.net:443 -r $PIKVM_REPO_KEY \
            || pacman-key --keyserver hkps://pgp.mit.edu:443 -r $PIKVM_REPO_KEY \
        ) \
    ) \
    && pacman-key --lsign-key $PIKVM_REPO_KEY \
    && echo -e "\n[pikvm]" >> /etc/pacman.conf \
    && echo "Server = $PIKVM_REPO_URL/$BOARD-$ARCH" >> /etc/pacman.conf \
    && echo "SigLevel = Required DatabaseOptional" >> /etc/pacman.conf

RUN pacman --noconfirm --ask=4 -Syu

RUN pacman -S --noconfirm kvmd-platform-$PLATFORM-$BOARD

RUN pacman -Sy --noconfirm git gcc make
RUN git clone https://github.com/pikvm/ustreamer.git /tmp/ustreamer
RUN cd /tmp/ustreamer \
    && make -j4 \
    && sudo PREFIX=/usr make install

ARG WEBUI_ADMIN_PASSWD
ENV WEBUI_ADMIN_PASSWD $WEBUI_ADMIN_PASSWD
RUN echo "$WEBUI_ADMIN_PASSWD" | kvmd-htpasswd set --read-stdin admin

COPY override.yaml /etc/kvmd/override.yaml

RUN kvmd-gencert --do-the-thing
RUN kvmd-gencert --do-the-thing --vnc

EXPOSE 443
COPY run.sh run.sh
CMD ./run.sh
