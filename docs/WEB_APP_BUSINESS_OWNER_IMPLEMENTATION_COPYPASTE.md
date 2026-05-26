# Habra Business Owner Web App — Copy-Paste Implementation

This document consolidates **everything you need** to implement the Business Owner Web app. Copy and paste sections into your project. The mobile app and web app share the **same Supabase project**, so **you do not need to run any SQL migrations** — RLS, storage policies, and schema are already in place.

---

## SQL & Database — No Action Required

| Question | Answer |
|----------|--------|
| Do I need to run SQL migrations? | **No.** The mobile app and web app use the same Supabase project. RLS, storage buckets, and policies are already applied. |
| What if I see RLS or storage errors? | Run `docs/supabase/migrations/fix_all_rls_and_storage.sql` **once** in Supabase Dashboard → SQL Editor (only if your project is new or missing buckets). |
| Schema reference | See `docs/supabase/habra_full_schema.sql` for table definitions. |
| Review replies | Mobile app uses `reply_text` and `replied_at` on `reviews`. If missing, add: `ALTER TABLE reviews ADD COLUMN IF NOT EXISTS reply_text TEXT, ADD COLUMN IF NOT EXISTS replied_at TIMESTAMPTZ;` — or use `review_replies` table. |

---

## 1. Environment & Supabase Client

### `.env`
```env
VITE_SUPABASE_URL=https://YOUR_PROJECT.supabase.co
VITE_SUPABASE_ANON_KEY=your_anon_key
```

### `src/lib/supabase.ts`
```ts
import { createClient } from '@supabase/supabase-js';

const url = import.meta.env.VITE_SUPABASE_URL;
const anonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;
if (!url || !anonKey) throw new Error('Missing Supabase env');

export const supabase = createClient(url, anonKey);
```

### Table & Bucket Constants
```ts
// src/lib/constants.ts
export const TABLES = {
  profiles: 'profiles',
  businesses: 'businesses',
  deals: 'deals',
  jobs: 'jobs',
  reviews: 'reviews',
  jobApplications: 'job_applications',
  boostPlans: 'boost_plans',
  boosts: 'boosts',
  businessLegalDocuments: 'business_legal_documents',
  events: 'events',
  eventTickets: 'event_tickets',
} as const;

export const BUCKETS = {
  businesses: 'businesses',
  deals: 'deals',
  events: 'events',
  legalDocuments: 'legal_documents',
  avatars: 'avatars',
  resumes: 'resumes',
} as const;
```

---

## 2. Design Tokens (Match Mobile App)

```css
/* src/shared/theme/tokens.css */
:root {
  --color-primary: #1F563F;
  --color-primary-light: #2D6B4F;
  --color-primary-dark: #16402F;
  --color-secondary: #C1A25F;
  --color-secondary-light: #D4B87A;
  --color-secondary-dark: #A88A4F;
  --color-text-primary: #000000;
  --color-text-secondary: #757575;
  --color-text-tertiary: #9E9E9E;
  --color-text-on-primary: #FFFFFF;
  --color-background: #FFFFFF;
  --color-background-light: #F5F5F5;
  --color-background-grey: #E0E0E0;
  --color-success: #4CAF50;
  --color-warning: #FF9800;
  --color-error: #B00020;
  --spacing-xs: 4px;
  --spacing-sm: 8px;
  --spacing-md: 16px;
  --spacing-lg: 24px;
  --spacing-xl: 32px;
  --radius-sm: 4px;
  --radius-md: 8px;
  --radius-lg: 12px;
}
```

---

## 3. Authentication & Role Guard

### Sign In (email/password)
```ts
const { data, error } = await supabase.auth.signInWithPassword({ email, password });
if (error) throw error;
// Redirect to dashboard
```

### Sign In (Google)
```ts
await supabase.auth.signInWithOAuth({ provider: 'google' });
// Add web app callback URL to Supabase Auth → Redirect URLs
```

### Get Profile & Role Check
```ts
const { data: { user } } = await supabase.auth.getUser();
if (!user) return; // redirect to sign-in

const { data: profile } = await supabase
  .from('profiles')
  .select('*')
  .eq('id', user.id)
  .single();

if (profile?.role !== 'businessOwner') {
  // Show "Wrong account" or sign out
  await supabase.auth.signOut();
  return;
}
```

### Sign Out
```ts
await supabase.auth.signOut();
// Redirect to sign-in
```

---

## 4. Supabase API — Copy-Paste Queries

All queries use the **anon** client. RLS enforces that owners only see their own data.

### 4.1 Owner Businesses
```ts
const { data } = await supabase
  .from('businesses')
  .select('*')
  .eq('owner_id', userId)
  .order('created_at', { ascending: false });
```

