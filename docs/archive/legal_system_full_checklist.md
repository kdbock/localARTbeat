# Legal System Full Checklist

This checklist is for building a user-safe legal system and reducing legal exposure. It is not legal advice. Use this with qualified counsel in your operating jurisdictions.

## 0A) Owner Decisions Locked (February 25, 2026)

- [x] Legal owner: Kristy Kelly.
- [x] Legal entity: Local ARTbeat, LLC.
- [x] Support/legal email: support@localartbeat.com.
- [x] Mailing address: PO BOX 232, Kinston, NC 28502.
- [x] Governing law baseline: North Carolina, United States.
- [x] Arbitration and class-action waiver approved for ToS (where legally permitted).
- [x] Financial/legal retention period approved: 7 years.
- [x] Account deletion timeline approved:
- [x] Primary user-facing data deletion within 30 days.
- [x] Backup purge within 60 days.
- [x] Refund policy approved: no refunds globally, except where required by law or platform policy.
- [x] Data-rights SLA approved:
- [x] Acknowledge requests within 72 hours.
- [x] Fulfillment target within 30 days.
- [x] Age policy baseline approved:
- [x] 13+ globally.
- [x] App not directed to children under 13.
- [x] Under-18 users allowed with restrictions on messaging, location sharing,
  public profile discovery, and event participation.
- [x] Artistic nudity policy approved: artistic nudity allowed in artistic
  context; pornography prohibited; pedophile-related content prohibited;
  ARTbeat recommended for ages 18+.
- [x] Copyright / DMCA intake contact approved: info@localartbeat.com.
- [x] Law enforcement intake contact approved: kristy@kristykelly.com.
- [x] Reported private-message review approved for moderation investigations.
- [x] Abuse-response enforcement baseline approved: restrict abused sections,
  delete violating accounts, block or remove abusive access as needed.

## 0B) Implementation Status Snapshot (Current)

- [x] Durable, versioned registration consent recording added in code.
- [x] Capture terms one-time acceptance enforced before capture submission.
- [x] Profile legal entry fixed to point to canonical legal docs.
- [x] In-app Legal Center added (version + acceptance visibility).
- [x] Terms/Privacy legal text updated with owner-approved baseline language.
- [x] Contact channel normalized in app legal/help surfaces.
- [x] Deletion page updated with 30/60 timeline and 7-year legal retention carveout.
- [x] Incident response plan document created.
- [x] Staged security rules rollout plan document created.
- [x] Data-rights request pipeline functional end-to-end for non-admin users.
- [x] Firestore/Storage rules hardened (least privilege) and deployed to staging with live validation.
- [x] Account deletion implementation expanded with admin-run deletion pipeline and audit summary.
- [x] Staging lifecycle test completed (`pending` -> `in_review` -> `fulfilled`) with deletion/audit verification.
- [x] Privilege-escalation gaps discovered during staging test were fixed and re-deployed.
- [x] Privacy policy security wording updated to verifiable claims.
- [x] Staging legal/rules regression script added (`scripts/legal_staging_regression.sh`).
- [x] Final admin-token evidence run completed successfully (February 26, 2026):
- [x] Regression tests passed (`00:03 +62: All tests passed!`).
- [x] Rule checks passed (`self_promote_admin_http=403`, owner uploads `200`, cross-user denies `403`).
- [x] Admin lifecycle completion succeeded with callable `result.ok: true`.
- [x] Deletion summary confirmed `authDeleted: true` with retained financial/legal collections explicitly preserved.
- [x] Canary deployment executed successfully to `wordnerd-artbeat` via:
  `PROJECT_ID=wordnerd-artbeat ./scripts/legal_canary_deploy.sh`.
- [x] Post-deploy regression re-run succeeded with live admin lifecycle validation.
- [x] Exact post-deploy evidence (2026-02-26): `data_request_created=jzyvWYISmQPIRx9DukPQ`, callable returned `result.ok=true`, deletion summary confirmed `authDeleted=true`.
- [x] CI legal regression workflow validated in GitHub Actions (2026-02-26):
  run `22424833231` completed `success` with full regression job pass.
