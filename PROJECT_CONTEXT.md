# 📘 Veterinary Prescription Hub – Project Context

## 🔄 Last Updated
Date: 2026-04-03

---

## ✅ Current System State

### 🎯 Core Flow (Working End-to-End)
- Prescription issued via Supabase RPC: `issue_prescription`
- Attachment uploaded (PDF or image)
- Node processor:
  - Converts images → PDF (lossless, no cropping)
  - Generates:
    - original (canonical file)
    - dispense.pdf (clean version)
    - preview.pdf (watermarked)
- Files stored in Supabase Storage (bucket: prescription-attachments)
- DB updated with attachment paths + metadata

---

## 🧾 Attachment Handling

### Supported Upload Types
- PDF
- Images (JPEG, PNG, WEBP, HEIC, HEIF)

### Processing Behaviour
- Images converted using sharp + pdf-lib
- No cropping or scaling (1:1 embedding)
- Orientation corrected
- No clinical data loss

---

## 🔁 Replace Attachment (LOW FRICTION)

### Behaviour
- Same rx_code retained
- Replaces:
  - original
  - preview
  - dispense

### Restrictions
- Blocked if status is:
  - PARTIALLY_DISPENSED
  - FULLY_DISPENSED
  - DISPENSED

### UI
- Drag & drop supported
- Accepts PDF + image formats
- Clear wording (no PDF-only restriction)

### Validation
- File required (alert)
- Reason required (alert)

---

## 🧠 Replace Audit Fields

Columns in `prescriptions`:
- replace_count
- last_replace_reason
- last_replaced_at

### Behaviour
- replace_count increments
- last_replace_reason updated
- last_replaced_at updated

---

## 🚫 Void Prescription

Endpoint: POST /api/void-prescription

- Sets:
  - status = VOIDED
  - voided_at
  - void_reason

### Principle
- “Void and forget”
- No forced reissue

---

## 🔄 Void + Reissue

Endpoint: POST /api/void-and-reissue

- Generates new rx_code
- Links via supersedes_id
- Voids original

---

## 📄 Practice UI

### Prescription Log
Displays:
- rx_code
- status
- reference_text
- relationships (superseded / replaced)

### Actions
- View Original
- View Owner Copy
- Replace Attachment
- Void Prescription
- Edit Reference

---

## 📂 Storage Structure

{prescription_id}/
  ├── original.{ext}
  ├── dispense.pdf
  └── preview.pdf

---

## ⚙️ Backend (Node / Railway)

### Endpoints
- /api/issue-and-process
- /api/replace-attachment
- /api/void-prescription
- /api/void-and-reissue
- /api/practice-prescriptions
- /process-prescription-attachments
- /health

### Security
- PROCESSOR_SECRET
- PRACTICE_UI_SECRET

---

## 🧪 Known Working Behaviour

- Replace works correctly
- Replace blocked after dispense
- Void works independently
- Watermark fixed
- Drag & drop working
- Alerts prevent silent failures

---

## ⚠️ Known Limitations

- No full attachment history
- Alerts instead of inline validation
- Large images → large PDFs
- No multi-page image support

---

## 🧭 Design Principles

1. Friction minimisation
2. Clinical safety
3. Lightweight audit
4. Clear separation (replace ≠ void ≠ reissue)

---

## 🧠 Current Position

Functional MVP with real-world usability

---

## 🔜 Next Phase Options

### UX
- Inline validation
- Replace indicators
- Toast messages

### Audit
- Full version history (optional)

### Processing
- A4 scaling (optional)
