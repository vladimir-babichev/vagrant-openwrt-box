#!/bin/ash

set -eux

# Configure WAN network on the second attached interface
uci batch <<EOF
set network.wan=interface
set network.wan.ifname='eth1'
set network.wan.proto='dhcp'
EOF

# Configure LAN network on the third attached interface
uci batch <<EOF
set network.lan=interface
set network.lan.ifname='eth2'
set network.lan.proto='dhcp'
EOF

# Save network configuration
uci commit
fsync /etc/config/network
