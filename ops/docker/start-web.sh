#!/bin/sh
set -eu
if [ -s /certs/ca.crt ]; then
    keytool -delete -alias h100-local -cacerts -storepass changeit >/dev/null 2>&1 || true
    keytool -importcert -noprompt -alias h100-local -file /certs/ca.crt -cacerts -storepass changeit
fi
mkdir -p /var/lib/tomcat9/logs
exec catalina.sh run
