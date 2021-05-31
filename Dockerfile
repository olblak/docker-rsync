FROM debian:stable

VOLUME /srv/releases/jenkins

EXPOSE 873

ARG TINI_VERSION=v0.19.0

## URL source: COPY cannot be used
# hadolint ignore=DL3020
ADD "https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini" /bin/tini

RUN chmod +x /bin/tini

COPY config/rsyncd.conf /etc/rsyncd.conf

COPY config/jenkins.motd /etc/jenkins.motd

## We always want the latest rsync version
# hadolint ignore=DL3008
RUN apt-get update && \
    apt-get install -y --no-install-recommends rsync && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["/bin/tini", "--"]

CMD [ "/usr/bin/rsync","--no-detach","--daemon","--config","/etc/rsyncd.conf" ]
