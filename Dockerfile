FROM --platform=$BUILDPLATFORM debian:bullseye AS builder

ARG ARCH=aarch64

# Common packages
RUN apt update -y && apt install -y \
    git \
    pkg-config \
    qt5-qmake

# Architecture-specific setup
RUN if [ "$ARCH" = "aarch64" ]; then \
        dpkg --add-architecture arm64 && \
        apt update && \
        apt install -y \
        crossbuild-essential-arm64 \
        openssl:arm64 \
        zlib1g-dev:arm64 \
        libbz2-dev:arm64 \
        libjemalloc-dev:arm64 \
        libzmq3-dev:arm64 \
        qtbase5-dev:arm64; \
        export CC=aarch64-linux-gnu-gcc; \
        export CXX=aarch64-linux-gnu-g++; \
    else \
        apt install -y \
        build-essential \
        openssl \
        zlib1g-dev \
        libbz2-dev \
        libjemalloc-dev \
        libzmq3-dev \
        qtbase5-dev; \
    fi

WORKDIR /src

RUN git clone --branch v1.11.1 https://github.com/cculianu/Fulcrum.git . && \
    git checkout v1.11.1

RUN if [ "$ARCH" = "aarch64" ]; then \
        aarch64-linux-gnu-qmake -makefile PREFIX=/usr \
            "QMAKE_CXXFLAGS_RELEASE -= -O3" \
            "QMAKE_CXXFLAGS_RELEASE += -O1" \
            "LIBS += -L/src/staticlibs/rocksdb/bin/linux/aarch64" \
            Fulcrum.pro \
            && \
        make -j1 install && \
        aarch64-linux-gnu-strip Fulcrum; \
    else \
        qmake -makefile PREFIX=/usr "QMAKE_CXXFLAGS_RELEASE -= -O3" "QMAKE_CXXFLAGS_RELEASE += -O1" Fulcrum.pro && \
        make -j1 install && \
        strip Fulcrum; \
    fi

FROM debian:bullseye-slim

RUN apt update && \
    apt install -y openssl libqt5network5 zlib1g libbz2-1.0 libjemalloc2 libzmq5 tini wget curl netcat && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY --from=builder /src/Fulcrum /usr/bin/Fulcrum

VOLUME ["/data"]
ENV DATA_DIR=/data

ENV SSL_CERTFILE=${DATA_DIR}/fulcrum.crt
ENV SSL_KEYFILE=${DATA_DIR}/fulcrum.key

ARG PLATFORM
ARG ARCH
ARG TARGETARCH
RUN wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_${TARGETARCH} && chmod +x /usr/local/bin/yq
ADD ./configurator/target/${ARCH}-unknown-linux-musl/release/configurator /usr/local/bin/configurator
COPY ./docker_entrypoint.sh /usr/local/bin/docker_entrypoint.sh
RUN chmod a+x /usr/local/bin/docker_entrypoint.sh

# Add health check scripts
ADD ./health-check/*.sh /usr/local/bin/
ADD ./docker_entrypoint.sh /usr/local/bin/docker_entrypoint.sh
RUN chmod a+x /usr/local/bin/*.sh