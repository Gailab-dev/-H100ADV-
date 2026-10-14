FROM alpine:3.22
RUN apk add --no-cache openssl
COPY ops/docker/init-certs.sh /init-certs.sh
ENTRYPOINT ["sh", "/init-certs.sh"]