### 4.2 Dashboard Analytics (counts)
```ts
// Active deals count
const { data: deals } = await supabase
  .from('deals')
  .select('id')
  .eq('business_id', businessId)
  .eq('status', 'active');

// Open jobs count
const { data: jobs } = await supabase
  .from('jobs')
  .select('id')
  .eq('business_id', businessId)
  .eq('is_active', true);

// Reviews (for rating)
const { data: reviews } = await supabase
  .from('reviews')
  .select('rating')
  .eq('business_id', businessId);

const avgRating = reviews?.length
  ? reviews.reduce((s, r) => s + (r.rating || 0), 0) / reviews.length
  : 0;
```

### 4.3 Deals
```ts
// List (with optional status filter: active | expired | draft | inactive)
let query = supabase
  .from('deals')
  .select('*, businesses!deals_business_id_fkey(name)')
  .eq('business_id', businessId);
if (status) query = query.eq('status', status);
const { data } = await query.order('created_at', { ascending: false });

// Create
const { data: deal } = await supabase
  .from('deals')
  .insert({
    business_id: businessId,
    title,
    description,
    discount_percentage,
    original_price,
    discounted_price,
    valid_from,   // ISO string
    valid_until,  // ISO string
    image_url,
    category,
    status: 'active' | 'draft',
  })
  .select()
  .single();
```

### 4.4 Jobs
```ts
// List
const { data } = await supabase
  .from('jobs')
  .select('*, businesses!jobs_business_id_fkey(name, logo_url)')
  .eq('business_id', businessId)
  .order('created_at', { ascending: false });

// Create
const { data: job } = await supabase
  .from('jobs')
  .insert({
    business_id: businessId,
    title,
    description,
    location,
    job_type: 'full-time' | 'part-time' | 'contract' | etc,
    salary_min,
    salary_max,
    is_active: status !== 'draft',
    status: 'open' | 'draft' | 'closed',
  })
  .select()
  .single();
```

### 4.5 Reviews
```ts
// List (with reviewer profile)
const { data } = await supabase
  .from('reviews')
  .select('*, profiles!reviews_user_id_fkey(full_name, avatar_url)')
  .eq('business_id', businessId)
  .order('created_at', { ascending: false });

// Reply — Option A: reply_text/replied_at on reviews (mobile app uses this)
// If your reviews table has these columns (added via migration):
await supabase
  .from('reviews')
  .update({
    reply_text: replyText,
    replied_at: new Date().toISOString(),
  })
  .eq('id', reviewId);

// Reply — Option B: review_replies table (from habra_full_schema.sql)
await supabase.from('review_replies').insert({
  review_id: reviewId,
  business_id: businessId,
  body: replyText,
});
```

### 4.6 Job Applicants
```ts
// List
const { data } = await supabase
  .from('job_applications')
  .select('*, profiles!job_applications_user_id_fkey(full_name, avatar_url)')
  .eq('job_id', jobId)
  .order('created_at', { ascending: false });

// Detail
const { data } = await supabase
  .from('job_applications')
  .select('*, profiles!job_applications_user_id_fkey(full_name, avatar_url, email, phone), jobs!job_applications_job_id_fkey(title)')
  .eq('id', applicantId)
  .single();

// Update status
await supabase
  .from('job_applications')
  .update({ status: 'reviewed' | 'shortlisted' | 'rejected' | 'hired' })
  .eq('id', applicantId);
```

### 4.7 Boosts
```ts
// Plans (read-only)
const { data } = await supabase
  .from('boost_plans')
  .select('*')
  .eq('is_active', true)
  .order('price_usd', { ascending: true });

// My boosts
const { data } = await supabase
  .from('boosts')
  .select('*, boost_plans(*), deals(title), jobs(title)')
  .in('business_id', businessIds)
  .order('created_at', { ascending: false });

// Create boost
await supabase.from('boosts').insert({
  business_id,
  boost_plan_id,
  deal_id: dealId ?? null,
  job_id: jobId ?? null,
  status: 'active',
  starts_at: new Date().toISOString(),
  ends_at: endDate.toISOString(),
});
```

### 4.8 Update Business
```ts
await supabase
  .from('businesses')
  .update({
    name,
    description,
    phone,
    email,
    website,
    address_street,
    address_city,
    address_state,
    address_zip,
    latitude,
    longitude,
    logo_url,
    background_url,
    updated_at: new Date().toISOString(),
  })
  .eq('id', businessId);
```

### 4.9 Update Business Hours
```ts
await supabase
  .from('businesses')
  .update({
    opening_time: '09:00:00',  // HH:mm:ss
    closing_time: '17:00:00',
    updated_at: new Date().toISOString(),
  })
  .eq('id', businessId);
```

### 4.10 Create Business (Add New Presence)
```ts
const { data } = await supabase
  .from('businesses')
  .insert({
    owner_id: userId,
    name,
    description,
    phone,
    email,
    website,
    address_street,
    address_city,
    address_state,
    address_zip,
    latitude,
    longitude,
    opening_time,
    closing_time,
    logo_url,
    background_url,
    approval_status: 'pending',
    updated_at: new Date().toISOString(),
  })
  .select('id')
  .single();
```

