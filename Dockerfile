FROM alpine:latest

RUN apk add --no-cache \
    bash \
    openssh \
    socat \
    && rm -rf /var/cache/apk/*

COPY entry.sh /entry.sh
RUN chmod +x /entry.sh

ENV SOCKET_DIR /.ssh-agent
ENV SSH_AUTH_SOCK ${SOCKET_DIR}/socket
ENV SSH_AUTH_PROXY_SOCK ${SOCKET_DIR}/proxy-socket

VOLUME ${SOCKET_DIR}

ENTRYPOINT [ "/entry.sh" ]
CMD [ "ssh-agent" ]
