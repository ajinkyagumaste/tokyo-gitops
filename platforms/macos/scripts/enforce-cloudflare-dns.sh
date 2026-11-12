#!/bin/bash
# Fleet policy remediation: configure Cloudflare 1.1.1.1 on enabled
# macOS network services, excluding common VPN/tunnel services.
# WARNING: Public DNS can break internal names, VPN split DNS, or enterprise policy.
set -euo pipefail

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Must run as root" >&2
  exit 1
fi

changed=0
while IFS= read -r service; do
  [[ -n "$service" ]] || continue
  [[ "$service" == "An asterisk"* ]] && continue
  [[ "$service" == \** ]] && continue  # disabled network service
  case "$service" in
    *VPN*|*vpn*|*Tunnel*|*tunnel*|*WireGuard*|*Tailscale*|*GlobalProtect*|*Zscaler*|*Cisco*)
      echo "Skipping VPN/tunnel service: $service"
      continue
      ;;
  esac

  current="$(/usr/sbin/networksetup -getdnsservers "$service" 2>/dev/null || true)"
  if [[ "$current" == "1.1.1.1" ]]; then
    echo "Already configured: $service"
    continue
  fi

  /usr/sbin/networksetup -setdnsservers "$service" 1.1.1.1
  echo "Set Cloudflare DNS on: $service"
  changed=$((changed + 1))
done < <(/usr/sbin/networksetup -listallnetworkservices)

echo "Finished: updated $changed network service(s)."