### 4.11 Legal Documents
```ts
// Check status
const { data: docs } = await supabase
  .from('business_legal_documents')
  .select('status')
  .eq('business_id', businessId);
// Require 2 docs; check approvedCount, hasRejected

// Upload document (after uploading file to Storage)
await supabase.from('business_legal_documents').insert({
  business_id: businessId,
  document_type: 'license' | 'registration' | etc,
  file_url: publicUrl,
  file_name: fileName,
  status: 'pending',
});
```

### 4.12 Create Event
```ts
const { data: event } = await supabase
  .from('events')
  .insert({
    organizer_id: userId,
    business_id: businessId ?? null,
    title,
    description,
    venue_name,
    venue_address,
    venue_lat,
    venue_lng,
    start_at,
    end_at,
    image_url,
    category,
    is_active: true,
  })
  .select()
  .single();

// Event tickets
await supabase.from('event_tickets').insert([
  { event_id: event.id, name: 'General', price: 0, quantity_available: 100 },
  // ...
]);
```

---

## 5. Storage Uploads

```ts
// Upload to bucket
const path = `${businessId}/${Date.now()}_${file.name}`;
const { error } = await supabase.storage
  .from('businesses')  // or 'deals', 'events', 'legal_documents'
  .upload(path, file, { upsert: true });

if (error) throw error;

const { data: { publicUrl } } = supabase.storage
  .from('businesses')
  .getPublicUrl(path);

// Use publicUrl in your insert/update
```

**Buckets & limits (from mobile):**
| Bucket | Max size | Use |
|--------|----------|-----|
| businesses | 5MB | Logo, cover, gallery |
| deals | 5MB | Deal images |
| events | 5MB | Event images |
| legal_documents | 10MB | PDF/JPG/PNG |
| avatars | 2MB | Profile photo |

---

## 6. Error Handling (User-Friendly Messages)

```ts
function getUserMessage(error: unknown): string {
  const msg = String(error).toLowerCase();
  if (msg.includes('connection') || msg.includes('network') || msg.includes('timeout'))
    return 'Check your internet connection and try again.';
  if (msg.includes('unauthorized') || msg.includes('session'))
    return 'Please sign in again.';
  if (msg.includes('upload') || msg.includes('storage') || msg.includes('bucket'))
    return 'We couldn\'t upload your file. Check that the file is under 5MB and try again.';
  if (msg.includes('5mb') || msg.includes('size') || msg.includes('too large'))
    return 'File must be under 5MB. Try a smaller image.';
  return 'Something went wrong. Please try again.';
}
```

---

## 7. Feature Checklist

| Feature | Tables / Buckets | Notes |
|---------|------------------|-------|
| Sign in | Auth, profiles | Require role = businessOwner |
| Dashboard | businesses, deals, jobs, reviews | Summary counts + lists |
| My Businesses | businesses | List, create, edit |
| Deals | deals, businesses | List, create, edit, filter by status |
| Jobs | jobs, businesses | List, create, edit |
| Reviews | reviews, profiles | List, reply (reply_text/replied_at) |
| Applicants | job_applications, profiles, jobs | List, detail, update status |
| Boosts | boosts, boost_plans, deals, jobs | List plans, list boosts, create |
| Edit Business | businesses | Update fields, hours |
| Business images | businesses bucket | Logo, cover upload |
| Legal documents | business_legal_documents, legal_documents bucket | 2 docs per business, pending |
| Create Event | events, event_tickets, events bucket | With image upload |

---

## 8. Auth Redirect URLs

Add your web app URLs in **Supabase Dashboard → Authentication → URL Configuration → Redirect URLs**:

- `http://localhost:5173/auth/callback` (local)
- `https://business.yourdomain.com/auth/callback` (production)

---

## 9. Quick Start Commands

```bash
npm create vite@latest habra-business-web -- --template react-ts
cd habra-business-web
npm install @supabase/supabase-js react-router-dom
```

Create `.env` with `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY`, then implement pages using the queries above.

---

## Related Documents

| Document | Purpose |
|----------|---------|
| [QA_CHECKLIST_BUSINESS_OWNER_V2.md](QA_CHECKLIST_BUSINESS_OWNER_V2.md) | Full QA checklist for business owner flow |
| [WEB_APP_BUSINESS_OWNER_IMPLEMENTATION.md](WEB_APP_BUSINESS_OWNER_IMPLEMENTATION.md) | Detailed design system, architecture, and setup |
| [WEB_APP_SETUP_AND_ARCHITECTURE.md](WEB_APP_SETUP_AND_ARCHITECTURE.md) | Project setup, folder structure, monorepo |

---

*Document version: 1.0 | Project: Habra | Mar 2025*
