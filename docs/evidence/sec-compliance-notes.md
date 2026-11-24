# Security, Identity & Compliance Notes (`SEC-2` – `SEC-9`)

## `SEC-2` Encryption at Rest & In Transit + Key Management
* **Data at Rest:**
  * **Azure SQL Database (`sqldb-ridgeline-prod-wus3`):** Encrypted via Transparent Data Encryption (TDE) using Microsoft service-managed keys (`ServiceManaged`), automatically encrypting database files and backups.
  * **Azure Storage (`stridgelineprod64hvdp`):** Encrypted at rest with 256-bit AES using Microsoft-managed keys (`Microsoft.Storage`).
  * **Compute Ephemeral/Managed Storage:** Encrypted at rest by the Azure platform.
* **Data in Transit:**
  * External and inter-tier web/API traffic uses HTTPS/TLS 1.2+ (`httpsOnly: true`, `minTlsVersion: 1.2`).
  * Database connections enforce `Encrypt=True;TrustServerCertificate=False` over TLS 1.2 across the Private Endpoint (`pe-sql-ridgeline-prod-wus3`).
* **Key Management Responsibility:** Platform-managed keys (PMK) managed by Microsoft Azure, eliminating manual key-rotation overhead while meeting PCI DSS encryption requirements within the $50 project budget.

## `SEC-3` Secrets Management & Repository Hygiene
* All sensitive credentials (such as `SqlConnectionString`) are stored in **Azure Key Vault (`kv-ridgeline-prod-64hvdp`)** with RBAC authorization enabled.
* Compute workloads authenticate via User-Assigned Managed Identity (`id-ridgeline-prod-wus3`) holding only the `Key Vault Secrets User` role.
* `.gitignore` blocks `.env`, certificates, and local secret files from ever being committed.

## `SEC-4` Multi-Factor Authentication (MFA)
* Every human account with access to the Azure subscription enforces MFA via Microsoft Entra ID. (Attach Entra ID Authentication Methods / Sign-in log screenshot showing MFA verification.)

## `SEC-5` Least-Privilege RBAC Model
| Role Category | Azure Built-In Role | Scope | Assigned Identity / Group | Justification |
| :--- | :--- | :--- | :--- | :--- |
| **Administrator (Single Owner)** | `Owner` | Subscription | Primary Student Account (`Linton_Feitosa`) | Full lifecycle & IAM control; restricted to a single identity. |
| **Operator** | `Website Contributor` / `Container Apps Contributor` | `rg-ridgeline-prod-wus3` | Operator Identity / Service Principal | Deploys and restarts web/API workloads without modifying IAM or locks. |
| **Read-Only Auditor** | `Reader` | `rg-ridgeline-prod-wus3` | Auditor / Reviewer Identity | Inspects configuration, logs, and compliance posture with zero write permissions. |

## `SEC-6` Account Provisioning & Deprovisioning Procedure
1. **Provisioning:** Verify business/academic justification, create or select the Entra ID identity, verify MFA registration (`SEC-4`), and assign the minimum required RBAC role at the narrowest scope (`rg-ridgeline-prod-wus3`).
2. **Deprovisioning:** Upon role change, project completion, or departure, immediately remove all RBAC role assignments (`az role assignment delete`), revoke active sessions/tokens, and verify zero remaining permissions via `az role assignment list`.
3. **Demonstration Evidence:** Record CLI/portal output showing assignment of the temporary/auditor test identity followed by `az role assignment delete` and post-removal verification.

## `SEC-7` & `SEC-8` Resource Locks & Automated Policy Enforcement
* **Locks (`SEC-7`):** `CanNotDelete` locks (`lock-kv-cannotdelete` and `lock-sqldb-cannotdelete`) prevent accidental deletion of Key Vault and the production database.
* **Azure Policy (`SEC-8`):** Built-in policy `Require a tag on resources` enforces the `CostCenter` tag (`ARC-9`) automatically on deployments in `rg-ridgeline-prod-wus3`.

## `SEC-9` Security Posture Management (Microsoft Defender for Cloud)
* Microsoft Defender for Cloud (Foundational CSPM) is enabled on the subscription.
* All **High-Severity** recommendations are either remediated directly or formally documented below with risk acceptance rationale if a remediation conflicts with the $50 student budget (e.g., paid Defender plans).
