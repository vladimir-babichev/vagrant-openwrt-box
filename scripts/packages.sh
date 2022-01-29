#!/bin/ash
# shellcheck shell=dash

set -eux

opkg update

# Install prerequisites for synced folders
opkg install rsync sudo
