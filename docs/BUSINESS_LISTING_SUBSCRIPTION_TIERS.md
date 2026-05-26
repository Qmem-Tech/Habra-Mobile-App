# Business listing subscription tiers — product spec & implementation baseline

**Purpose:** Single reference for the **Free / Standard / Premium** listing model. **Prices are not documented here** — they are set in **Google Play / App Store** and **RevenueCat** (product SKUs, regional pricing). This doc is for features, limits, and engineering alignment.

**Status:** Product definition + gap analysis. **Not** a commitment that every line item is build-ready.

---

## What’s included vs not (mobile app — authoritative for gates)

These rows reflect **`BusinessSubscriptionPolicy`** and owner UI (Dashboard / Home). Names: **Free** = `basic`, **Standard** = `pro`, **Premium** = `premium`.

### Free (listing-only)

| Included | Not included |
|----------|----------------|
| Business listing profile (details that appear on explore/search when approved) | Posting **deals**, **hosted events**, or **job posts** (0 allowed; Dashboard Deals/Jobs/Events tabs show upgrade; Home quick actions open subscription) |
| Reviews tab (respond where product allows) | **Analytics** dashboard (locked like paid analytics; tier ≠ basic required for full analytics access pattern in app) |
| Hours, edit listing, photos (subject to global gallery cap today) | **Subscription “verified” badge** styling tied to paid tier (`canUseVerifiedBadge`) |
| | **Feed boost weight** (0 for Free) |

### Standard

| Included | Not included |
|----------|----------------|
| Everything Free includes **plus** posting deals, events, and jobs (within caps below) | “Unlimited” deals/events/jobs — caps apply |
| **Up to 5** concurrent **active** deals per business (`maxActiveDeals`) | Premium-only marketing extras (higher boost weight, de facto unlimited caps) |
| **Up to 5** concurrent **active** hosted events per business (`maxActiveEvents`) | |
| **Up to 5** concurrent **open** job posts per business (`maxActiveJobs`) | |
| **Analytics** access (tier ≠ basic) | |
| **Feed boost weight** = 1 | |

### Premium

| Included | Not included |
|----------|----------------|
| Same posting categories as Standard with **very high** effective caps (`9999` per category in app policy) | Truly unlimited at DB layer — still subject to abuse/fair-use elsewhere |
| Stronger **feed boost weight** (2) | Features listed in §6 still **not** promised (banners, Instagram, push quotas, etc.) |

---

## 1. Tier overview (commercial spec)

| Tier | Billing | Positioning (marketing) |
|------|---------|--------------------------|
| **Free** | No paid subscription | Basic presence to get discovered. |
| **Standard** | Paid (store + RevenueCat) | Visibility, credibility, and customer engagement. |
| **Premium** | Paid (store + RevenueCat) | Full marketing power and maximum exposure. |

---

## 2. Feature matrix (copy from product)

### Free

| Capability | Notes |
|------------|--------|
| Business name listing | Core listing identity. |
| Phone number | Contact on profile / cards. |
| Location (map integration) | Maps / geodata as supported by the app. |
| Appears in search results | Inclusion in explore/search surfaces (rules TBD). |
| Limited photos | **Quantify:** e.g. max N gallery images vs Standard/Premium (see §6). |

### Standard

| Capability | Notes |
|------------|--------|
| Higher visibility in category | **Requires:** ranking / boost rules in search API (not only client). |
| Up to 10 photos | **Conflict check:** app currently uses a **single global** gallery cap (see §5). |
| Full service/menu listing | **Requires:** menu/service model + UI if not already complete. |
| Customer reviews | Typically available to all listings that allow reviews; confirm if gated. |
| Call Now + Directions (priority placement) | **Requires:** ranking + CTA ordering in list/detail templates. |
| Promotions & deals section | Align with **active deals** limits (today: tier-based caps in app policy). |
| 1 push notification / month | **Requires:** marketing push pipeline + quota per listing (see §6). |

### Premium

