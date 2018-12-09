FROM ubuntu:18.04

ENV VERSION=0.0.1

RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y \
        cmake \
        uuid-dev \
        git \
        libwebsockets-dev \
        pkg-config && \
    mkdir /build && cd /build && \
    git clone https://github.com/eclipse/mosquitto.git && \
    git clone https://github.com/jpmens/mosquitto-auth-plug && \
    cd /build/mosquitto && \
    make -j "$(nproc)" \
        WITH_ADNS=no \
        WITH_DOCS=no \
        WITH_MEMORY_TRACKING=no \
        WITH_SHARED_LIBRARIES=no \
        WITH_SRV=no \
        WITH_STRIP=yes \
        WITH_TLS_PSK=no \
        WITH_WEBSOCKETS=yes \
        prefix=/usr \
        binary && \
    addgroup --system mosquitto 2>/dev/null && \
    adduser --system --disabled-password --no-create-home --home /var/empty --shell /sbin/nologin --gecos mosquitto --ingroup mosquitto mosquitto 2>/dev/null && \
    mkdir -p /mosquitto/config /mosquitto/data /mosquitto/log && \
    install -d /usr/sbin/ && \
    install -s -m755 /build/mosquitto/src/mosquitto /usr/sbin/mosquitto && \
    install -s -m755 /build/mosquitto/src/mosquitto_passwd /usr/bin/mosquitto_passwd && \
    install -m644 /build/mosquitto/mosquitto.conf /mosquitto/config/mosquitto.conf && \
    chown -R mosquitto:mosquitto /mosquitto && \
    apt-get install -y libmongoc-dev libmosquitto-dev && \
    cd /build/mosquitto-auth-plug && \
    cp config.mk.in config.mk && \
    make MOSQUITTO_SRC=/build/mosquitto \
         BACKEND_MYSQL=no \
         BACKEND_MONGO=yes && \
    cp /build/mosquitto-auth-plug/auth-plug.so /usr/local/lib && \
    cp /build/mosquitto-auth-plug/np /usr/bin

COPY mosquitto.conf /mosquitto/mosquitto.conf

RUN cat /mosquitto/mosquitto.conf

VOLUME ["/mosquitto/data", "/mosquitto/log"]

EXPOSE 1883

CMD ["mosquitto", "-c", "/mosquitto/mosquitto.conf"]   