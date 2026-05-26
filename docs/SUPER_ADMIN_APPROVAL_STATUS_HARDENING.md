# Super Admin Approval Status Hardening (Copy/Paste)

Use this guide on the super admin web app to prevent:

`invalid input value for enum business_approval_status: ""`

It gives you a drop-in implementation pattern and verification checklist.

---

## 1) Confirm DB enum and default

Run this in Supabase SQL editor:

```sql
-- 1) Verify enum values
select enumlabel
from pg_enum e
join pg_type t on t.oid = e.enumtypid
where t.typname = 'business_approval_status'
order by enumsortorder;

-- 2) Verify businesses.approval_status default
select column_default
from information_schema.columns
where table_schema = 'public'
  and table_name = 'businesses'
  and column_name = 'approval_status';
```

Expected:
- Enum values include exactly: `pending`, `approved`, `rejected`
- Column default is `pending`

---

## 2) Frontend constants + sanitizer (TypeScript)

Create `src/lib/businessApprovalStatus.ts`:

```ts
export const BUSINESS_APPROVAL_STATUSES = ['pending', 'approved', 'rejected'] as const;

export type BusinessApprovalStatus = (typeof BUSINESS_APPROVAL_STATUSES)[number];

export function normalizeBusinessApprovalStatus(
  value: unknown,
  opts?: { defaultWhenMissing?: BusinessApprovalStatus }
): BusinessApprovalStatus | undefined {
  if (typeof value !== 'string') return opts?.defaultWhenMissing;

  const normalized = value.trim().toLowerCase();
  if (!normalized) return opts?.defaultWhenMissing;

  if (
    BUSINESS_APPROVAL_STATUSES.includes(
      normalized as BusinessApprovalStatus
    )
  ) {
    return normalized as BusinessApprovalStatus;
  }

  return opts?.defaultWhenMissing;
}
```

Why this matters:
- Prevents empty string (`''`) from being sent
- Prevents invalid values (`"approve"`, `"APPROVE"`, etc.)
- Keeps payload values aligned with enum values

---

## 3) Safe update helpers (TypeScript + Supabase)

Create `src/features/businesses/api/updateBusinessApproval.ts`:

```ts
import { supabase } from '@/lib/supabase';
import {
  type BusinessApprovalStatus,
  normalizeBusinessApprovalStatus,
} from '@/lib/businessApprovalStatus';

type UpdateBusinessApprovalInput = {
  businessId: string;
  status: unknown;
  rejectionReason?: string;
  reviewerUserId: string;
};

export async function updateBusinessApproval({
  businessId,
  status,
  rejectionReason,
  reviewerUserId,
}: UpdateBusinessApprovalInput): Promise<void> {
  const safeStatus = normalizeBusinessApprovalStatus(status);
  if (!safeStatus) {
    throw new Error('Invalid approval status. Must be pending, approved, or rejected.');
  }

  const payload: Record<string, unknown> = {
    approval_status: safeStatus,
    reviewed_at: new Date().toISOString(),
    reviewed_by: reviewerUserId,
  };

  if (safeStatus === 'rejected') {
    const reason = (rejectionReason ?? '').trim();
    if (!reason) {
      throw new Error('Rejection reason is required when rejecting.');
    }
    payload.rejection_reason = reason;
  } else {
    // Clear stale reason if status moves away from rejected.
    payload.rejection_reason = null;
  }

  const { error } = await supabase
    .from('businesses')
    .update(payload)
    .eq('id', businessId);

  if (error) throw error;
}

export async function approveBusiness(
  businessId: string,
  reviewerUserId: string
): Promise<void> {
  return updateBusinessApproval({
    businessId,
    status: 'approved',
    reviewerUserId,
  });
}

export async function rejectBusiness(
  businessId: string,
  reviewerUserId: string,
  rejectionReason: string
): Promise<void> {
  return updateBusinessApproval({
    businessId,
    status: 'rejected',
    reviewerUserId,
    rejectionReason,
  });
}
```

---

## 4) UI mapping rules (important)

Do not bind raw labels directly to DB enum values.

Use explicit mapping:

```ts
const UI_TO_DB_STATUS: Record<string, BusinessApprovalStatus> = {
  pending: 'pending',
  approve: 'approved',
  approved: 'approved',
  reject: 'rejected',
  rejected: 'rejected',
};
```

Before update:
- Convert UI selection to DB value through this map
- Run `normalizeBusinessApprovalStatus(...)` after mapping
- If value is invalid, block submit and show validation message

---

## 5) Query patterns that should always be used

Pending queue:

```ts
const { data, error } = await supabase
  .from('businesses')
  .select('*')
  .eq('approval_status', 'pending')
  .order('created_at', { ascending: false });
```

Approved list:

```ts
const { data, error } = await supabase
  .from('businesses')
  .select('*')
  .eq('approval_status', 'approved')
  .order('created_at', { ascending: false });
```

Rejected list:

```ts
const { data, error } = await supabase
  .from('businesses')
  .select('*')
  .eq('approval_status', 'rejected')
  .order('created_at', { ascending: false });
```

---

## 6) RLS/config checks for admin app

Ensure:
- Admin users have `profiles.role = 'admin'`
- Admin RLS policy allows `UPDATE` on `public.businesses`
- Admin app uses anon key + authenticated admin user (not service_role in browser)
- Supabase project URL/key match the same environment where the enum exists

Quick auth sanity query (as signed-in admin in app):

```ts
const { data: me } = await supabase.auth.getUser();
const { data: profile } = await supabase
  .from('profiles')
  .select('id, role')
  .eq('id', me.user?.id ?? '')
  .single();
```

`profile.role` must be `admin`.

---

## 7) End-to-end test checklist

1. Create/register a new business owner + business (should be `pending`)
2. Open admin pending queue (`approval_status = 'pending'`)
3. Click Approve
4. Verify DB row now has:
   - `approval_status = 'approved'`
   - `reviewed_at` is not null
   - `reviewed_by` is admin user id
5. Approve/reject again from UI and confirm no enum errors
6. Confirm browser network payload never sends:
   - `approval_status: ""`
   - `approval_status: null` (unless field intentionally omitted)
   - invalid custom strings

---

## 8) Common root causes of the enum error

- Empty `<select>` default option with `value=""` submitted directly
- Form reset sets `approval_status` to empty string
- Label/value mismatch (sending `"Approve"` instead of `"approved"`)
- Status read from URL/query/local storage without sanitization
- Partial update payload includes `approval_status: ''` unintentionally

---

## 9) Minimal “safe submit” snippet

```ts
const rawStatus = formValues.approvalStatus; // unknown UI value
const safeStatus = normalizeBusinessApprovalStatus(rawStatus);

if (!safeStatus) {
  setError('approvalStatus', 'Please choose a valid status.');
  return;
}

await updateBusinessApproval({
  businessId,
  status: safeStatus,
  reviewerUserId: currentUserId,
  rejectionReason: formValues.rejectionReason,
});
```

---

If you already follow this guide and still get the same error, inspect the exact request payload in browser DevTools (Network tab) and verify `approval_status` is always one of:

- `pending`
- `approved`
- `rejected`
