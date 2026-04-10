# Veterinary Prescription Hub – Unified JWT Auth Migration State

## 🔄 Last Updated
Date: 2026-04-10

---

## ✅ Current Status (WORKING)

### Practice UI
- Supabase Auth login implemented
- One login per practice
- JWT used for backend API calls
- Practice identity derived from token, not frontend payload
- Logout works
- Logged-in email shown in UI
- Enter/return key works at login
- Prescriber dropdown now loads directly from `prescribers`
- `practice_prescribers` is no longer used by `practice.html`
- Prescriber duplication bridge has been removed from frontend usage

### Pharmacy UI
- Supabase Auth login implemented
- UI gated behind login (`loginCard` → `mainApp`)
- Logout button added and working
- Session persists correctly across reloads
- Preview works via JWT
- Watermarked preview PDF works via JWT
- Full dispense works via JWT
- Unlocked dispense attachment works via JWT
- Start partial dispense works via JWT
- Continue partial dispense works via JWT
- Dispense all remaining items works via JWT
- Pharmacy API key is no longer needed in live workflow

---

## 🧠 Core Architectural Position

The system has now moved from:

- shared secret / API key model

to:

- identity-based JWT model via Supabase Auth

This now applies to both:
- practices
- pharmacies

### New rule
- `auth.uid()` must match the relevant record in:
  - `practices.id` for practice flows
  - `pharmacies.id` for pharmacy flows

---

## ✅ Current Live Auth Model

### Practices
- Login with email/password
- Backend trusts JWT
- `req.practiceId` derived from token
- No frontend `practice_id` trust
- No frontend practice secret usage

### Pharmacies
- Login with email/password
- RPC functions trust `auth.uid()`
- No live dependency on `p_api_key`
- No live dependency on `pharmacy_api_keys`

---

## ✅ Working JWT Functions

### Pharmacy JWT functions now in use
- `get_prescription_state`
- `get_prescription_preview_attachment`
- `full_dispense_prescription`
- `get_prescription_dispense_attachment`
- `start_partial_dispense`
- `continue_partial_dispense`

### Practice-side core flow
- issue-and-process via JWT-authenticated backend
- replace attachment via JWT-authenticated backend
- void prescription via JWT-authenticated backend
- update identifier/reference via JWT-authenticated backend

---

## ✅ Prescriber Model

### Current correct source of truth
- `prescribers`

Columns include:
- `id`
- `practice_id`
- `vet_name`
- `rcvs_number`
- `is_active`

### Important outcome
- `practice.html` now loads prescribers directly from `prescribers`
- duplicate "Rory Gormley" bridge logic is no longer used in the UI
- one prescriber source of truth is now established at frontend level

---

## ✅ Pharmacy Partial Dispense Model

### `prescription_items` table includes
- `id`
- `prescription_id`
- `line_number`
- `drug_description`
- `quantity_prescribed`
- `quantity_dispensed`
- `quantity_remaining`
- `status`
- `created_at`

### Working behaviour
- Start partial dispense creates item rows
- Continue partial dispense updates remaining quantities
- Dispense all remaining items works
- Prescription state refreshes correctly
- Itemised mode now returned correctly from `get_prescription_state`

---

## ⚠️ Legacy Code Still Present (NOT USED BY LIVE UI)

### Legacy SQL functions still exist
- `check_prescription_with_key`
- `continue_partial_dispense_with_key`
- `flag_prescription_issue_with_key`
- `full_dispense_prescription_with_key`
- `get_prescription_attachment_with_key`
- `get_prescription_dispense_attachment_with_key`
- `get_prescription_preview_attachment_with_key`
- `get_prescription_state_with_key`
- `start_partial_dispense_with_key`

### Legacy table still exists
- `pharmacy_api_keys`

### Important note
These appear to be legacy only and are no longer used by the live `pharmacy.html`, but they have not yet been retired from the database.

---

## 🚧 High-Priority Cleanup Next Session

### 1. Retire legacy API-key pharmacy code
Goal:
- remove all unnecessary old code still present in database

Planned actions:
- verify no current frontend or backend path still references `_with_key`
- drop all legacy `_with_key` SQL functions
- drop `pharmacy_api_keys` table

This is important for:
- tidiness
- reducing bug surface area
- preventing accidental use of old auth model
- making the system easier to reason about

---

### 2. Pharmacy UI polish / parity with practice UI
Need to ensure `pharmacy.html` matches `practice.html` standards:

#### Required
- show logged-in email at top of UI
- keep logout button visible and working
- make return/enter key submit login form
- reduce ambiguity about which account is signed in

Note:
- practice UI already behaves correctly here
- pharmacy UI needs to match it cleanly

---

### 3. Remove obsolete UI remnants from `pharmacy.html`
Need to confirm and clean:
- no API key input field remains
- no `apiKeyInput`
- no `apiKey`
- no `_with_key` references
- `getInputs()` should return only:
  - `rxCode`

---

### 4. Confirm no obsolete bridge/dead code remains in practice flow
Goal:
- ensure `practice_prescribers` is no longer needed anywhere
- ensure no dead prescriber bridge logic remains
- leave one clean prescriber path only

---

## 🐛 Important Issues Encountered and Resolved

### ACTIVE_PHARMACY_NOT_FOUND
Cause:
- logged in as non-pharmacy user

Fix:
- pharmacy JWT flow must use a user whose `auth.uid()` matches `pharmacies.id`

### Invalid API key
Cause:
- old post-dispense / attachment path still called legacy `_with_key` function

Fix:
- migrated dispense attachment loading to JWT function

### record has no field "email"
Cause:
- JWT full dispense function referenced non-existent `pharmacies.email`

Fix:
- removed email reference from function

### No partial dispense mode is active
Cause:
- `partialMode` was being set before `resetPartialMode()`, which nulled it out

Fix:
- always call `resetPartialMode()` first, then set `partialMode`

### null value in column "line_number" violates not-null constraint
Cause:
- `start_partial_dispense` did not populate `line_number`

Fix:
- assign incrementing `line_number` during item creation

### Could not choose best candidate function
Cause:
- duplicate overloaded `continue_partial_dispense` functions existed (`integer` and `numeric`)

Fix:
- removed old integer version, kept numeric version only

### Itemised prescription still showing as unitemised
Cause:
- early minimal JWT version of `get_prescription_state` always returned `mode = unitemised`

Fix:
- replaced with full item-aware version that returns `items` array and `mode = itemised` when appropriate

---

## 🧭 Current Position

The system is now:

- JWT-authenticated for both practices and pharmacies
- functioning end-to-end for issue, preview, replace, void, full dispense, and partial dispense
- much closer to production architecture
- still carrying legacy SQL baggage that should now be retired deliberately

---

## 🔜 Next Session Starting Point

Resume from:

1. retire all legacy pharmacy `_with_key` SQL functions
2. drop `pharmacy_api_keys`
3. tidy `pharmacy.html` for parity with `practice.html`
   - logged-in email visible
   - logout visible
   - enter key submits login
4. confirm no obsolete code remains in live paths

---

## 🧩 Design Principle

Aim for:
- one authentication model
- one source of truth
- minimal dead code
- minimal hidden legacy paths
- reduced bug surface area
- clear, auditable user identity everywhere

Avoid:
- parallel auth systems
- temporary bridges left in place
- dormant legacy code that could accidentally be re-used