- [x] Shared chat media lifecycle hardening deployed and validated (2026-02-26):
  participant message create allow/deny checks passing with media ownership metadata.

## 0) Legal Program Foundations

- [x] Assign legal owner (internal) and external counsel contact.
- [x] Define operating entities, trademarks, and app legal name consistency.
- [x] Define target jurisdictions (US states, EU/EEA/UK, others).
- [ ] Create legal risk register with owners, due dates, and severity.
- [x] Define incident escalation path (privacy, security, content, payments).
- [x] Define record retention policy (what, why, how long, deletion method).

## 1) Canonical Legal Documents

- [x] Terms of Service owner-approved and updated in product.
- [ ] Terms of Service finalized by counsel.
- [x] Privacy Policy owner-approved and updated in product.
- [ ] Privacy Policy finalized by counsel.
- [x] Community Guidelines / Acceptable Use Policy finalized for current
  owner-approved operating baseline.
- [x] Copyright/IP Policy (DMCA process, repeat infringer policy) drafted and
  published for current owner-approved operating baseline.
- [ ] Refund/Cancellation Policy (subscriptions, events, ads, commissions).
- [x] Safety Disclaimer for location-based features.
- [x] Children/age policy baseline documented for the current operating model.
- [ ] Data Processing Addendum (if B2B/galleries/business users).
- [ ] Cookie/Tracking notice (if web tracking applies).
- [x] Arbitration/class-action/jurisdiction clauses reviewed per jurisdiction.
- [x] Ensure all docs have:
- [x] Effective date.
- [x] Last updated date.
- [x] Version ID (e.g., `tos_v3`, `privacy_v4`).
- [x] Clear contact channel.

## 2) Policy-to-Product Mapping

- [ ] Build a matrix: each legal promise mapped to exact product behavior.
- [ ] Remove any policy promise not implemented in code/operations.
- [ ] Add missing product controls for each policy commitment.
- [x] Keep “source of truth” for legal text in one place (no divergent copies).

## 3) Consent Architecture (One-Time + Versioned)

- [x] Require ToS + Privacy acceptance at registration.
- [ ] Gate high-risk features with contextual one-time consent:
- [x] Capture/content upload (IP + rights + legality).
- [x] Location-based features (GPS + real-world safety).
- [x] Payments/subscriptions/refunds.
- [x] Store consent records server-side (not only local storage):
- [x] `userId`
- [x] `consentType`
- [x] `policyVersion`
- [x] `acceptedAt` (server timestamp)
- [x] `surface` (screen/flow)
- [x] `locale`
- [ ] Optional lawful metadata (country/state, app version).
- [ ] Re-prompt only when policy version changes materially.
- [x] Show users a Consent History screen.
- [ ] Support consent withdrawal where legally required (non-essential processing).

## 4) UX Clarity Requirements

- [x] Add plain-language “What this means” summaries before full legal text.
- [ ] Link full legal docs from:
- [x] Registration
- [x] Settings > Legal/Privacy
- [x] Purchase flow
- [x] Upload flow
- [x] Use consistent legal copy across app/web/email/help.
- [x] Ensure labels match destination (no mislabeled legal screens).
- [x] Provide concise pre-action warnings for risky actions where already
  implemented; registration warning added for mature-content recommendation and
  under-18 restrictions.

## 5) Data Rights (GDPR/CCPA/State Privacy)

- [ ] Implement in-app requests for:
- [x] Access/export
- [x] Deletion
- [ ] Correction (if applicable)
- [ ] Processing objection/restriction (if applicable)
- [x] Request submission works for authenticated users in production rules.
- [x] Request status tracking (`pending`, `in_review`, `fulfilled`, `denied`).
- [x] SLA clocks and reminders (e.g., 30/45-day limits depending on law).
- [ ] Identity verification workflow for high-risk requests.
- [ ] Appeal workflow and denial rationale logging.
- [ ] “Do Not Sell/Share” handling where applicable.
- [ ] Data portability format and delivery process documented.
- [x] Data rights audit log immutable to normal users.

## 6) Account Deletion and Data Deletion

