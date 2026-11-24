#!/usr/bin/env bash
set -euo pipefail

RG="${1:-rg-ridgeline-prod-wus3}"
VNET="${2:-vnet-ridgeline-prod-wus3}"
SQL_FQDN="${3:-sql-ridgeline-prod-wus3.database.windows.net}"
FRONT_HOST="${4:-ca-proxy-ridgeline-prod-wus3.proudflower-c1a593a0.westus3.azurecontainerapps.io}"
OUT_DIR="${5:-docs/evidence/phase2-outputs}"

mkdir -p "$OUT_DIR"

echo "=== [NET-2] NSG Rules on Every Subnet ===" | tee "$OUT_DIR/NET-2_nsgs.txt"
for snet in snet-proxy snet-web snet-app snet-data; do
  nsg_id=$(az network vnet subnet show --resource-group "$RG" --vnet-name "$VNET" --name "$snet" --query "networkSecurityGroup.id" -o tsv)
  nsg_name=$(basename "$nsg_id")
  echo "--- Subnet: $snet | NSG: $nsg_name ---" | tee -a "$OUT_DIR/NET-2_nsgs.txt"
  az network nsg rule list --resource-group "$RG" --nsg-name "$nsg_name" -o table | tee -a "$OUT_DIR/NET-2_nsgs.txt"
done

echo "=== [NET-3] Check for Exposed Management Ports (22, 3389) ===" | tee "$OUT_DIR/NET-3_mgmt_ports.txt"
for snet in snet-proxy snet-web snet-app snet-data; do
  nsg_id=$(az network vnet subnet show --resource-group "$RG" --vnet-name "$VNET" --name "$snet" --query "networkSecurityGroup.id" -o tsv | tr -d '\r')
  nsg_name=$(basename "$nsg_id")
  echo "--- Subnet: $snet | NSG: $nsg_name ---" | tee -a "$OUT_DIR/NET-3_mgmt_ports.txt"
  az network nsg show --resource-group "$RG" --name "$nsg_name" \
    --query "securityRules[].{Name:name,Priority:priority,Direction:direction,Access:access,Protocol:protocol,SourceAddr:sourceAddressPrefix,DestPort:destinationPortRange}" \
    -o table | tee -a "$OUT_DIR/NET-3_mgmt_ports.txt"
done

echo "=== [NET-5] Private DNS Zones & VNet Links ===" | tee "$OUT_DIR/NET-5_private_dns.txt"
az network private-dns zone list --resource-group "$RG" -o table | tee -a "$OUT_DIR/NET-5_private_dns.txt"
az network private-dns link vnet list --resource-group "$RG" --zone-name "privatelink.database.windows.net" -o table | tee -a "$OUT_DIR/NET-5_private_dns.txt"
az network private-dns record-set a list --resource-group "$RG" --zone-name "privatelink.database.windows.net" -o table | tee -a "$OUT_DIR/NET-5_private_dns.txt"

echo "=== [NET-6] TLS Certificate & Expiration Check ===" | tee "$OUT_DIR/NET-6_tls_cert.txt"
echo | openssl s_client -servername "$FRONT_HOST" -connect "$FRONT_HOST:443" 2>/dev/null   | openssl x509 -noout -subject -issuer -dates | tee -a "$OUT_DIR/NET-6_tls_cert.txt"

echo "=== [NET-7] Front-End HTTP Response Check ===" | tee "$OUT_DIR/NET-7_edge_check.txt"
curl -sS -I "https://$FRONT_HOST" | tee -a "$OUT_DIR/NET-7_edge_check.txt"

echo "Saved Phase 2 evidence outputs to $OUT_DIR"
