FROM --platform=$BUILDPLATFORM cculianu/fulcrum:v2.1.0

ARG ARCH
ARG TARGETARCH

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends ca-certificates netcat-openbsd tini wget && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN \
    wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_${TARGETARCH} && \
    chmod +x /usr/local/bin/yq

COPY ./configurator/target/${ARCH}-unknown-linux-musl/release/configurator /usr/local/bin/configurator
COPY --chmod=0755 ./docker_entrypoint.sh /usr/local/bin/docker_entrypoint.sh

# Add health check scripts
COPY --chmod=0755 ./health-check/check-synced.sh /usr/local/bin/check-synced.sh
COPY --chmod=0755 ./health-check/check-electrum.sh /usr/local/bin/check-electrum.sh

EXPOSE 50001 50002
VOLUME ["/data"]
ENTRYPOINT ["/usr/local/bin/docker_entrypoint.sh"]