- [ ] Deletion policy states exactly what is deleted, pseudonymized, retained.
- [ ] App deletion flow matches published deletion page exactly.
- [ ] Deletion pipeline covers all user data domains:
- [x] Auth account
- [x] User profile/docs
- [x] User-generated content
- [x] Messages and social graph handling
- [x] Purchases/subscriptions linkage (retained collections explicitly carved out)
- [x] Storage objects across all storage paths
- [x] Shared chat media cleanup/redaction for sender-owned media references in deletion pipeline.
- [ ] Analytics/event stores (as applicable)
- [x] Backups (document delay and final purge windows)
- [x] Legal/financial retention carve-outs are explicit and enforced.
- [x] Confirm deletion completion with user-visible status.
- [x] Maintain deletion evidence trail (who, what, when).

## 7) Security Controls (Legal + User Safety)

- [x] Firestore rules reviewed for least privilege.
- [x] Storage rules reviewed for least privilege.
- [x] Remove temporary/permissive dev rules before release.
- [ ] Enforce App Check and authentication checks where needed.
- [ ] Restrict sensitive collections to owner/admin as appropriate.
- [ ] Penetration test and remediation tracking.
- [ ] Encryption in transit and at rest verified.
- [ ] Secret management and key rotation policy.
- [ ] Dependency vulnerability scanning in CI.
- [ ] Security incident response runbook tested.
- [ ] Breach notification playbook per jurisdiction.

## 8) Payments, Billing, Refunds, and Financial Risk

- [ ] Terms and UI clearly explain pricing, renewals, and cancellation.
- [x] Refund rules are deterministic and visible pre-purchase.
- [ ] Chargeback handling workflow documented.
- [ ] Webhook handling is idempotent and monitored.
- [ ] No duplicate/overwritten critical webhook handlers.
- [ ] Payment authorization checks and ownership verification in backend.
- [ ] Financial records retention policy implemented.
- [ ] Tax/VAT/GST responsibility language reviewed by counsel/accounting.
- [ ] Ad/sponsorship purchase terms and performance disclaimers defined.

## 9) Content, IP, and Moderation

- [x] Community rules published for the current operating baseline.
- [ ] Upload attestations: user confirms rights to post content.
- [x] Repeat infringer policy implemented at the policy level.
- [x] Notice-and-takedown process (DMCA-like) operational.
- [x] Counter-notice process defined where applicable.
- [ ] Moderation action appeal process implemented.
- [ ] Moderation logs stored and reviewable by admins.
- [x] Illegal/harmful content escalation workflow documented.
- [x] High-risk category handling (nudity, harassment, threats, doxxing).

## 10) Location and Real-World Safety

- [x] Explicit safety warning before first location feature use.
- [x] Explicit statement not to trespass or enter restricted areas.
- [ ] Emergency/non-emergency guidance in app help.
- [ ] Geolocation permissions are minimum necessary.
- [ ] Background location usage minimized and justified.
- [ ] Safety and liability language aligned across app and terms.

## 11) Minors and Age Gating

- [x] Age threshold and jurisdiction-specific digital consent handling.
- [ ] Age gate and parent/guardian consent flow where required.
- [x] Restricted features for minors defined in policy and signup language.
- [ ] Child account reporting and parental deletion request process.
- [ ] COPPA/UK/EU child data obligations reviewed by counsel.

## 12) Privacy by Design in Engineering

- [x] Initial data inventory matrix created (`docs/LEGAL_DATA_INVENTORY_MATRIX.md`).
- [x] Rules-derived dataset inventory expanded to full collection/path coverage baseline, including shared chat media lifecycle controls.
- [ ] Data inventory by field and purpose completed (field-level coverage still pending).
- [ ] Data minimization review: remove non-essential fields.
- [ ] Purpose limitation: each field mapped to lawful purpose.
- [ ] Default privacy-friendly settings enabled.
- [ ] Optional analytics/personalization controlled by real toggles.
- [ ] Consent toggles actually control tracking behavior.
- [ ] PII redaction in logs and error telemetry.
- [ ] Data classification labels in code/schema.

## 13) Auditability and Evidence

- [ ] Consent ledger queryable by user + policy version.
- [ ] Policy version release log maintained.
- [ ] Data request log with timestamps and outcomes.
- [ ] Deletion/export job execution logs retained.
- [ ] Moderation and takedown evidence retention policy.
- [ ] Security audit logs immutable and access-controlled.
- [ ] Quarterly legal-compliance review checklist executed.

