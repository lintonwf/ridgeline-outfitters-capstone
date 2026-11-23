# Ridgeline Outfitters — Cloud Infrastructure & Application (CPTR 445 Capstone)

## Project Overview
Production-ready, multi-tier e-commerce web application built on Microsoft Azure for **Ridgeline Outfitters**, designed to stay within a **$50/month** budget while meeting availability, network segmentation, security, and disaster recovery targets.

## Architecture Summary
* **Primary / Secondary Regions (`ARC-6`):** `westus3` (Primary) / `westus` (Paired Secondary)
* **Edge / Filtering Layer (`ARC-1`, `ARC-5`, `NET-7`):** Caddy Reverse Proxy on Azure Container Apps (`snet-proxy`)
* **Web Tier (`ARC-2`):** Azure App Service (`B1`, 2 instances) with regional VNet integration (`snet-web`)
* **Application / API Tier (`ARC-5`):** Serverless API on Azure Container Apps (`snet-app`)
* **Data Tier (`ARC-3`, `NET-5`):** Azure SQL Database (`Basic`, 5 DTUs) with public access disabled, accessed via Private Endpoint (`snet-data`) and Private DNS (`privatelink.database.windows.net`)
* **Storage Tier (`ARC-4`):** Azure Storage Account (`Standard_LRS`, `Hot` tier) for static web assets
* **Identity & Secrets (`SEC-3`, `SEC-7`):** Azure Key Vault with RBAC authorization, `CanNotDelete` resource locks, and User-Assigned Managed Identity

## Repository Organization
```text
.
├── infra/
│   ├── main.bicep                  # Root orchestration template (AUT-1)
│   ├── main.bicepparam             # Production parameter file
│   └── modules/
│       ├── network.bicep           # VNet, 4 subnets, default-deny NSGs (NET-1, NET-2, NET-4)
│       ├── security.bicep          # Managed Identity, Key Vault, Locks (SEC-2, SEC-3, SEC-7)
│       ├── storage.bicep           # Storage Account Hot/LRS (ARC-4, SEC-2)
│       ├── database.bicep          # Azure SQL, Private Endpoint, Private DNS, Lock (ARC-3, NET-5, SEC-7)
│       └── compute.bicep           # App Service (2x B1) & Container Apps Proxy/API (ARC-2, ARC-5, NET-6, NET-7)
├── src/
│   ├── web/                        # Storefront web frontend (to be added in Phase 4)
│   ├── api/                        # Backend REST API (to be added in Phase 4)
│   └── proxy/                      # Caddyfile & container config (to be added in Phase 2/4)
├── .github/
│   └── workflows/                  # CI/CD pipelines (to be added in Phase 4)
└── docs/
    └── evidence/                   # Requirement-labeled verification artifacts
```

## Naming & Tagging Standard (`ARC-9`)
* **Naming Convention:** `<resource-type>-<app-name>-<environment>-<region>` (or compact alphanumeric for Storage/Key Vault)
* **Required Tags:** `Owner`, `Environment`, `CostCenter`, `Project`

## Deployment Instructions (`AUT-1`)
```bash
# 1. Log in and select your subscription
az login
az account set --subscription "<YOUR_SUBSCRIPTION_ID>"

# 2. Create the target resource group
az group create --name rg-ridgeline-prod-wus3 --location westus3 \
  --tags Owner="<Your Name>" Environment="Production" CostCenter="RO-IT-001" Project="CPTR445-Capstone"

# 3. Validate (what-if) and deploy into the empty resource group
az deployment group what-if \
  --resource-group rg-ridgeline-prod-wus3 \
  --template-file infra/main.bicep \
  --parameters infra/main.bicepparam

az deployment group create \
  --resource-group rg-ridgeline-prod-wus3 \
  --template-file infra/main.bicep \
  --parameters infra/main.bicepparam
```

## AI Tools Disclosure
In accordance with course guidelines:
* **Google AI Pro & GitHub Copilot (Student):** Used to scaffold modular Bicep templates, GitHub Actions workflows, application boilerplate, and documentation structure. All architecture decisions, security rules, credentials, and live Azure verification steps were authored and validated by the student.
