Veterinary Prescription Hub – Project Context

📍 Project State (as of current session)

This project is a cloud-based veterinary prescription system designed to prevent fraud, duplication, and unsafe dispensing by using a centralised, auditable dispensing ledger.

The system has now transitioned from a claim/lock model to a multi-pharmacy shared dispensing model.

⸻

🧠 Core Architectural Model

Previous (deprecated)
	•	Prescription could be CLAIMED
	•	First pharmacy to claim locked out all others

Current (live model)
	•	No ownership / no locking
	•	Multiple pharmacies can dispense against the same prescription
	•	All dispensing is tracked as append-only events

👉 This is now a distributed dispensing ledger

⸻

📊 Prescription Status Model

Allowed values (prescriptions.status)
	•	ISSUED
	•	PARTIALLY_DISPENSED
	•	FULLY_DISPENSED
	•	EXPIRED
	•	VOIDED

Notes
	•	CLAIMED has been fully removed
	•	DISPENSED replaced with FULLY_DISPENSED

⸻

📦 Item Status Model

Allowed values (prescription_items.status)
	•	ISSUED
	•	PARTIALLY_DISPENSED
	•	FULLY_DISPENSED
	•	VOIDED
	•	EXPIRED

⸻

🧾 Key Database Tables

prescriptions
	•	id
	•	rx_code
	•	status
	•	issued_by
	•	drug_summary
	•	created_at
	•	issued_at
	•	expires_at
	•	validity_mode
	•	validity_days
	•	is_controlled_drug

Completion fields (replaces claimed_*)
	•	fully_dispensed_by
	•	fully_dispensed_by_pharmacy_id
	•	fully_dispensed_at

⸻

prescription_items
	•	id
	•	prescription_id
	•	line_number
	•	drug_description
	•	quantity_prescribed
	•	quantity_dispensed
	•	quantity_remaining
	•	status

⸻

prescription_item_dispenses

Each row = one dispense event
	•	prescription_item_id
	•	prescription_id
	•	pharmacy_id
	•	quantity_dispensed
	•	dispensed_at
	•	dispense_session_id
	•	billable

⸻

dispense_sessions

Logical grouping of actions
	•	id
	•	prescription_id
	•	pharmacy_id
	•	created_at
	•	session_type:
	•	FULL
	•	PARTIAL_START
	•	PARTIAL_CONTINUE

⸻

pharmacy_api_keys
	•	pharmacy_id
	•	key_hash
	•	is_active
	•	last_used_at

⸻

🔐 Authentication Model
	•	Pharmacies authenticate using API keys
	•	Keys are stored as SHA256 hashes
	•	Raw key is only known at creation time
	•	API key determines:
	•	pharmacy identity
	•	billing attribution
	•	audit logs

⸻

⚙️ Core RPC Functions

1. get_prescription_state_with_key
	•	Returns:
	•	mode: unitemised / itemised
	•	status
	•	expiry
	•	item list (if itemised)

⸻

2. start_partial_dispense_with_key
	•	Converts unitemised → itemised
	•	Creates prescription_items
	•	Creates dispense records
	•	Sets prescription status:
	•	PARTIALLY_DISPENSED or FULLY_DISPENSED

⸻

3. continue_partial_dispense_with_key
	•	Adds dispense to existing item
	•	Validates:
	•	cannot exceed remaining quantity
	•	Updates:
	•	item totals
	•	prescription status

⸻

4. full_dispense_prescription_with_key
	•	Marks entire prescription as completed
	•	Sets:
	•	status = FULLY_DISPENSED
	•	fully_dispensed_* fields
	•	Creates FULL dispense session

⸻

🖥️ Frontend (Pharmacy Test Page)

Key behaviours

Preview
	•	Always required before any action
	•	Displays:
	•	prescription status
	•	expiry
	•	item breakdown

Unitemised prescriptions
	•	Buttons:
	•	Dispense Full Prescription
	•	Start Partial Dispense

Itemised prescriptions (with remaining quantities)
	•	Buttons:
	•	Continue Partial Dispense
	•	Dispense All Remaining Items

⸻

✨ UX Improvements Implemented

1. Dispense All Remaining Items
	•	Auto-fills remaining quantities
	•	Allows quick completion

2. Validation (frontend + backend)
	•	Cannot exceed remaining quantity
	•	Clear error messages before submission

⸻

🧪 Tested Scenarios
	•	Full dispense from fresh prescription ✅
	•	Partial dispense (single pharmacy) ✅
	•	Continue partial dispense (same pharmacy) ✅
	•	Continue partial dispense (different pharmacy) ✅
	•	Over-dispense attempt blocked ✅
	•	Full completion after partial dispense ✅

⸻

🚨 Important Design Principles
	1.	No locking
	•	No pharmacy “owns” a prescription
	2.	Event-driven ledger
	•	Every dispense recorded independently
	3.	State = derived
	•	Status reflects aggregate of item states
	4.	Safety-first validation
	•	Cannot exceed prescribed quantities

⸻

🔜 Next Planned Feature

Dispense History in UI

Goal:
	•	Show which pharmacy dispensed each portion

Example:
Prascend 1 mg tablets

Dispense history:
- 100 → Pharmacy X → 18 Mar
- 50  → Pharmacy Y → 23 Mar

- This will use:
	•	prescription_item_dispenses
	•	pharmacy_id → pharmacy name join

⸻

🧭 Future Roadmap (High Level)
	1.	Dispense history UI
	2.	Soft warnings for edge-case over-dispensing
	3.	Owner-facing prescription view
	4.	PDF watermark / anti-fraud layer
	5.	Billing aggregation per pharmacy
	6.	API / partner integrations

⸻

🧩 Notes for Future Sessions
	•	Always confirm:
	•	function names
	•	schema constraints
	•	status enums
	•	Avoid reintroducing:
	•	CLAIMED model
	•	Assume:
	•	multi-pharmacy is core behaviour

⸻

📌 Summary

This system now functions as:

A multi-pharmacy, centralised, auditable prescription dispensing ledger

This is a major architectural milestone and forms the foundation for all future features.
:::