| Capability | Notes |
|------------|--------|
| Top visibility in results (not fixed position) | Ranking weights; must not guarantee illegal “fixed #1.” |
| Verified **“Top Pick”** badge | Distinct from **listing verification** flow; branding + eligibility rules. |
| Unlimited photos & videos | **Requires:** media model (video hosting), storage cost, removal of hard caps. |
| Full service/menu listing | Same as Standard unless Premium adds sections. |
| Customer reviews | Same as Standard unless Premium adds moderation tools. |
| Priority Call & Directions | Stronger ranking signal than Standard. |
| Promotions with extra exposure | Deals + feed/boost weighting. |
| Homepage banner (shared placement) | **Requires:** CMS/slots + rotation; likely web + app hero contracts. |
| Multiple push notifications | Quota > Standard; exact count TBD. |
| Featured on Instagram | **Ops/marketing** process + consent; usually **not** automatic from app alone. |
| Event & concert promotion | Align with **events** product limits + visibility (see §5). |
| Priority support | Support routing / SLA — outside core app logic. |

---

## 3. Suggested mapping to internal identifiers

The codebase today uses **`BusinessSubscriptionTier`**: `basic` | `pro` | `premium` (see `lib/core/subscription/business_subscription_tier.dart`). RevenueCat resolves tier partly by **product / entitlement id strings** containing `pro` or `premium`.

**Recommended alignment for new product naming:**

| Commercial name | Suggested internal enum | RevenueCat / store notes |
|-------------------|-------------------------|---------------------------|
| Free | `basic` (or rename to `free` in a future refactor) | No paid subscription SKU; absence of paid entitlement. |
| Standard | `pro` | Subscription product id(s) and price configured in Play Console / App Store Connect + RevenueCat. |
| Premium | `premium` | Subscription product id(s) and price configured in Play Console / App Store Connect + RevenueCat. |

**Action for implementation phase:** Confirm whether to **rename** enums/display strings for clarity (`free`/`standard`/`premium`) vs keep `basic`/`pro`/`premium` internally.

---

## 4. What the mobile app enforces today (baseline)

This is **current behavior** — not the full marketing target in §2.

| Area | Current behavior (summary) |
|------|----------------------------|
| **Subscription gate** | `BusinessSubscriptionConfig`: when mode is `revenuecat`, owner **Dashboard / Boosts** require active RevenueCat entitlement (`REVENUECAT_BUSINESS_ENTITLEMENT_ID`, default `business_owner_tools`). Mode `off` disables the paywall. |
| **Free listing vs posting** | `canPostDealsEventsJobs`: **false** for `basic`, **true** for `pro` / `premium`. Free tier: Dashboard **Deals / Jobs / Events** tabs show **locked** state + **View plans**; FAB hidden; create flows and Home quick actions (**Post Deal / Post Job / Event**) open subscription. |
| **Deals** | `maxActiveDeals`: basic **0**, pro **5**, premium **9999** (active deals per business). |
| **Events** | `maxActiveEvents`: basic **0**, pro **5**, premium **9999** (active window per business; see create-event query). |
| **Jobs** | `maxActiveJobs`: basic **0**, pro **5**, premium **9999** (open jobs per business; enforced on publish in `CreateJobPostPage`). |
| **Analytics** | `canAccessAnalytics`: allowed if tier ≠ basic. |
| **Verified badge (subscription)** | `canUseVerifiedBadge`: tier ≠ basic — **separate** from listing “verified/pending” status in UI. |
| **Feed boost weight** | Numeric weight by tier (basic 0, pro 1, premium 2). |
| **Gallery photos** | **`BusinessMediaLimits.maxGalleryImages = 5`** for **all** tiers globally — **not** tier-specific (10 / unlimited) yet. |
| **Pricing** | **Not** in this repo — **Play / App Store listings + RevenueCat** are source of truth for amounts and regions. |

**Stripe:** Used for **event ticket checkout**, not for these listing tiers.

---

## 5. Gap analysis — spec vs current app

Legend: **Done** (partially or fully) · **Partial** · **Missing** · **External**

