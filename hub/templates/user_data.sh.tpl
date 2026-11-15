#!/bin/bash
set -eux

curl -fsSL https://tailscale.com/install.sh | sh

cat > /etc/sysctl.d/99-tailscale.conf <<'CONF'
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
CONF
sysctl -p /etc/sysctl.d/99-tailscale.conf

tailscale up \
  --client-id="${tailscale_client_id}?preauthorized=true&ephemeral=false" \
  --audience="${tailscale_audience}" \
  --advertise-tags=${hub_router_tag} \
  --advertise-routes=${advertised_routes} \
