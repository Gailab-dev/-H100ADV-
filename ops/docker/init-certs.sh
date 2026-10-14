#!/bin/sh
set -eu
if [ -s /certs/server.crt ] && [ -s /certs/server.key ] && [ -s /certs/ca.crt ]; then
    echo 'Existing local certificates preserved.'
    exit 0
fi
umask 077
openssl req -x509 -newkey rsa:2048 -nodes -days 365 -subj '/CN=H100 Local Development' -keyout /certs/server.key -out /certs/server.crt -addext 'subjectAltName=DNS:localhost,DNS:module-c,DNS:module-d,IP:127.0.0.1'
cp /certs/server.crt /certs/ca.crt
echo 'Local development certificates created.'