## 14) Operational Governance

- [ ] RACI chart for Legal, Product, Engineering, Support, Trust & Safety.
- [ ] Support team scripts for legal/privacy/payment requests.
- [ ] Standard response templates reviewed by counsel.
- [ ] SLA dashboard for legal/privacy support tickets.
- [ ] On-call playbook for urgent legal requests.

## 15) Internationalization and Accessibility

- [ ] Legal docs available in supported app languages.
- [ ] If translations differ, define governing language clause.
- [ ] Locale-aware legal flows (region-specific notices/rights).
- [ ] Accessibility compliance for legal screens (screen reader, contrast, sizing).

## 16) Release Gates (Must Pass Before Production)

- [ ] Security rules reviewed and signed off.
- [ ] Consent recording and version checks tested end-to-end.
- [x] Data-rights requests tested with non-admin account (staging API-level).
- [x] Account deletion tested across declared core data stores (staging API-level).
- [x] Admin-authenticated callable deletion workflow tested with valid Firebase ID token.
- [x] Canary deployment of rules + deletion callable executed successfully.
- [x] Shared chat media authorization regression checks executed (`participant create=200`, `non-participant create=403`).
- [ ] Payment/refund flows tested, including webhook replay/idempotency.
- [x] Support contact channels verified and consistent everywhere.
- [x] Legal links reachable from all required screens.
- [x] Policy claims and app behavior verified line-by-line in manual in-app UI session (manual QA + screenshot evidence).
- [x] Counsel sign-off recorded.

## 20) Next Steps (Immediate)

- [x] Run manual in-app staging QA for admin data-rights queue and deletion UX (completed with screenshot evidence).
- [x] Complete policy text hardening for unverifiable technical claims (for example, 2FA/encryption wording).
- [x] Produce initial data inventory matrix (collection/path -> purpose -> retention -> deletion behavior).
- [x] Add CI regression workflow for rules + deletion callable scenarios (`.github/workflows/legal_staging_regression.yml`).
- [x] Add helper script to set CI secrets and dispatch workflow (`scripts/legal_ci_setup_and_run.sh`).
- [x] Create production canary deploy runbook and deploy helper script.
- [x] Complete matrix coverage for all app datasets and shared chat media lifecycle handling baseline.
- [x] Configure CI secrets and validate workflow execution in GitHub Actions (`legal_staging_regression.yml` run `22424833231` passed).
- [ ] Complete production canary sign-off log after manual QA + remaining non-engineering sign-offs.

## 17) Ongoing Compliance Cadence

- [ ] Monthly review: support/legal tickets and emerging risk patterns.
- [ ] Quarterly review: policy-to-product drift check.
- [ ] Semiannual review: vendor/subprocessor and transfer mechanisms.
- [ ] Annual review: full legal/security/privacy audit.
- [ ] Triggered review on:
- [ ] New feature class (payments, location, AI, minors).
- [ ] New jurisdiction launch.
- [ ] Material policy/legal changes.

## 18) Immediate Priority Remediation Template

- [x] P0: Fix data-rights request flows and production access rules.
- [x] P0: Remove permissive storage/firestore rules.
- [x] P0: Ensure account deletion truly covers all declared data.
- [x] P1: Implement durable versioned consent ledger.
- [x] P1: Unify legal contact channels and legal copy sources.
- [x] P1: Correct legal screen routing and labeling.
- [x] P1: Replace placeholder legal text and enforce feature-specific terms.
- [x] P2: Add user-facing consent history and request-status tracking.
- [ ] P2: Complete moderation/IP workflow hardening and audit logs.

## 19) “Don’t Get Sued” Practical Principles

- [ ] Never claim compliance you cannot prove.
- [ ] Never promise deletion scope/timing you cannot execute.
- [ ] Never collect data you cannot justify and protect.
- [ ] Never rely on client-only consent evidence.
- [ ] Never leave temporary permissive security rules in production.
- [ ] Never ship ambiguous payment/refund language.
- [ ] Always document decisions, approvals, and evidence.
