#!/usr/bin/env bash
D=`ip -br a | grep en | awk '{print $1}'`
cat <<EOT >> /etc/systemd/network/20-wired.network
[Match]
Name=$D

[Network]
DHCP=yes
EOT
