FROM debian:bookworm-20230814-slim

## We always want the latest rsync version
# hadolint ignore=DL3008
RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates curl rsync && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ARG TINI_VERSION=v0.19.0
RUN curl --silent --show-error --location --output /bin/tini \
    "https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-$(dpkg --print-architecture)" \
    && chmod +x /bin/tini

COPY config/rsyncd.conf /etc/rsyncd.conf

COPY config/jenkins.motd /etc/jenkins.motd

VOLUME /srv/releases/jenkins

EXPOSE 873


ENTRYPOINT ["/bin/tini", "--"]

CMD [ "/usr/bin/rsync","--no-detach","--daemon","--config","/etc/rsyncd.conf" ]
