# Mobile app ↔ Super Admin — alignment guide

Short reference for updating the **Habra mobile app** so it matches what the **Super Admin** web app and Supabase now support.

---

## 1. Platform notifications (`platform_notifications`)

**Purpose:** Admins create broadcast messages from the web app (title, body, audience). The mobile app can show them in an inbox or as banners once users are allowed to **read** the table.

### Schema (after migration)

| Column        | Type        | Notes |
|---------------|-------------|--------|
| `id`          | uuid        | Primary key |
| `title`       | text        | Short headline |
| `body`        | text        | Full message |
| `audience`    | text        | `'all'` \| `'business_owners'` \| `'customers'` |
| `created_at`  | timestamptz | Server default `now()` |
| `created_by`  | uuid        | Admin’s `auth.users.id`, nullable |

### Current RLS (important)

- Only **`profiles.role = 'admin'`** (via `is_admin()`) can **insert/update/delete/select** today.
- The **mobile app cannot read this table** until you add read policies (or expose data through an Edge Function).

### Suggested mobile integration

1. **Filter by audience** using the signed-in user’s role (e.g. treat `businessOwner` as `business_owners`, `customer` as `customers`, and show `all` to everyone).
2. **Order by** `created_at` descending; optionally store `last_seen_notification_id` locally to mark “new” items.
3. **Backend options (pick one):**
   - **A — RLS read policies** on `platform_notifications` for `authenticated` users (e.g. `SELECT` where audience matches their segment, or `audience = 'all'`).
   - **B — Edge Function** that returns rows for the current JWT (keeps table locked down from direct client reads).
   - **C — `user_notifications`** (separate table): an admin or cron job copies each broadcast into per-user rows; mobile reads only that table (common for push + badge counts).

### Supabase query shape (once read access exists)

```text
from('platform_notifications')
  .select('id, title, body, audience, created_at')
  .order('created_at', { ascending: false })
```

Apply audience filtering **in app code** or in RLS / SQL.

---

## 2. Dynamic business categories

**Purpose:** Category list is maintained in Super Admin (“Listing categories”). Mobile onboarding and discovery should **not** hardcode categories.

### Tables

- **`categories`** — canonical rows: `id`, `name`, `slug`, `description`, `icon_key`, `sort_order`, `is_active`, timestamps.
- **`business_categories`** — many-to-many: `(business_id, category_id)`.

### Reads for pickers / filters

- For **new business signup** or filters: load categories with **`is_active = true`**, ordered by `sort_order`, then `name`.
- RLS already allows **public/authenticated** read of **active** rows only (see migration `20250328000000_categories_business_categories_admin.sql`).

### After owner selects categories

- Mobile should **insert/delete** rows in `business_categories` for that `business_id` (owner RLS applies). Super Admin can also assign tags from the web app; both write to the same junction table.

### Icons

- `icon_key` is a string stored for the app to map to your asset pack (same idea as the web admin).

---

## 3. Business legal documents & review

**Purpose:** Owners upload files; admins review **per file** (`pending` → `approved` / `rejected`).

### Relevant columns (`business_legal_documents`)

- `review_status`: `'pending'` \| `'approved'` \| `'rejected'`
- `rejection_reason` — required when rejected (non-empty).
- `reviewed_at`, `reviewed_by`

### Mobile behavior

- Show **owner** the current status and **rejection reason** when `rejected`.
- Owners **cannot** change review fields (enforced by trigger); only admins can.
- Optional DB helper: `business_legal_documents_all_approved(business_id)` — `true` when there is at least one row and every row is `approved` (useful for “fully compliant” gating).

### Files

- Rows reference **Storage** (`storage_bucket`, `storage_path`, etc.). Download/preview uses your existing signed-URL flow; align bucket name with web env (`legal_documents` / project-specific).

---

## 4. Business profile fields (read-only context)

Super Admin loads **`businesses.*`** plus owner `profiles` (`email`, `full_name`) and linked categories.

- Any **extra columns** on `businesses` (e.g. description, phone, address) should be **read and edited on mobile** the same way you already persist them—they will appear in admin automatically when present in the database.
- Do not rely on client-only fields that are never written to Supabase.

---

## 5. Checklist for mobile

| Area | Action |
|------|--------|
| Notifications | Add read path + audience filtering; or Edge Function / `user_notifications` |
| Category lists | Load from `categories` where `is_active = true`, sorted |
| Business tags | Sync `business_categories` with owner + admin changes |
| Legal docs | Show review status + rejection reason; respect admin-only review |
| Storage | Same buckets/paths as web for legal documents |

---

## 6. Migrations to apply on Supabase (if not already)

- `20250328000000_categories_business_categories_admin.sql`
- `20250329200000_business_legal_documents.sql` (and bucket migration)
- `20250330120000_business_legal_documents_review.sql`
- `20250331140000_platform_notifications.sql`

Deploy these to the same Supabase project the mobile app uses, then add **notification read** policies or an API as in §1.
