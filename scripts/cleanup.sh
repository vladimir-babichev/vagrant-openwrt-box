#!/bin/ash

set -eux

# Delete the SSH host keys, so they get generated when the box is
# provisioned.
rm -f /etc/dropbear/dropbear_rsa_host_key

# Delete package lists
rm -rf /var/opkg-lists