| Spec item | Status vs codebase |
|-----------|-------------------|
| Free: name, phone, location, search | **Partial** — listing flows exist; **search ranking by tier** not fully described in client. |
| Free: limited photos | **Partial** — limit exists (**5** gallery) but **same cap for all tiers**, not “limited vs 10 vs unlimited.” |
| Standard: higher visibility in category | **Missing** as explicit ranking — needs **backend search/index** + experiments. |
| Standard: up to 10 photos | **Missing** — cap is **5** everywhere. |
| Standard: full service/menu | **Unknown** — depends on product/schema; confirm menu feature completeness. |
| Standard: customer reviews | **Done** broadly — reviews exist; **gating by tier** not reflected in policy. |
| Standard: Call + Directions priority | **Partial** — CTAs exist; **priority placement** = ranking product. |
| Standard: promotions & deals | **Partial** — deals exist; limits **differ** from spec if Standard should allow other than **5** active. |
| Standard: 1 push / month | **Missing** — no per-tier marketing push quota in app (FCM exists for transactional/notifications). |
| Premium: Top Pick badge | **Partial** — `isVerified` / icons exist; **“Top Pick”** as premium-only badge not implemented as named feature. |
| Premium: unlimited photos & videos | **Missing** — **5** photo cap; **video** in gallery not part of this cap model. |
| Premium: homepage banner | **Missing** in mobile scope as described — likely **web CMS + app home module**. |
| Premium: multiple pushes | **Missing** — quota system. |
| Premium: Instagram | **External** — operational; app can surface **links** or admin workflow. |
| Premium: event & concert promotion | **Partial** — events feature + tier limits; **“promotion”** visibility is product/marketing. |
| Premium: priority support | **External** — Zendesk/email routing. |

---

## 6. What is explicitly **not** included (unless added later)

These are **out of scope** for a minimal “implement the table” pass unless you add requirements:

1. **Exact search ranking formulas** (category boost, distance, paid tier weights, freshness).
2. **Legal/compliance** for “top visibility,” **advertising disclosures**, and lottery-style placement claims.
3. **Instagram featured** as an automated entitlement (typically manual + brand approvals).
4. **Homepage banner** creative rotation, A/B testing, and **shared placement** fairness rules.
5. **Video hosting** costs, transcoding, moderation, and limits.
6. **Push marketing** vs **transactional** push (OS permissions, frequency caps, unsubscribe).
7. **Support SLAs** (“priority support”).
8. **Cross-platform sync** of tier (Supabase `businesses.subscription_tier` vs RevenueCat as source of truth) — **must** be decided before scaling.

---

## 7. Implementation planning checklist (for follow-up PRs)

Use this as a backlog; order by dependency.

- [ ] **Source of truth:** RevenueCat webhook → Supabase `businesses` (tier, status, period end) vs client-only.
- [ ] **Rename / map** commercial tiers to internal enums and RevenueCat product ids.
- [ ] **Photo limits:** Replace global `5` with tier-based limits (Free < Standard 10 < Premium unlimited); video policy.
- [ ] **Search & feed:** Server-side ranking weights per tier; optional A/B.
- [ ] **Badges:** Define **Top Pick** vs **Verified listing** vs subscription badge; UI + eligibility.
- [ ] **Push quotas:** Admin-defined monthly sends per tier; audit log.
- [ ] **Pricing:** Wire Store SKUs and RevenueCat offerings (amounts and regions per store policies).
- [ ] **Analytics:** Track funnel Free → Standard → Premium; feature usage by tier.
- [ ] **Docs:** Update `BUSINESS_OWNER_SUBSCRIPTION_CHECKLIST.md` and onboarding copy when gates change.

---

## 8. Related code references

| Topic | Location |
|-------|----------|
| Tier enum | `lib/core/subscription/business_subscription_tier.dart` |
| Policy (deals, events, analytics, badge, boost) | `lib/core/subscription/business_subscription_policy.dart` |
| Feature flags & RevenueCat ids | `lib/core/config/business_subscription_config.dart`, `app_config.dart` |
| Owner paywall / Dashboard gate | `lib/core/navigation/business_owner_navigation_wrapper.dart`, `BusinessOwnerSubscriptionCubit` |
| RevenueCat integration | `lib/core/services/revenue_cat_service.dart` |
| Gallery hard cap (today) | `lib/core/constants/business_media_limits.dart` |

---

*Last updated: planning doc for Free / Standard / Premium listing subscription. Adjust features as product decides; pricing remains in stores + RevenueCat.*
