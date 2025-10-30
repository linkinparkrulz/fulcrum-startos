FROM --platform=$BUILDPLATFORM debian:bookworm AS builder

ARG ARCH
ARG TARGETARCH

# Common packages
RUN apt-get update -y && apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    pkg-config \
    qt5-qmake

# Architecture-specific setup
RUN dpkg --add-architecture ${TARGETARCH} && \
    apt-get update -y && \
    apt-get install -y --no-install-recommends \
        crossbuild-essential-${TARGETARCH} \
        openssl:${TARGETARCH} \
        zlib1g-dev:${TARGETARCH} \
        libbz2-dev:${TARGETARCH} \
        libjemalloc-dev:${TARGETARCH} \
        libzmq3-dev:${TARGETARCH} \
        qtbase5-dev:${TARGETARCH}

WORKDIR /src

RUN git clone --branch v2.0.0 --depth 1 https://github.com/cculianu/Fulcrum.git . && \
    git checkout v2.0.0

RUN export CXXFLAGS="-std=c++20" && \
    export CC=${ARCH}-linux-gnu-gcc && \
    export CXX=${ARCH}-linux-gnu-g++ && \
    ${ARCH}-linux-gnu-qmake -makefile PREFIX=/usr \
        "QMAKE_CXXFLAGS_RELEASE -= -O3" \
        "QMAKE_CXXFLAGS_RELEASE -= -std=gnu++2a" \
        "QMAKE_CXXFLAGS_RELEASE += -O1" \
        "QMAKE_CXXFLAGS_RELEASE += -std=c++20" \
        "LIBS += -L/src/staticlibs/rocksdb/bin/linux/${ARCH}" \
        Fulcrum.pro \
        && \
    make -j1 install && \
    ${ARCH}-linux-gnu-strip Fulcrum

FROM debian:bookworm-slim

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends ca-certificates curl libbz2-1.0 libjemalloc2 libqt5network5 libzmq5 netcat-openbsd openssl tini wget zlib1g && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY --from=builder /src/Fulcrum /usr/bin/Fulcrum

VOLUME ["/data"]
ENV DATA_DIR=/data

ENV SSL_CERTFILE=${DATA_DIR}/fulcrum.crt
ENV SSL_KEYFILE=${DATA_DIR}/fulcrum.key

#EXPOSE 50001 50002

ARG PLATFORM
ARG ARCH
ARG TARGETARCH
RUN wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_${TARGETARCH} && chmod +x /usr/local/bin/yq
ADD ./configurator/target/${ARCH}-unknown-linux-musl/release/configurator /usr/local/bin/configurator
COPY ./docker_entrypoint.sh /usr/local/bin/docker_entrypoint.sh
RUN chmod a+x /usr/local/bin/docker_entrypoint.sh
# ENTRYPOINT ["/entrypoint.sh"]

# CMD ["Fulcrum"]

# Add health check scripts
COPY ./health-check/check-synced.sh /usr/local/bin/check-synced.sh
COPY ./health-check/check-electrum.sh /usr/local/bin/check-electrum.sh
RUN chmod +x /usr/local/bin/check-synced.sh /usr/local/bin/check-electrum.sh
