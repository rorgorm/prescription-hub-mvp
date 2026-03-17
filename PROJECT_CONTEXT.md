# 🧠 Project: Veterinary Prescription Hub

## 🔹 Overview
Cloud-based prescription system designed to:
- Issue veterinary prescriptions
- Allow pharmacies to verify and claim prescriptions
- Prevent duplication and fraud
- Maintain a full audit trail of all actions
- Support future expansion to partial dispensing

Core flow:
Issue → Check → Claim → Audit → Flag → Void/Supersede

---

## 🗄️ Core Tables

- prescriptions
- prescription_claims
- claims_audit
- pharmacies
- pharmacy_api_keys
- practices
- prescribers
- prescription_flags

---

## 🧩 Key Table Notes

### prescriptions
- id (uuid, PK)
- rx_code (text, UNIQUE)
- status (ISSUED / CLAIMED / DISPENSED / EXPIRED)
- claimed_by (text)
- claimed_by_pharmacy_id (uuid FK → pharmacies.id)
- claimed_at (timestamp)
- issued_by (text)
- patient_name (text)
- drug_summary (text)
- issued_at (timestamp, NOT NULL)
- validity_mode (PRESET / CUSTOM)
- validity_days (int)
- expires_at (derived via trigger)
- supersedes_id (self FK)
- voided_at / void_reason
- attachment fields

### claims_audit
- append-only audit log
- records ALL events (checks, claims, failures, auth issues)
- includes structured result codes:
  - CHECK_OK
  - CLAIM_SUCCESS
  - CLAIM_EXPIRED
  - CLAIM_ALREADY_CLAIMED
  - CLAIM_RACE_LOST
  - etc.
- includes `billable` flag

### prescription_claims
- intended as claim attempt ledger
- currently underused vs claims_audit

### pharmacy_api_keys
- stores SHA256 hash of API keys
- links to pharmacy_id
- includes is_active + last_used_at

---

## ⚙️ Core Functions

- issue_prescription
- check_prescription_with_key
- claim_prescription
- claim_prescription_with_key
- create_pharmacy_api_key
- flag_prescription_issue_with_key
- resolve_prescription_flag
- verify_prescription
- void_and_supersede_prescription

---

## 🔑 Key Design Decisions

- rx_code is the public identifier
- rx_code is UNIQUE (DB enforced)
- expiry is derived from:
  issued_at + validity_days (trigger-based)
- prescription clinical data is immutable after issue
- operational fields (status, claim info) remain mutable
- claims are atomic (race-condition safe update)
- API keys are hashed using SHA256
- audit log is append-only (no mutation)
- pharmacy identity is UUID-based (not just text)
- supersession handled via self-referencing FK

---

## 🔐 Access Model

- Primarily function-based access (SECURITY DEFINER)
- Minimal use of RLS currently
- RLS enabled on prescription_flags only
- Pharmacy access via API key authentication

---

## 🚨 Known Issues / TODO

### Critical Fixes
- issue_prescription() is OUT OF SYNC with schema:
  - does not set:
    - validity_mode
    - validity_days
    - issued_at
  - incorrectly accepts expires_at directly

- claim_prescription_with_key():
  - does NOT set claimed_by_pharmacy_id (should be set)

- API key hashing is INCONSISTENT across functions:
  - must standardise on:
    extensions.digest(convert_to(api_key, 'utf8'), 'sha256')

- void_and_supersede_prescription():
  - uses incorrect audit result values:
    - 'SUCCESS' → should be 'CLAIM_SUCCESS'
    - 'VOIDED' → should be 'CLAIM_VOIDED'

### Structural Questions
- Is prescription_claims needed, or redundant vs claims_audit?
- Should RLS be introduced for public tables later?

---

## 🔄 Triggers (Important)

- prevent_prescription_mutation → blocks clinical changes
- prevent_created_at_update → enforces immutability
- prevent_prescriber_change → locks prescriber
- prevent_validity_change_after_claim → locks validity post-claim
- set_expires_at_from_validity → derives expiry automatically

---

## 🧠 Current Architecture Summary

System behaves as:

1. Prescription issued → stored immutably
2. Pharmacy authenticates via API key
3. Pharmacy checks claimability
4. System validates:
   - existence
   - expiry
   - claim status
5. Atomic claim update prevents race conditions
6. Audit log records ALL actions
7. Flags allow exception handling
8. Prescriptions can be voided and superseded

---

## 📌 Current Focus

- Fix schema/function mismatches
- Align claim logic with relational pharmacy model
- Standardise API key handling
- Prepare for next phase:
  → partial dispensing
  → billing logic
  → stronger access control (RLS vs function-only)

---

## 🚀 Next Phase (Planned)

- Partial dispensing ledger
- Multi-claim tracking per prescription
- Pharmacy billing model
- Improved audit analytics
- External API / frontend integration

---
