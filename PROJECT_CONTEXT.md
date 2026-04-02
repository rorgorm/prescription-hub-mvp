Project Context – Prescription Processing System (MVP)

Last Updated

2026-04-02

⸻

Overview

This project is a working hosted MVP for a veterinary prescription workflow with:
	•	Practice-side prescription issuing UI
	•	Hosted backend processing on Railway
	•	Supabase database + storage
	•	Pharmacy-side preview and dispense flow
	•	Safe void-and-reissue correction workflow
	•	Emerging “practice workspace” with prescription log and correction tools

The system is now suitable for controlled demonstration, but not yet production-ready from a security or authentication perspective.

⸻

Architecture

Frontend (Practice)
	•	File: practice.html
	•	Runs locally in browser
	•	Now functions as a workspace, not just an upload form
	•	Responsibilities:
	•	Issue prescriptions
	•	Display recent prescriptions log
	•	Filter prescriptions (date range + Rx code)
	•	Edit optional reference text
	•	Void and reissue prescriptions inline

Frontend (Pharmacy)
	•	Separate HTML page (unchanged)
	•	Responsibilities:
	•	Enter Rx code
	•	View preview PDF
	•	Dispense prescription

Backend
	•	Node.js / Express server hosted on Railway
	•	Public domain:
https://prescription-processor-production.up.railway.app

Endpoints:
	•	POST /api/issue-and-process
	•	POST /process-prescription-attachments
	•	GET /api/practice-prescriptions
	•	POST /api/void-and-reissue
	•	POST /api/update-prescription-reference
	•	GET /health

⸻

Database & Storage (Supabase)

Database:
	•	PostgreSQL
	•	prescriptions table now includes:
	•	reference_text (NEW)

Storage:
	•	Bucket: prescription-attachments
	•	Stores:
	•	original uploads
	•	preview PDFs
	•	dispense PDFs

⸻

Current Working State

Working end-to-end:
	•	Practice uploads file → Supabase storage
	•	Backend issues prescription
	•	Backend processes:
	•	clean dispense PDF
	•	watermarked preview PDF
	•	Backend updates DB with attachment paths
	•	Practice UI displays:
	•	recent prescriptions
	•	relationships (replaces / replaced by)
	•	metadata
	•	Void-and-reissue flow:
	•	creates new Rx code
	•	links via supersedes_id
	•	voids original safely

Manual SQL and curl are no longer required for normal flows.

⸻

Practice Workspace (Current Features)

Issue section:
	•	Prescriber selection
	•	Validity period
	•	Controlled drug checkbox
	•	Optional “Unique identifier” (reference_text)
	•	PDF upload
	•	One-click issue

Prescription log:
	•	Displays recent prescriptions
	•	Shows:
	•	Rx code
	•	status
	•	created date
	•	validity
	•	controlled drug flag
	•	void reason (if applicable)
	•	reference_text (editable)

Filtering:
	•	Date range (from + to)
	•	Rx code search

Inline actions:
	•	Copy Rx code
	•	View PDF (currently broken – see below)
	•	Void / Correct workflow (inline panel)
	•	Edit and save reference_text

Relationships:
	•	“Replaces RX-…”
	•	“Replaced by RX-…”

⸻

Reference Text Feature (NEW)

Field: reference_text (TEXT)

Purpose:
	•	Human-readable identifier
	•	Examples:
	•	“Blackie Smith”
	•	PMS code
	•	Animal ID

Behaviour:
	•	Optional at upload
	•	Can be edited retrospectively from list
	•	Stored in DB and returned via API
	•	Updated via:
POST /api/update-prescription-reference

⸻

Prescription Relationships (NEW)

Backend now returns:
	•	supersedes_rx_code
	•	replaced_by_rx_code

UI displays:
	•	Replaces RX-XXXX
	•	Replaced by RX-YYYY

This improves audit clarity and usability significantly.

⸻

Void-and-Reissue Flow (Final Design)

Correct safe sequence:
	1.	Load original prescription
	2.	Issue replacement prescription (new Rx code)
	3.	Process replacement attachment
	4.	Link replacement → old via supersedes_id
	5.	Void old prescription

