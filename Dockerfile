FROM debian:bookworm-20230814-slim

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

COPY config/rsyncd.conf /etc/rsyncd.conf

COPY config/jenkins.motd /etc/jenkins.motd

VOLUME ["/srv/releases/jenkins", "/tmp", "/var/run"]

EXPOSE 873

ENTRYPOINT ["/bin/tini", "--"]

CMD [ "/usr/bin/rsync","--no-detach","--daemon","--config","/etc/rsyncd.conf" ]
