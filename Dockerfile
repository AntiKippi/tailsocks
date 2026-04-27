FROM alpine:latest
RUN apk add tailscale --no-cache
RUN apk add microsocks --no-cache --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing/
COPY --chown=root:root entry.sh /entry.sh
RUN chmod 755 /entry.sh

ENTRYPOINT ["/entry.sh"]
