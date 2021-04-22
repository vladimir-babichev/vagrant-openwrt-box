#!/bin/ash

set -eux

opkg update

# Install prerequisites for synced folders
opkg install rsync sudo
