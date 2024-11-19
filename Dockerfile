FROM debian:stable-20241111-slim

ARG TINI_VERSION=v0.19.0
## We always want the latest rsync version
# hadolint ignore=DL3008
RUN apt-get update && \
    apt-get install --yes --no-install-recommends ca-certificates curl rsync && \
    curl --silent --show-error --location --output /bin/tini \
    "https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-$(dpkg --print-architecture)" && \
    chmod +x /bin/tini && \
    apt-get remove --purge --yes ca-certificates curl && \
    apt-get autoremove --purge --yes && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ARG RSYNCD_DIR=/rsyncd
ENV RSYNCD_DIR="${RSYNCD_DIR}"
RUN mkdir -p "${RSYNCD_DIR}/run" "${RSYNCD_DIR}/data" /etc/rsyncd.d && \
    chown -R nobody:nogroup "${RSYNCD_DIR}"

COPY rsyncd.conf /etc/rsyncd.conf

WORKDIR /rsyncd/data

VOLUME ["/rsyncd/run","/rsyncd/data","/tmp"]

EXPOSE 873

USER nobody:nogroup

ENTRYPOINT ["/bin/tini","--"]

CMD ["/usr/bin/rsync", "--no-detach","--daemon","--config","/etc/rsyncd.conf"]
