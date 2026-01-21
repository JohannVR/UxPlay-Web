FROM ghcr.io/linuxserver/baseimage-selkies:alpine323

ENV HARDEN_DESKTOP=true \
    HARDEN_OPENBOX=true \
    TITLE=UxPlay \
    RESTART_APP=true \
    AIRPLAY_NAME="UxPlay-Web"

RUN apk add --no-cache \
    avahi \
    dbus \
    gstreamer \
    gst-plugins-base \
    gst-plugins-good \
    gst-plugins-bad \
    gst-libav \
    uxplay

# 1. Prepare D-Bus and Avahi directories
RUN mkdir -p /var/run/dbus /var/run/avahi-daemon && \
    sed -i 's/#enable-dbus=yes/enable-dbus=yes/g' /etc/avahi/avahi-daemon.conf

# 2. Create S6 service for D-Bus (Essential for Avahi)
RUN mkdir -p /etc/services.d/dbus && \
    echo -e "#!/usr/bin/with-contenv bash\n\
    exec dbus-daemon --system --nofork" > /etc/services.d/dbus/run && \
    chmod +x /etc/services.d/dbus/run

# 3. Create S6 service for Avahi-daemon
RUN mkdir -p /etc/services.d/avahi && \
    echo -e "#!/usr/bin/with-contenv bash\n\
    # Wait for dbus socket to exist before starting\n\
    while [ ! -S /var/run/dbus/system_bus_socket ]; do sleep 1; done\n\
    exec /usr/sbin/avahi-daemon --no-drop-root" > /etc/services.d/avahi/run && \
    chmod +x /etc/services.d/avahi/run

# 4. Configure Autostart for UxPlay
RUN mkdir -p /defaults && \
    echo "sleep 5 && uxplay -n \"\${AIRPLAY_NAME}\" -nh -fs" > /defaults/autostart
