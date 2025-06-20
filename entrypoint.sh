#!/usr/bin/sh
set -e

mkdir -p /run/dbus
if [ -f /run/dbus/pid ]; then
    rm /run/dbus/pid
fi
dbus-daemon --config-file=/usr/share/dbus-1/system.conf

LD_PRELOAD=/bind_redirect.so warp-svc --accept-tos &

echo "Waiting for warp-svc to start..."
sleep 2

warp-cli --accept-tos registration new
warp-cli --accept-tos mode proxy
warp-cli --accept-tos connect

while true; do
    sleep 60
done
