# 🧠 Project: Veterinary Prescription Hub (Updated State)

## 🔹 Overview
Cloud-based veterinary prescription system designed to:
- Issue prescriptions
- Allow pharmacies to verify and claim prescriptions
- Prevent duplication and fraud
- Maintain a full audit trail
- Support partial dispensing (next phase)

Core flow:
Issue → Check → Claim → Audit → Flag → Void/Supersede → (Next: Partial Dispense)

---

## 🗄️ Core Tables

- prescriptions
- prescription_claims (currently underused)
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
- claimed_by_pharmacy_id (uuid FK → pharmacies.id) ✅ now correctly populated
- claimed_at (timestamp)
- issued_by (text)
- patient_name (text)
- drug_summary (text)
- issued_at (timestamp, NOT NULL) ✅ now set correctly
- validity_mode (PRESET / CUSTOM) ✅ now used
- validity_days (int) ✅ now used
- expires_at (derived via trigger)
- supersedes_id (self FK)
- voided_at / void_reason
- attachment fields

---

### claims_audit
- append-only audit log
- records ALL events:
  - CHECK_OK
  - CLAIM_SUCCESS
  - CLAIM_EXPIRED
  - CLAIM_ALREADY_CLAIMED
  - CLAIM_RACE_LOST
  - CLAIM_VOIDED ✅ now standardised
- includes:
  - prescription_id
  - pharmacy_id
  - rx_code
  - result
  - errcode
  - message
  - billable
- ⚠️ created_at column recommended (not yet confirmed present)

---

### pharmacy_api_keys
- stores SHA256 hash of API keys
- links to pharmacy_id
- includes:
  - is_active
  - last_used_at

---

## ⚙️ Core Functions (Now Aligned)

### issue_prescription ✅ FIXED
- sets:
  - issued_at = now()
  - validity_mode
  - validity_days
- NO longer accepts expires_at directly
- expiry derived via trigger

---

### claim_prescription_with_key ✅ FIXED
- uses standardised API key hashing
- resolves pharmacy via API key
- sets:
  - claimed_by
  - claimed_by_pharmacy_id ✅ FIXED
  - claimed_at
- atomic update prevents race conditions
- writes CLAIM_SUCCESS audit row

---

### check_prescription_with_key ✅ CLEANED
- consistent hashing
- returns claimability state
- logs CHECK_* audit events

---

### create_pharmacy_api_key ✅ FIXED
- uses standardised hashing:
  extensions.digest(convert_to(v_key, 'utf8'), 'sha256')
- returns raw API key once
- stores only hash

---

### flag_prescription_issue_with_key ✅ FIXED
- hashing now consistent
- API key validation aligned with other functions
- logs flags correctly

---

### void_and_supersede_prescription ✅ FIXED
- audit codes corrected:
  - SUCCESS → CLAIM_SUCCESS
  - VOIDED → CLAIM_VOIDED
- old prescription:
  - voided_at set
  - void_reason set
- new prescription:
  - supersedes_id links to old
- prior CLAIM_SUCCESS rows set to billable = false

---

## 🔐 Access Model

- Function-based access (SECURITY DEFINER)
- Minimal RLS (only prescription_flags currently)
- Pharmacy authentication via API key

---

## 🔑 Key Design Decisions

- rx_code is the public identifier
- prescription clinical data is immutable
- operational fields remain mutable
- expiry derived from issued_at + validity_days
- API keys stored hashed only
- claims are atomic and race-condition safe
- audit log is append-only
- pharmacy identity is UUID-based (not text)
- supersession handled via self-referencing FK

---

## 🔄 Triggers

- prevent_prescription_mutation
- prevent_created_at_update
- prevent_prescriber_change
- prevent_validity_change_after_claim
- set_expires_at_from_validity

---

## 🚨 Known Issues / TODO (Updated)

### Minor
- claims_audit likely missing created_at → should be added

### Structural
- prescription_claims table likely redundant vs claims_audit (to review)

---

## 🧠 Current Architecture Summary

1. Prescription issued → immutable record created
2. Pharmacy authenticates via API key
3. Prescription checked for validity
4. Atomic claim prevents duplication
5. Audit log records ALL events
6. Flags allow exception handling
7. Prescriptions can be voided and superseded cleanly

---

## 🚀 Next Phase: Partial Dispensing (Agreed Direction)

### Key Requirement
Support:
- multiple medicines per prescription
- partial redemption over time
- multiple pharmacies dispensing different items

---

## 🧩 Proposed New Tables

### prescription_items (NEW)
- id
- prescription_id
- line_number
- drug_description
- quantity_prescribed
- quantity_dispensed
- quantity_remaining
- status (ISSUED / PARTIAL / DISPENSED / EXPIRED)

---

### prescription_item_dispenses (NEW)
- id
- prescription_item_id
- prescription_id
- pharmacy_id
- quantity_dispensed
- dispensed_at
- billable
- created_at

---

## 🧠 Key Design Decision (CRITICAL)

👉 Ledger must operate at item level, not prescription level

This supports:
- multi-drug prescriptions
- independent partial dispensing
- accurate audit trails
- regulatory defensibility

---

## 🔄 Future Flow (Planned)

Issue → Items created →  
Pharmacy selects item →  
Dispense quantity →  
Ledger updated →  
Remaining balance tracked  

---

## 📌 Next Build Steps

1. Create prescription_items table
2. Create prescription_item_dispenses table
3. Update issue flow to create items
4. Update claim logic → item + quantity based
5. Derive prescription status from item states
6. Introduce billing per dispense event

---

## 🧠 Strategic Position

System now has:
- robust auditability
- fraud prevention
- relational pharmacy tracking
- supersession logic
- strong foundation for controlled-drug workflows

Next phase (partial dispensing) will:
- significantly increase real-world usability
- differentiate product from competitors
- align with both practice and pharmacy workflo
Use this as the source of truth for the current Prescription Hub state. Do not assume anything else unless I provide code.
