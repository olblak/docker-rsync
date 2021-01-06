FROM debian:stable

VOLUME /srv/releases/jenkins

EXPOSE 873

ENV TINI_VERSION v0.19.0

ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /bin/tini

RUN chmod +x /bin/tini

COPY config/rsyncd.conf /etc/rsyncd.conf

COPY config/jenkins.motd /etc/jenkins.motd

RUN apt-get update && \
    apt-get install -y rsync

ENTRYPOINT ["/bin/tini", "--"]

CMD [ "/usr/bin/rsync","--no-detach","--daemon","--config","/etc/rsyncd.conf" ]
