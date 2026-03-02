# Capture Tour: Post-Pink Hill Security & Compliance Plan

This document outlines the critical remaining tasks to be addressed after the initial capture tour phase in Pink Hill, NC.

## 🚨 Immediate Priorities (Post-Tour)

### 1. Security Hardening Cleanup
- [ ] **Remove Permissive Exceptions**: Audit `firestore.rules` and `storage.rules` for any remaining `if true` or debug-only bypasses used during the tour.
- [ ] **App Check Enforcement**: Transition from "Monitor" to "Enforce" mode for Firebase App Check across all production services.
- [ ] **Production Sign-off**: Finalize the Engineering + Product sign-off in the `LEGAL_PRODUCTION_CANARY_ROLLOUT_RUNBOOK.md`.

### 2. Operational Compliance
- [ ] **Payment/Refund QA**: Execute the manual QA checklist in `docs/LEGAL_PAYMENT_REFUND_QA_CHECKLIST.md` to ensure billing disclosures match tour experiences.
- [ ] **Data Inventory Maturity**: Expand the `LEGAL_DATA_INVENTORY_MATRIX.md` to include field-level mapping for all new data captured during the tour.
- [ ] **Legal Risk Register**: Initialize the formal risk register to track any edge cases discovered in Pink Hill (e.g., specific municipal property art rights).

## 🛠️ System Improvements

### 1. Consent & Transparency
- [ ] **Plain-Language Summaries**: Implement "What this means" tooltips for the capture terms based on user feedback from the tour.
- [ ] **Version Bump Workflow**: Finalize the system to force re-consent if capture terms are updated for the next city.

### 2. Minor/Student Readiness (P2)
- [ ] Define the school/student mode legal model.
- [ ] Implement age-gate handling for the capture flow if touring near school zones.

## 📋 Audit & Evidence
- [ ] **Tour Audit**: Review the `dataRequestAudit` logs generated during the tour period.
- [ ] **CI Regression**: Ensure `scripts/legal_staging_regression.sh` still passes after any tour-related hotfixes.

---
*Plan created: March 1, 2026*
*Target Review: Post-Pink Hill Return*
