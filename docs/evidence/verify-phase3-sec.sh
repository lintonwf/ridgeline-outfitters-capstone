#!/usr/bin/env bash
set -euo pipefail

RG="${1:-rg-ridgeline-prod-wus3}"
KV="${2:-kv-ridgeline-prod-64hvdp}"
SQL_SERVER="${3:-sql-ridgeline-prod-wus3}"
SQL_DB="${4:-sqldb-ridgeline-prod-wus3}"
STG="${5:-stridgelineprod64hvdp}"
OUT_DIR="${6:-docs/evidence/phase3-outputs}"

mkdir -p "$OUT_DIR"

echo "=== [SEC-2] Encryption at Rest & In Transit ===" | tee "$OUT_DIR/SEC-2_encryption.txt"
echo "--- Azure SQL Transparent Data Encryption (TDE) & TLS ---" | tee -a "$OUT_DIR/SEC-2_encryption.txt"
az sql db tde show --resource-group "$RG" --server "$SQL_SERVER" --database "$SQL_DB" -o table | tee -a "$OUT_DIR/SEC-2_encryption.txt"
az sql server show --resource-group "$RG" --name "$SQL_SERVER" --query "{Name:name,MinTls:minimalTlsVersion,PublicNetworkAccess:publicNetworkAccess}" -o table | tee -a "$OUT_DIR/SEC-2_encryption.txt"

echo "--- Storage Account Encryption & HTTPS-Only ---" | tee -a "$OUT_DIR/SEC-2_encryption.txt"
az storage account show --resource-group "$RG" --name "$STG"   --query "{Name:name,HttpsOnly:enableHttpsTrafficOnly,MinTls:minimumTlsVersion,EncryptionKeySource:encryption.keySource}" -o table | tee -a "$OUT_DIR/SEC-2_encryption.txt"

echo "--- App Service HTTPS-Only & TLS ---" | tee -a "$OUT_DIR/SEC-2_encryption.txt"
az webapp show --resource-group "$RG" --name "app-ridgeline-prod-wus3"   --query "{Name:name,HttpsOnly:httpsOnly,MinTls:siteConfig.minTlsVersion}" -o table | tee -a "$OUT_DIR/SEC-2_encryption.txt"

echo "=== [SEC-3] Key Vault Secrets & Managed Identity Access ===" | tee "$OUT_DIR/SEC-3_keyvault_mi.txt"
az keyvault show --resource-group "$RG" --name "$KV"   --query "{Name:name,RbacEnabled:properties.enableRbacAuthorization,SoftDelete:properties.enableSoftDelete,PurgeProtection:properties.enablePurgeProtection}" -o table | tee -a "$OUT_DIR/SEC-3_keyvault_mi.txt"
az keyvault secret list --vault-name "$KV" --query "[].{Name:name,Enabled:attributes.enabled,Updated:attributes.updated}" -o table | tee -a "$OUT_DIR/SEC-3_keyvault_mi.txt"
az identity show --resource-group "$RG" --name "id-ridgeline-prod-wus3" --query "{Name:name,ClientId:clientId,PrincipalId:principalId}" -o table | tee -a "$OUT_DIR/SEC-3_keyvault_mi.txt"

echo "=== [SEC-5] RBAC Role Assignments (Least Privilege & Single Owner) ===" | tee "$OUT_DIR/SEC-5_rbac_roles.txt"
az role assignment list --all --include-inherited --output table | tee -a "$OUT_DIR/SEC-5_rbac_roles.txt"

echo "=== [SEC-7] Resource Locks on SQL Database & Key Vault ===" | tee "$OUT_DIR/SEC-7_locks.txt"
az lock list --resource-group "$RG" -o table | tee -a "$OUT_DIR/SEC-7_locks.txt"

echo "=== [SEC-8] Azure Policy Assignments ===" | tee "$OUT_DIR/SEC-8_policy.txt"
az policy assignment list --resource-group "$RG" -o table | tee -a "$OUT_DIR/SEC-8_policy.txt"

echo "Saved Phase 3 evidence outputs to $OUT_DIR"
