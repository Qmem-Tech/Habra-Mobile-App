# Email owners when legal documents are approved or rejected

The mobile app **does not send email by itself**. It shows in-app banners when `business_legal_documents` rows are `approved` or `rejected` (and reads `rejection_reason`). To also email the business owner, wire something on the backend.

## Option A — Database webhook + Edge Function (recommended)

1. **Supabase Dashboard → Database → Webhooks**  
   Create a webhook on `business_legal_documents` for `UPDATE` (and optionally `INSERT`).

2. **Payload**  
   Send the row (or `record` / `old_record`) to an Edge Function URL.

3. **Edge Function** (Deno)  
   - Verify the webhook secret header.  
   - If `status` changed to `approved` or `rejected`, load `businesses.owner_id` and `profiles.email` for `business_id`.  
   - Call **Resend**, **SendGrid**, **Postmark**, or **AWS SES** with your template (subject/body for approved vs rejected; include `rejection_reason` when rejected).

4. **Secrets**  
   Store API keys in Supabase Function secrets, not in the app.

## Option B — Postgres trigger + `pg_net` / HTTP

Create an `AFTER UPDATE` trigger on `public.business_legal_documents` that calls `net.http_post` to your mail API or Edge Function when `NEW.status` differs from `OLD.status` and `NEW.status` is `approved` or `rejected`.  
Use `SECURITY DEFINER` carefully and restrict who can update rows.

## Option C — Super admin app only

If approval happens only in your admin tool, send the email from that app’s server when the admin saves (same providers as above). No database webhook required.

## App configuration

- **Support mailto** from the rejection banner: set  
  `--dart-define=SUPPORT_EMAIL=you@company.com`  
  (see `lib/core/constants/support_contact.dart`).

## Status values

The app treats document status **case-insensitively** (`approved`, `rejected`, `pending`). Keep DB values lowercase to match triggers and reports.
