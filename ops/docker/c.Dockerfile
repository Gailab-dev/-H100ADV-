FROM --platform=$BUILDPLATFORM golang:1.24-bookworm AS build
ARG TARGETOS
ARG TARGETARCH
WORKDIR /build
COPY h100_module_c/go.mod h100_module_c/go.sum ./
RUN go mod download
COPY h100_module_c/ ./
RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -trimpath -o /module-c ./cmd/server
RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -trimpath -o /roi-cleaner ./cmd/roi_cleaner

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl tzdata && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=build /module-c /usr/local/bin/module-c
COPY --from=build /roi-cleaner /usr/local/bin/roi-cleaner
ENV TZ=Asia/Seoul PORT=8443 HEALTH_TLS_NAME=localhost
EXPOSE 8443
HEALTHCHECK --interval=10s --timeout=5s --retries=12 CMD curl --resolve "$HEALTH_TLS_NAME:8443:127.0.0.1" --cacert /certs/ca.crt -fsS "https://$HEALTH_TLS_NAME:8443/healthz" || exit 1
CMD ["module-c"]
