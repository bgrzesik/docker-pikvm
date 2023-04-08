#!/bin/bash

usermod -a -G $(stat -c "%G" /dev/gpiochip0) kvmd
chown root:video /dev/kvmd-video
chown root:gpio /dev/kvmd-hid

sudo -u kvmd-nginx /usr/sbin/nginx -p /etc/kvmd/nginx -c /etc/kvmd/nginx/nginx.conf -g 'pid /run/kvmd/nginx.pid; user kvmd-nginx; error_log stderr;' &

sudo -u kvmd /usr/bin/kvmd --run
