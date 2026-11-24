# Milestone 2 Evidence Checklist (Build Complete)

Every requirement below must have labeled evidence (screenshots, CLI outputs, Git commits, or pipeline runs) in `docs/evidence/` before submitting Milestone 2.

## Networking & Security (`NET-2`, `NET-3`, `NET-5`, `NET-6`, `NET-7`)
- [ ] **NET-2:** Default-deny NSGs on `snet-proxy`, `snet-web`, `snet-app`, and `snet-data` (`docs/evidence/phase2-outputs/NET-2_nsgs.txt` + portal NSG/subnet screenshot).
- [ ] **NET-3:** No management ports (`22`, `3389`) open to the internet (`docs/evidence/phase2-outputs/NET-3_mgmt_ports.txt`).
- [ ] **NET-5:** Front-end hostname configured + `privatelink.database.windows.net` linked to `vnet-ridgeline-prod-wus3` (`docs/evidence/phase2-outputs/NET-5_private_dns.txt`).
- [ ] **NET-6:** HTTPS-only enforced, valid TLS certificate inspected, exact expiration date recorded, and expiry monitoring configured (`docs/evidence/phase2-outputs/NET-6_tls_cert.txt` + alert/monitor screenshot).
- [ ] **NET-7:** Caddy reverse proxy (`ca-proxy-ridgeline-prod-wus3`) active in front of the web tier (`docs/evidence/phase2-outputs/NET-7_edge_check.txt` + response headers/screenshot).

## Identity, Secrets & Encryption (`SEC-2` to `SEC-9`)
- [ ] **SEC-2:** Encryption at rest (TDE, storage, disks) and in transit verified; key management documented.
- [ ] **SEC-3:** Secrets stored in `kv-ridgeline-prod-64hvdp` and read via Managed Identity (`id-ridgeline-prod-wus3`); zero secrets in repo or plaintext settings.
- [ ] **SEC-4:** MFA enabled for every human account with subscription access (Entra ID MFA proof).
- [ ] **SEC-5:** At least 3 least-privilege RBAC roles assigned to distinct identities/groups; only 1 Owner.
- [ ] **SEC-6:** Provisioning/deprovisioning documented; access removal demonstrated for one account.
- [ ] **SEC-7:** `CanNotDelete` locks on SQL database and Key Vault (`lock-sqldb-cannotdelete`, `lock-kv-cannotdelete`).
- [ ] **SEC-8:** Azure Policy assigned and evaluated (e.g., required tags or allowed regions).
- [ ] **SEC-9:** Defender for Cloud posture enabled; high-severity recommendations fixed or formally accepted.

## Automation, Deployment & Patching (`AUT-1` to `AUT-7` + `README`)
- [ ] **AUT-1:** Modular IaC in Git (`infra/main.bicep` + modules) deploying cleanly into an empty resource group.
- [ ] **AUT-2:** CI/CD pipeline builds, tests, and deploys on commits to `main`.
- [ ] **AUT-3:** Non-production environment/slot used with promotion to production.
- [ ] **AUT-4:** Rollout strategy chosen, justified, and demonstrated once.
- [ ] **AUT-5:** Patching schedule in a maintenance window + provider vs. student responsibilities documented.
- [ ] **AUT-6:** Snapshot/image taken before a significant change + rollback demonstrated.
- [ ] **AUT-7:** Release tagged in Git and visible in running app or logs.
- [ ] **README:** Explains app, architecture, repo structure, deployment, and AI tools used.
