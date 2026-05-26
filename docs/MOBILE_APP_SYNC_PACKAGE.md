# Habra Mobile App – Shared Types & Endpoints

Copy this document’s contents into your mobile app to stay in sync with the web admin and Supabase schema.

---

## 1. Types (`lib/types.ts` or `types/index.ts`)

```typescript
export interface Profile {
  id: string;
  email?: string;
  full_name?: string;
  avatar_url?: string;
  /** App role. 'authenticated' is sometimes stored from Supabase Auth; app treats it as business owner. */
  role: 'user' | 'customer' | 'businessOwner' | 'admin' | 'authenticated';
  /** Set by super admin; when true, user can create businesses, add details, upload files. */
  business_verified?: boolean;
  verified_at?: string;
  verified_by?: string;
  created_at?: string;
  updated_at?: string;
}

export type BusinessApprovalStatus = 'pending' | 'approved' | 'rejected';

export interface Business {
  id: string;
  owner_id: string;
  name: string;
  description?: string;
  address_city?: string;
  address_street?: string;
  phone?: string;
  email?: string;
  website?: string;
  logo_url?: string;
  approval_status: BusinessApprovalStatus;
  is_active?: boolean;
  rating?: number;
  review_count?: number;
  created_at: string;
  updated_at?: string;
}

export type DealStatus = 'draft' | 'active' | 'expired' | 'inactive';

export interface Deal {
  id: string;
  business_id: string;
  title: string;
  description?: string;
  original_price?: number;
  discounted_price?: number;
  discount_percentage?: number;
  valid_from?: string;
  valid_until?: string;
  image_url?: string;
  category?: string;
  status: DealStatus;
  created_at?: string;
  updated_at?: string;
}

/** Common job type values (must match DB). */
export type JobType = 'full-time' | 'part-time' | 'contract' | 'temporary' | 'internship' | 'volunteer';

export interface Job {
  id: string;
  business_id: string;
  title: string;
  description?: string;
  location?: string;
  job_type?: JobType | string;
  salary_min?: number;
  salary_max?: number;
  posted_at: string;
  status?: string;
  is_active?: boolean;
  created_at?: string;
  updated_at?: string;
}

export interface Review {
  id: string;
  business_id: string;
  user_id: string;
  rating: number;
  comment?: string;
  reply_text?: string;
  replied_at?: string;
  created_at: string;
  updated_at?: string;
  profiles?: { full_name?: string; avatar_url?: string };
}

export type ApplicationStatus = 'pending' | 'reviewed' | 'shortlisted' | 'rejected' | 'hired';

export interface JobApplication {
  id: string;
  job_id: string;
  user_id: string;
  status: ApplicationStatus;
  cover_letter?: string;
  resume_url?: string;
  created_at: string;
  updated_at?: string;
  profiles?: { full_name?: string; email?: string; phone?: string };
  jobs?: { title?: string };
}

export interface BoostPlan {
  id: string;
  name: string;
  description?: string;
  duration_days: number;
  price?: number;
  is_active: boolean;
  created_at?: string;
}

export interface Boost {
  id: string;
  business_id: string;
  boost_plan_id: string;
  deal_id?: string;
  job_id?: string;
  starts_at: string;
  ends_at: string;
  status: string;
  created_at?: string;
  boost_plans?: BoostPlan;
  deals?: { title?: string };
  jobs?: { title?: string };
}
```

---

## 2. Table & Path Constants (`lib/endpoints.ts` or `lib/api/endpoints.ts`)

```typescript
/** Supabase table names (used with supabase.from(...)). */
export const tables = {
  profiles: 'profiles',
  businesses: 'businesses',
  deals: 'deals',
  jobs: 'jobs',
  reviews: 'reviews',
  jobApplications: 'job_applications',
  boostPlans: 'boost_plans',
  boosts: 'boosts',
} as const;

/** Paths for a custom REST API (if you add one). */
export const paths = {
  profiles: '/profiles',
  businesses: '/businesses',
  deals: '/deals',
  jobs: '/jobs',
  reviews: '/reviews',
  applicants: '/applicants',
  boosts: '/boosts',
} as const;
```

---

## 3. Enum Values Reference

| Column          | Table             | Values                                                                 |
|-----------------|-------------------|------------------------------------------------------------------------|
| `approval_status` | businesses      | `'pending'`, `'approved'`, `'rejected'`                               |
| `status`        | deals             | `'draft'`, `'active'`, `'expired'`, `'inactive'`                       |
| `job_type`      | jobs              | `'full-time'`, `'part-time'`, `'contract'`, `'temporary'`, `'internship'`, `'volunteer'` |
| `status`        | job_applications  | `'pending'`, `'reviewed'`, `'shortlisted'`, `'rejected'`, `'hired'`    |
| `category`      | deals             | `'food-drink'`, `'retail'`, `'services'`, `'entertainment'`, `'health-beauty'`, `'other'` |

---

## 4. Usage in Mobile

```typescript
// Example: Fetch jobs
const { data } = await supabase
  .from(tables.jobs)
  .select('*')
  .eq('business_id', businessId);

// Example: Type the response
const jobs = data as Job[];
```

---

## 5. Sync Checklist

When the web admin schema changes:

1. Update this document (or pull from web repo).
2. Copy the new types/endpoints into your mobile project.
3. Run any new migrations in Supabase (see `supabase/migrations/`).

---

*Source: Habra-Business-Admin-Site `src/types/index.ts` and `src/lib/api/endpoints.ts`*
