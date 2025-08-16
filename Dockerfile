FROM --platform=$BUILDPLATFORM debian:bullseye AS builder

ARG ARCH
ARG TARGETARCH

# Common packages
RUN apt-get update -y && apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    pkg-config \
    qt5-qmake \
    curl \
    build-essential

# Install Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable
ENV PATH="/root/.cargo/bin:${PATH}"

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

# Build Fulcrum
RUN git clone --branch v1.11.1 --depth 1 https://github.com/cculianu/Fulcrum.git . && \
    git checkout v1.11.1

RUN export CC=${ARCH}-linux-gnu-gcc && \
    export CXX=${ARCH}-linux-gnu-g++ && \
    ${ARCH}-linux-gnu-qmake -makefile PREFIX=/usr \
        "QMAKE_CXXFLAGS_RELEASE -= -O3" \
        "QMAKE_CXXFLAGS_RELEASE += -O1" \
        "LIBS += -L/src/staticlibs/rocksdb/bin/linux/${ARCH}" \
        Fulcrum.pro \
        && \
    make -j1 install && \
    ${ARCH}-linux-gnu-strip Fulcrum

# Build configurator
WORKDIR /configurator
COPY ./configurator/ ./

# Build configurator natively (simpler approach)
RUN cargo build --release

FROM debian:bullseye-slim

ARG TARGETARCH

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends ca-certificates curl libbz2-1.0 libjemalloc2 libqt5network5 libzmq5 netcat openssl tini wget zlib1g && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY --from=builder /src/Fulcrum /usr/bin/Fulcrum

# Copy configurator with correct target path
COPY --from=builder /configurator/target/release/configurator /usr/bin/configurator

VOLUME ["/data"]
ENV DATA_DIR=/data

ENV SSL_CERTFILE=${DATA_DIR}/fulcrum.crt
ENV SSL_KEYFILE=${DATA_DIR}/fulcrum.key

ARG PLATFORM
ARG ARCH
RUN wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_${TARGETARCH} && chmod +x /usr/local/bin/yq

COPY ./docker_entrypoint.sh /usr/local/bin/docker_entrypoint.sh
RUN chmod a+x /usr/local/bin/docker_entrypoint.sh

# Add health check scripts
COPY ./health-check/check-synced.sh /usr/local/bin/check-synced.sh
COPY ./health-check/check-electrum.sh /usr/local/bin/check-electrum.sh
RUN chmod +x /usr/local/bin/check-synced.sh /usr/local/bin/check-electrum.sh

# Copy assets for StartOS 0.4.0
COPY ./javascript/ /assets/javascript/
COPY ./assets/ /assets/