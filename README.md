# Ridgeline Outfitters — Cloud Infrastructure & Storefront (CPTR 445 Capstone)

Milestone 2 ("Build Complete") implementation for **Ridgeline Outfitters**, deploying a multi-tier cloud architecture on Microsoft Azure in `westus3` using Infrastructure-as-Code (Bicep and Azure CLI) within a $50/month budget.

## Architecture Overview
* **Primary Region:** West US 3 (`westus3`)
* **Networking:** Hub-and-spoke VNet (`10.0.0.0/16`) segmented into `/24` subnets with default-deny NSGs, Private DNS zones, and HTTPS/TLS 1.2+ enforcement
* **Compute:** Azure App Service (`app-ridgeline-prod-wus3` and staging app `app-ridgeline-stage-wus3` on `asp-ridgeline-prod-wus3`) serving the storefront web tier, paired with Azure Container Apps (`ca-api-ridgeline-prod-wus3`, `ca-proxy-ridgeline-prod-wus3`) for API/proxy workloads
* **Data & Secrets:** Azure SQL Database (`sqldb-ridgeline-prod-wus3`) with Private Endpoint and TDE, Azure Storage (`stridgelineprod64hvdp`) with LRS and HTTPS-only, and Azure Key Vault (`kv-ridgeline-prod-64hvdp`) with RBAC and User-Assigned Managed Identity (`id-ridgeline-prod-wus3`)
* **Governance & Security:** Azure Policy (`CostCenter` tag enforcement), resource locks (`CanNotDelete` on critical resources), least-privilege RBAC roles, and Microsoft Defender for Cloud (Foundational CSPM)

## Repository Structure
```text
├── .github/workflows/ci-cd.yml   # Automated validation, secret scan, unit tests & release workflow
├── docs/
│   ├── evidence/                 # Labeled verification scripts, CLI outputs & screenshots
│   ├── phase4-rollout-patching.md# Rollout strategy, patching schedule & rollback notes
│   └── sec-compliance-notes.md   # Security, RBAC, key management & compliance notes
├── infra/
│   ├── main.bicep                # Root IaC orchestration template
│   ├── main.bicepparam           # Environment parameters (CostCenter, naming, etc.)
│   └── modules/                  # Modular Bicep templates (network, compute, database, security, governance)
└── src/
    ├── web/                      # Node.js storefront web app & unit tests
    └── api/                      # Node.js backend API service, Dockerfile & unit tests
```

## Quick Start & Deployment
1. **Run Unit Tests Locally:**
   ```bash
   cd src/web && npm test
   cd ../api && npm test
   ```
2. **Deploy Infrastructure (Bicep):**
   ```bash
   export SQL_ADMIN_PASSWORD='<YourStrongPassword>'
   az deployment group create      --resource-group rg-ridgeline-prod-wus3      --template-file infra/main.bicep      --parameters infra/main.bicepparam
   ```
3. **Deploy Web Application & Verify Version:**
   ```bash
   curl -sS https://app-ridgeline-prod-wus3.azurewebsites.net/health
   ```

## AI Tools & Assistance Disclosure
This project was developed with assistance from **VS Code**, **GitHub Copilot**, and **Google AI** (Gemini) for Bicep authoring, troubleshooting CLI/policy/runtime errors, generating unit tests and documentation, and organizing verification evidence. All configurations, deployments, and security/cost decisions were reviewed and verified against project requirements.