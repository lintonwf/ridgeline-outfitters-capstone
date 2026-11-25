# Automation, Rollout, Patching & Rollback Documentation (`AUT-3` – `AUT-7`)

## `AUT-3` & `AUT-4` Non-Production Promotion & Blue-Green Rollout Strategy
* **Chosen Strategy:** **Blue-Green Deployment** (using a non-production staging environment/slot promoted to production).
* **Justification:** Ridgeline Outfitters requires zero-downtime customer releases and instant rollback capability if a defect slips past automated unit tests. Blue-Green warms up the new release in non-production, verifies `/health` and `/version`, and switches traffic atomically without taking the storefront offline.
* **Rejected Alternatives:**
  * *In-place recreate:* Rejected because restarting all instances simultaneously causes customer-facing downtime during updates.
  * *Complex multi-cluster canary mesh:* Rejected due to added operational complexity and cost beyond the $50 project budget.

## `AUT-5` Patching Schedule & Shared Responsibility Matrix
* **Maintenance Window:** **Sundays, 02:00 – 04:00 UTC (Saturday 21:00 – 23:00 EST)** — lowest e-commerce traffic window.
* **Shared Responsibility Breakdown:**

| Component | Cloud Provider (Microsoft Azure) Responsibility | Student / Operator Responsibility |
| :--- | :--- | :--- |
| **Azure App Service (`app-ridgeline-prod-wus3`)** | Underlying host OS, hypervisor, and managed `NODE|20-lts` runtime patching. | Application code dependencies, runtime version selection (`NODE|20-lts`), and app configuration. |
| **Azure Container Apps (`ca-proxy`, `ca-api`)** | Underlying Kubernetes/Envoy control plane, host OS, and serverless fabric patching. | Rebuilding and redeploying container base images (`node:20-alpine`, `caddy:2.8-alpine`) on schedule. |
| **Azure SQL Database (`sqldb-ridgeline-prod-wus3`)** | SQL engine patches, OS updates, TDE platform keys, and automated backup infrastructure. | Database schema/index maintenance, firewall/Private Endpoint rules, and credential rotation in Key Vault. |
| **Azure Storage & VNet/NSGs** | Storage fabric, physical hardware, and software-defined networking infrastructure. | NSG rule hygiene, TLS certificate monitoring, and access policy reviews. |

## `AUT-6` Pre-Change Snapshot & Rollback Procedure
1. **Pre-Change Snapshot / Backup:**
   * Record the active release tag (`v0.2.0`), export current App Service settings/package backup (and verify Azure SQL point-in-time restore point / Storage blob snapshot) prior to applying a significant change (`v0.2.1-broken` or configuration update).
2. **Rollback Execution:**
   * Revert the deployment to the known-good release package/tag (`v0.2.0`), verify `/health` and `/version` return `v0.2.0`, and archive before/after screenshots and CLI logs as `AUT-6` evidence.

## `AUT-7` Release Versioning & Tagging Standard
* Releases follow Semantic Versioning (`vMAJOR.MINOR.PATCH`, e.g., `v0.2.0`) tagged in Git (`git tag -a v0.2.0 -m "Release v0.2.0"`).
* The active version is injected via `APP_VERSION` and displayed in:
  1. The storefront web UI header and footer (`Release v0.2.0`)
  2. The `GET /health` and `GET /version` JSON responses and `X-App-Version` HTTP response header
  3. Structured JSON application logs on startup and health checks

## Environment Promotion & CI/CD Execution Model (AUT-2, AUT-3, AUT-4, AUT-7)

* **Non-Production Staging Architecture (`AUT-3`):** Because Azure App Service deployment slots require a Standard (`S1`) or higher plan that would exceed the $50/month project budget, non-production validation is implemented via a dedicated staging web app (`app-ridgeline-stage-wus3`) hosted on the existing Basic `B1` App Service Plan (`asp-ridgeline-prod-wus3`) at **$0** additional compute cost.
* **Automated Build, Staging Deploy & Production Promotion (`AUT-2`, `AUT-4`):**
  1. Every push or pull request to `main` (and any `v*` release tag) triggers `.github/workflows/ci-cd.yml`, executing secret hygiene scans, `az bicep build` validation, and Node.js 26 unit tests for both `src/web` and `src/api`.
  2. Upon passing tests, the workflow packages the web tier artifact (`ridgeline-web.zip`) and deploys it first to `app-ridgeline-stage-wus3` using `AZURE_STAGE_PUBLISH_PROFILE`.
  3. After staging deployment succeeds, the workflow promotes the identical validated build artifact to `app-ridgeline-prod-wus3` using `AZURE_PROD_PUBLISH_PROFILE`, realizing Blue-Green-style immutable artifact promotion without rebuilding.
* **Version Traceability (`AUT-7`):** Releases are tagged in Git (`v*`) and surfaced in the running application (`/health`, `/version`, `X-App-Version` response headers, structured container logs, and storefront UI) so deployed versions can be verified and rolled back (`AUT-6`) cleanly.
