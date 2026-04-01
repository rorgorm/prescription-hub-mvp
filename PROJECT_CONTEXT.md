Project Context – Prescription Processing System (MVP)

Last Updated

2026-04-01

Overview

This project is now a working hosted MVP for a veterinary prescription workflow with:
	•	Practice-side prescription issuing
	•	Hosted backend processing on Railway
	•	Supabase database + storage
	•	Pharmacy-side preview and dispense flow
	•	Safe void-and-reissue correction flow

The system is now suitable for controlled demonstration, but not yet production-ready from a security or authentication perspective.

Architecture

Frontend (Practice)
	•	File: practice.html
	•	Runs locally in browser
	•	Current purpose:
	•	Select prescriber
	•	Select validity period
	•	Mark as controlled drug
	•	Upload prescription PDF
	•	Issue prescription in a single action
	•	Display recent uploaded prescriptions log

Frontend (Pharmacy)
	•	Existing separate pharmacy HTML remains in use
	•	Handles:
	•	Entering / using Rx code
	•	Previewing watermarked PDF
	•	Dispensing flow

Backend
	•	Node.js / Express server hosted on Railway
	•	Public domain:
	•	https://prescription-processor-production.up.railway.app

Main endpoints
	•	POST /api/issue-and-process
	•	POST /process-prescription-attachments
	•	GET /api/practice-prescriptions
	•	POST /api/void-and-reissue
	•	GET /health

Database & Storage (Supabase)
	•	PostgreSQL database with RPC functions
	•	Storage bucket:
	•	prescription-attachments

Current Working State

The following are now working:
	•	Practice-side upload from practice.html
	•	Practice-side issue-and-process via hosted Railway backend
	•	Railway deployment is live and no longer dependent on local laptop server
	•	Prescription processing generates:
	•	canonical original attachment path
	•	preview PDF
	•	dispense PDF
	•	Existing pharmacy-side HTML remains separate and continues to handle preview / dispense flow
	•	Manual SQL and manual curl are no longer required for the normal practice-side issuing workflow
	•	Practice prescriptions endpoint returns a large recent prescription list successfully
	•	Safe void-and-reissue endpoint works successfully when passed:
	•	a valid old Rx code
	•	a valid uploaded file path
	•	prescriber ID
	•	void reason
	•	validity days
	•	controlled drug flag

Practice UI – Current State

Current inputs on practice.html
	•	Prescriber
	•	Validity period
	•	Controlled drug checkbox
	•	defaults to No
	•	Prescription PDF upload

Current behaviour
	1.	User selects prescriber
	2.	User selects validity period
	3.	User optionally ticks controlled drug
	4.	User uploads PDF
	5.	User clicks “Upload and issue prescription”
	6.	Frontend uploads file to Supabase Storage
	7.	Frontend calls Railway backend /api/issue-and-process
	8.	Backend issues prescription and processes files
	9.	UI returns Rx code
	10.	Practice page can now also show recent uploaded prescriptions

Practice Log / Workspace Direction

We have now agreed that the practice upload page should evolve into a broader practice workspace, not just a one-off upload form.

Why this is needed
	•	Practices need to review previous uploads
	•	Practices need to void and replace incorrect uploads
	•	Practices will likely value the upload page as a useful log / reference tool
	•	Date-based searching is important
	•	Potential future support for optional owner email as a search key and delivery mechanism

Agreed direction
	•	The page should show uploaded prescriptions in a log
	•	Practices should be able to return later and void / re-upload a corrected attachment
	•	Date range filtering is preferred over exact date-only filtering
	•	Owner email is likely useful as an optional field later, but is not yet implemented

Owner Email Discussion

We discussed making owner email an optional upload field in future.

Possible advantages
	•	Useful search identifier for practices
	•	Potentially useful for owners looking up historic prescriptions
	•	Could support automatic owner email sending of Rx code / details

Important caveat
	•	Owner email would be personal data
	•	This would trigger GDPR considerations
	•	Current thinking:
	•	optional, not mandatory
	•	only added once the wider practice workspace is stable

Security Model – Current MVP

Current state
	•	Practice UI uses a shared secret via:
	•	Authorization: Bearer ...
	•	Backend validates PRACTICE_UI_SECRET

Important limitation
	•	This secret is currently present in frontend code
	•	This is acceptable only for controlled MVP/demo use
	•	This is not the final production security model

Future direction
	•	Replace shared secret with proper authentication
	•	Add practice accounts and role-based access

Environment Variables (Railway)

Required service-level variables
	•	SUPABASE_URL
	•	SUPABASE_SERVICE_ROLE_KEY
	•	PROCESSOR_SECRET
	•	PRACTICE_UI_SECRET
	•	BUCKET_NAME

Notes
	•	Missing variables cause startup failure
	•	Previous Railway crash was caused by missing PRACTICE_UI_SECRET
	•	Railway edits must actually be deployed, not just saved

CORS

CORS needed to be enabled because practice.html is browser-based and calls Railway directly.

This was required due to:
	•	Browser preflight OPTIONS requests
	•	Authorization header in fetch requests

