# Veterinary Prescription Hub – Pharmacy UI JWT Migration State

## 🔄 Last Updated
Date: 2026-04-08

---

## ✅ Current Status (WORKING)

### Authentication
- Pharmacy login via Supabase Auth is implemented
- UI gated behind login (loginCard → mainApp)
- Logout button added and working
- Session persists correctly across reloads

### JWT Migration Progress

#### Completed (JWT-based)
- get_prescription_state
- get_prescription_preview_attachment
- full_dispense_prescription
- get_prescription_dispense_attachment

#### Still using API key (legacy)
- start_partial_dispense_with_key
- continue_partial_dispense_with_key

---

## 🧠 Key Architectural Change

System is transitioning from:

API key–based pharmacy authentication  
→ JWT-based pharmacy authentication (Supabase Auth)

New rule:
- auth.uid() MUST match pharmacies.id
- pharmacies.is_active = true

---

## 🏗️ Database Requirements

### pharmacies table
Columns:
- id (UUID) ← MUST match Supabase Auth user ID
- name
- is_active
- created_at

Important:
Each pharmacy user must have:
1. Supabase Auth account
2. Matching row in public.pharmacies

---

## 🧪 Current Working Flow

### Pharmacy flow:
1. Login (email/password)
2. Enter Rx code
3. Click Preview
   - Calls get_prescription_state (JWT)
   - Loads preview PDF (watermarked)
4. Click "Dispense Full"
   - Calls full_dispense_prescription (JWT)
5. Unlocked PDF loads
   - Calls get_prescription_dispense_attachment (JWT)

No API key required for:
- Preview
- Full dispense
- Attachment access

---

## ❗ Known Transitional State

UI still includes:
- Pharmacy API key input field (now redundant)

Backend still includes:
- Partial dispense via _with_key functions

---

## 🚧 Next Steps (HIGH PRIORITY)

### 1. Migrate partial dispense to JWT

Replace:
- start_partial_dispense_with_key
- continue_partial_dispense_with_key

With:
- start_partial_dispense
- continue_partial_dispense

Using:
- auth.uid()

---

### 2. Remove API key completely

Once partial dispense is migrated:

Remove:
- API key input field
- apiKeyInput
- all references to apiKey

Simplify:
- getInputs() → return { rxCode }

---

### 3. UI cleanup
- Remove API key box from pharmacy.html
- Keep:
  - login status display
  - logout button

---

### 4. Optional improvements
- Add role-based guard (pharmacy vs practice)
- Display pharmacy name in UI
- Add session timeout handling

---

## 🐛 Issues Encountered (Resolved)

ACTIVE_PHARMACY_NOT_FOUND
- Cause: logged in as non-pharmacy user
- Fix: auth.uid() must match pharmacies.id

Invalid API key
- Cause: legacy _with_key function still called
- Fix: migrated attachment + full dispense to JWT

record has no field "email"
- Cause: function referenced non-existent column
- Fix: removed email reference

---

## 🧭 Current Position

- Fully authenticated pharmacy UI
- Core dispense flow working via JWT
- Midway through removing API key system

---

## 🔜 Next Session Starting Point

Resume from:

"Migrate partial dispense to JWT and remove API key completely"

---

## 🧩 Key Insight

System is evolving into:

A true identity-based dispensing ledger  
rather than a token/key-based access system
