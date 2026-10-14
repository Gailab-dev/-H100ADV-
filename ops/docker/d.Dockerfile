FROM --platform=$BUILDPLATFORM golang:1.24-bookworm AS build
ARG TARGETOS
ARG TARGETARCH
WORKDIR /build
COPY h100_module_d/go.mod h100_module_d/go.sum ./
RUN go mod download
COPY h100_module_d/ ./
RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -trimpath -o /module-d ./cmd/server

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl ffmpeg tzdata && rm -rf /var/lib/apt/lists/*
WORKDIR /app
RUN mkdir -p /data/image /data/video /data/voice /hls
COPY --from=build /module-d /usr/local/bin/module-d
ENV TZ=Asia/Seoul PORT=8443 HEALTH_TLS_NAME=localhost FFMPEG_PATH=/usr/bin/ffmpeg HLS_DIR=/hls FILE_PATH=/data AUDIO_PATH=/data/voice SEGMENT_TIME=1
EXPOSE 8443
HEALTHCHECK --interval=10s --timeout=5s --retries=12 CMD curl --resolve "$HEALTH_TLS_NAME:8443:127.0.0.1" --cacert /certs/ca.crt -fsS "https://$HEALTH_TLS_NAME:8443/healthz" || exit 1
CMD ["module-d"]
