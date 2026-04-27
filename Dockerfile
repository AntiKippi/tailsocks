FROM alpine:latest
RUN apk add tailscale --no-cache
RUN apk add microsocks --no-cache --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing/
COPY --chown=root:root --chmod=755 entry.sh /entry.sh
EXPOSE 1080

ENTRYPOINT ["/entry.sh"]
