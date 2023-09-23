#!/bin/ash
# shellcheck shell=dash

set -eux

# Replace repositories
sed -i "s|https://downloads.openwrt.org|${MIRROR_URL}|" /etc/opkg/distfeeds.conf

opkg update

# Install prerequisites for synced folders
opkg install rsync sudo