Key rules:
	•	Replacement ALWAYS gets a new Rx code
	•	Old Rx code is never reused
	•	Old prescription remains immutable
	•	Void only occurs after successful replacement

This is now implemented and working.

⸻

Backend Structure (server.js)

Key components:
	•	requireSecret(…)
	•	requirePracticeUiSecret(…)
	•	processPrescriptionAttachment(…)
	•	/api/issue-and-process
	•	/api/practice-prescriptions
	•	/api/void-and-reissue
	•	/api/update-prescription-reference
	•	/health

processPrescriptionAttachment handles:
	•	download original file
	•	generate dispense PDF
	•	generate preview watermark PDF
	•	upload processed files
	•	update DB paths

⸻

Environment Variables (Railway)

Required:
	•	SUPABASE_URL
	•	SUPABASE_SERVICE_ROLE_KEY
	•	PROCESSOR_SECRET
	•	PRACTICE_UI_SECRET
	•	BUCKET_NAME

Notes:
	•	Missing variables → server crash
	•	Must be set at service level
	•	Changes require redeploy

⸻

Security Model (Current MVP)

Current:
	•	Practice UI uses shared secret:
Authorization: Bearer PRACTICE_UI_SECRET

Limitations:
	•	Secret is exposed in frontend
	•	Acceptable for demo only

Future:
	•	Replace with authentication system
	•	Practice accounts + roles
	•	Token-based auth

⸻

CORS

Enabled to allow:
	•	Browser → Railway API calls
	•	Authorization headers

Without CORS:
	•	“Load failed”
	•	preflight errors

⸻

Watermarking

Status: stable and accepted

Characteristics:
	•	horizontal
	•	dense
	•	repeating pattern
	•	includes Rx code
	•	brick/stagger layout

Settings:
	•	fontSize: 12
	•	opacity: 0.16
	•	rowGap: 22

⸻

Known Issue (IMPORTANT)

View PDF button currently fails with:

{“statusCode”:“404”,“error”:“Bucket not found”,“message”:“Bucket not found”}

Cause:
	•	UI builds direct public URL to Supabase storage
	•	bucket access method incorrect for current setup

Planned fix:
	•	switch to Supabase signed URLs via:
storage.createSignedUrl(…)

Status:
	•	NOT yet implemented

⸻

Key Lessons Learned
	•	Railway must be deployed, not just edited
	•	Missing env vars crash entire service
	•	Browser errors often mask CORS issues
	•	Hosted backend is essential for real demos
	•	Separation of practice vs pharmacy UI was correct
	•	Safe correction flow must not void first
	•	Storage paths must be used exactly as uploaded
	•	Relationship mapping (supersedes) greatly improves UX

⸻

Current Limitations
	•	View PDF broken (signed URL fix pending)
	•	Shared secret in frontend (not secure)
	•	No authentication system yet
	•	No owner email feature yet
	•	No inline preview modal (new tab only planned)
	•	Basic error handling
	•	No pagination on prescription list
	•	No search beyond Rx/date

⸻

Next Steps

Immediate:
	1.	Fix View PDF using signed URLs
	2.	Minor UI polish (spacing, clarity)
	3.	Optional:
	•	highlight active correction item
	•	improve success messaging

Short-term:
	4.	Add authentication (replace shared secret)
	5.	Introduce practice accounts

Future:
	6.	Optional owner email field
	7.	Auto-send Rx to owner
	8.	GDPR-compliant handling of personal data
	9.	Advanced filtering/search
	10.	Full audit trail UI

⸻

Summary

The system is now a functioning hosted MVP with:
	•	Practice workspace UI
	•	Backend processing on Railway
	•	Supabase DB + storage
	•	Working issue + process flow
	•	Working void-and-reissue workflow
	•	Prescription log with filtering
	•	Editable reference identifiers
	•	Relationship tracking between prescriptions

This is now a credible demonstrable product, but requires:
	•	authentication
	•	security hardening
	•	storage access refinement

before production use.

⸻

Resume Point

When resuming, start with:

“Fix View PDF using signed URLs, then move on to authentication.”

⸻

If you want next time, we can:
👉 fix that PDF issue in ~2 minutes
👉 then move straight into proper login/auth (this is the big next step)