Without proper CORS handling, browser showed:
	•	“Load failed”
	•	preflight 502 / blocked fetch errors

Supabase Storage

Bucket
	•	prescription-attachments

Relevant current policy state
	•	Public read policy exists
	•	Practice-side upload path works in MVP flow

Important note
	•	The upload path generated by practice.html is timestamped and must be used exactly when passing file paths to backend endpoints

Watermarking

Watermark system is stable and accepted.

Characteristics
	•	Horizontal
	•	Dense
	•	Edge-to-edge feel
	•	Repeating phrase includes Rx code
	•	Brick / stagger pattern
	•	Final tuning accepted by user

Current settings
	•	fontSize = 12
	•	opacity = 0.16
	•	rowGap = 22
	•	stagger offset based on unit text width

Important Backend Structure (server.js)

Key components currently present
	•	requireSecret(...)
	•	requirePracticeUiSecret(...)
	•	processPrescriptionAttachment(...)
	•	/process-prescription-attachments
	•	/api/issue-and-process
	•	/api/practice-prescriptions
	•	/api/void-and-reissue
	•	/health

processPrescriptionAttachment(...) handles
	•	download original file
	•	clean dispense PDF creation
	•	preview watermark generation
	•	upload of processed files
	•	DB update of attachment fields

Practice Prescriptions Endpoint

GET /api/practice-prescriptions is now working and returns a large list of prescriptions.

Purpose
	•	populate recent prescription list on practice page
	•	foundation for practice workspace / log

Important note
	•	Earlier generic error “Failed to fetch prescriptions” was resolved
	•	Terminal curl test confirmed this endpoint now works

Void-and-Reissue Flow

The safe corrected design is now:
	1.	Load original prescription
	2.	Issue replacement prescription (new Rx code)
	3.	Process replacement attachment
	4.	Link replacement to old prescription using supersedes_id
	5.	Only then void old prescription

This is important.

Agreed model
	•	The replacement gets a NEW Rx code
	•	The old Rx code is not reused
	•	The old prescription remains immutable
	•	The old prescription is only voided after the replacement is successfully issued and processed

Why this is preferred
	•	safer audit trail
	•	clearer pharmacy logic
	•	avoids ambiguity
	•	consistent with immutable / append-only design

Important lesson from testing
	•	Earlier version voided first, which was unsafe if later steps failed
	•	This was rewritten safely
	•	The safe version is now working

Successful test result already achieved
	•	old Rx code successfully voided
	•	replacement Rx code successfully created
	•	processed attachment paths generated
	•	endpoint returned ok: true

Important behavioural note
	•	The backend will accept any valid uploaded attachment_path as the replacement attachment
	•	It does not know whether this was a genuinely corrected file or simply an existing uploaded file path reused during testing
	•	In the final UI, the correction flow should make the user upload/select the replacement file deliberately

Key Lessons Learned
	•	Missing environment variables on Railway cause full server crash
	•	Railway changes must actually be deployed, not just edited
	•	Browser errors like “Load failed” can hide CORS / preflight issues
	•	Real product architecture needs a backend orchestration layer
	•	It was correct to separate practice and pharmacy UIs
	•	The processor must be hosted, not run from a laptop, for real demos
	•	Safe correction flow must not void the old prescription before replacement processing succeeds
	•	When testing with curl, placeholder file paths or Rx codes will cause confusing but logical failures

Current Limitations
	•	Practice UI still uses shared secret in browser code
	•	No real auth yet
	•	No polished success state yet
	•	No copy button for Rx code yet in final refined form
	•	No direct handoff from practice UI to pharmacy UI yet
	•	No inline “Void / Correct” form in practice UI yet
	•	Date range filtering preference agreed but not yet implemented
	•	Owner email not yet implemented
	•	Error handling is still basic
	•	Security model remains MVP-only

Immediate Recommended Next Steps

UI / Workflow
	•	Rewrite practice.html again to include:
	•	recent prescription list
	•	inline “Void / Correct” action
	•	safer and clearer success state
	•	date range filtering rather than exact date only

Correction Workflow
	•	Add frontend support for:
	•	void reason
	•	replacement PDF upload
	•	call to /api/void-and-reissue

Security
	•	Replace shared secret with proper authentication
	•	Move toward practice-level auth and role separation

Future Product Extensions
	•	Optional owner email field at upload
	•	Owner email delivery of Rx code / prescription details
	•	GDPR-compliant handling of owner personal data
	•	Richer search / filtering within practice workspace

Summary

The system is now a real hosted MVP with:
	•	Practice-side issuing UI
	•	Hosted Railway backend
	•	Supabase database and storage
	•	Working PDF processing
	•	Working watermarking
	•	Separate pharmacy-side preview / dispense UI
	•	Working recent prescriptions endpoint
	•	Working safe void-and-reissue backend flow with new Rx code for corrections

This is suitable for demonstration, but not yet production-grade from a security perspective.

Resume Point

When resuming, start with:

“Rewrite practice.html with recent prescriptions log, date range filtering, and inline void/correct workflow.”
