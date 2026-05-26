# Habra Web Apps — Setup & Scalable Architecture

This document gives you **exact setup commands** to run inside each web app folder and a **scalable folder structure** so both apps can grow without turning into a mess.

Use this for:
- **Business owner web app** (e.g. `habra-business-web`)
- **Super admin web app** (e.g. `habra-admin-web`)

---

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Setup Commands (per app)](#2-setup-commands-per-app)
3. [Environment Files](#3-environment-files)
4. [Scalable Folder Structure](#4-scalable-folder-structure)
5. [Architecture Principles](#5-architecture-principles)
6. [Scripts & Tooling](#6-scripts--tooling)
7. [Optional: Monorepo with Shared Code](#7-optional-monorepo-with-shared-code)

---

## 1. Prerequisites

- **Node.js** 18+ (LTS recommended).
- **npm** (comes with Node) or **pnpm** (faster, recommended: `npm install -g pnpm`).
- **Supabase project** with Habra schema deployed; **Project URL** and **anon key** from Dashboard → Project Settings → API.

---

## 2. Setup Commands (per app)

Run these **inside the folder** where you want the app (create the folder first for option A).

### Option A: Create new project from scratch

**Business owner app:**

```bash
# Create app folder and Vite + React + TS project
npm create vite@latest habra-business-web -- --template react-ts
cd habra-business-web

# Install dependencies
npm install @supabase/supabase-js react-router-dom

# Optional: Tailwind for styling (recommended for consistent design system)
npm install -D tailwindcss postcss autoprefixer
npx tailwindcss init -p
```

**Admin app** (in a different folder):

```bash
npm create vite@latest habra-admin-web -- --template react-ts
cd habra-admin-web

npm install @supabase/supabase-js react-router-dom

# Optional: Tailwind
npm install -D tailwindcss postcss autoprefixer
npx tailwindcss init -p
```

### Option B: Using pnpm

```bash
pnpm create vite habra-business-web --template react-ts
cd habra-business-web
pnpm add @supabase/supabase-js react-router-dom
pnpm add -D tailwindcss postcss autoprefixer
npx tailwindcss init -p
```

### Verify

```bash
npm run dev
# or
pnpm dev
```

Open the URL shown (e.g. `http://localhost:5173`). You should see the Vite default page; we’ll replace it with the app structure next.

---

## 3. Environment Files

Create these files **in the project root** (e.g. `habra-business-web/` or `habra-admin-web/`). Do not commit real keys.

**`.env`** (local development; add to `.gitignore` if not already):

```env
VITE_SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co
VITE_SUPABASE_ANON_KEY=your_anon_key_here
```

**`.env.example`** (commit this; no real values):

```env
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your_anon_key
```

**Staging / production:** Use `.env.staging` and `.env.production` or your host’s env (Vercel, Netlify, etc.) with the same variable names. Point to the correct Supabase project per environment.

---

## 4. Scalable Folder Structure

Use this structure **inside `src/`** so the app stays scalable as you add features.

```
src/
├── app/                    # App shell & routing (top-level)
│   ├── App.tsx
│   ├── Router.tsx          # Route definitions + guards
│   └── RootLayout.tsx      # Layout with sidebar/nav
│
├── shared/                 # Shared across features (no Supabase here)
│   ├── components/         # Button, Card, Input, Badge, Spinner, Modal
│   ├── theme/              # Design tokens (colors, spacing, typography)
│   │   ├── tokens.css      # or tokens.ts
│   │   └── index.ts
│   ├── hooks/              # Generic hooks (useLocalStorage, useMediaQuery)
│   └── utils/              # formatDate, cn(), etc.
│
├── lib/                    # Infrastructure (Supabase, env)
│   ├── supabase.ts         # createClient(url, anonKey)
│   ├── env.ts              # Validate and export VITE_* vars
│   └── constants.ts        # App-wide constants (routes, storage keys)
│
├── features/               # Feature modules (by domain)
│   ├── auth/
│   │   ├── components/     # SignInForm, SignOutButton
│   │   ├── hooks/         # useAuth, useProfile, useSession
│   │   ├── guards/        # RequireAuth, RequireRole (businessOwner / admin)
│   │   └── types.ts
│   │
│   ├── dashboard/          # (Business: overview; Admin: counts)
│   │   ├── components/
│   │   ├── hooks/         # useDashboardStats
│   │   └── pages/
│   │
│   ├── businesses/         # (Business app: CRUD; Admin: list + approve)
│   │   ├── components/
│   │   ├── hooks/         # useBusinesses, useBusiness
│   │   ├── pages/
│   │   └── types.ts
│   │
│   ├── deals/
│   ├── jobs/
│   ├── reviews/
│   ├── applicants/         # (Business app)
│   ├── boosts/
│   │
│   ├── users/              # (Admin app only)
│   ├── content-moderation/ # (Admin: deals, events, jobs, reviews)
│   ├── boost-plans/        # (Admin: CRUD)
│   ├── audit-log/          # (Admin)
│   └── app-settings/       # (Admin)
│
├── pages/                  # Top-level route pages (thin; delegate to features)
│   ├── SignInPage.tsx
│   ├── DashboardPage.tsx
│   ├── BusinessesPage.tsx
│   └── ...
│
├── types/                  # Global TS types (Profile, DB row types)
│   ├── database.ts         # Supabase generated or hand-written
│   └── index.ts
│
├── main.tsx
└── index.css
```

### Why this scales

- **`app/`**: Single place for router and layout; easy to add middleware or error boundaries later.
- **`shared/`**: Reusable UI and theme only; no Supabase or feature logic. Safe to reuse across features.
- **`lib/`**: One Supabase client and env; no UI. Keeps infra in one place.
- **`features/`**: Each feature owns components, hooks, and pages. Add a new feature without touching others. Hooks do the Supabase calls; pages stay thin.
- **`pages/`**: Route entry points; they import from `features/` and `shared/`. You can merge `pages/` into `features/*/pages/` and route to them if you prefer.

### Dependency rules

- **shared** → nothing (no imports from features or lib).
- **lib** → nothing (no UI, no features).
- **features** → can use `shared`, `lib`, `types`.
- **app** / **pages** → use `shared`, `lib`, `features`, `types`.

---

## 5. Architecture Principles

1. **Single Supabase client**  
   Create the client once in `lib/supabase.ts`; import it everywhere. Use **anon key only**; RLS enforces access.

2. **Auth and role in one place**  
   `features/auth/` exposes `useAuth`, `useProfile`, `useSession`. Route guards (`RequireAuth`, `RequireRole`) use these. All protected routes go through the guard.

3. **Feature hooks own data**  
   Each feature has hooks like `useBusinesses()`, `useDeals(businessId)`. Hooks call `supabase.from(...)`. Pages and components use the hooks, not raw Supabase.

4. **Design tokens in shared/theme**  
   One file (CSS variables or TS) for colors, spacing, typography. Components in `shared/components` and feature components use these tokens so the app matches the Habra mobile look.

5. **Types from a single place**  
   `types/` (or generated from Supabase) for `Profile`, `Business`, `Deal`, etc. Use the same types in hooks and components.

6. **No cross-feature imports**  
   `features/deals` does not import from `features/jobs`. Shared code goes in `shared/` or `lib/`.

---

## 6. Scripts & Tooling

**`package.json` scripts** (add or adjust):

```json
{
  "scripts": {
    "dev": "vite",
    "build": "tsc -b && vite build",
    "preview": "vite preview",
    "lint": "eslint . --ext ts,tsx",
    "typecheck": "tsc --noEmit"
  }
}
```

**Recommended dev dependencies:**

```bash
npm install -D typescript @types/node eslint @typescript-eslint/eslint-plugin @typescript-eslint/parser
# If using Tailwind (see Option A/B above)
npm install -D tailwindcss postcss autoprefixer
```

**Tailwind config** (if used): point `content` at `./index.html` and `./src/**/*.{ts,tsx}`. In your CSS, add the Habra design tokens as Tailwind theme extensions or use CSS variables in `shared/theme/tokens.css`.

---

## 7. Optional: Monorepo with Shared Code

If you want **one repo** for both web apps and shared design/types:

### Structure

```
habra-web/
├── apps/
│   ├── business/          # Vite app (business owner)
│   └── admin/             # Vite app (admin)
├── packages/
│   └── shared/            # Design tokens, types, maybe shared components
│       ├── theme/
│       ├── types/
│       └── package.json   # "name": "@habra/shared"
├── package.json           # workspace root
└── pnpm-workspace.yaml
```

### Commands (pnpm workspace)

```bash
# Root
mkdir habra-web && cd habra-web
pnpm init

# Create workspace file
echo "packages:\n  - 'apps/*'\n  - 'packages/*'" > pnpm-workspace.yaml

# Apps
pnpm create vite apps/business --template react-ts
pnpm create vite apps/admin --template react-ts

# Shared package
mkdir -p packages/shared/src/theme packages/shared/src/types
cd packages/shared && pnpm init
# Set "name": "@habra/shared" in package.json

# From root: install deps in each app
cd ../..
pnpm install
pnpm add @supabase/supabase-js react-router-dom -F business -F admin
pnpm add @habra/shared -F business -F admin
```

In each app, import from `@habra/shared` for theme and types. Build the shared package (e.g. `tsup` or `tsc`) and reference it in the apps. This is optional; two separate repos with copied or manually synced tokens are fine too.

---

## Quick Reference: What to Run Where

| Step | Where | Command |
|------|--------|--------|
| Create business app | Parent folder | `npm create vite@latest habra-business-web -- --template react-ts` |
| Create admin app | Parent folder | `npm create vite@latest habra-admin-web -- --template react-ts` |
| Install deps | Inside each app root | `npm install @supabase/supabase-js react-router-dom` |
| Env | App root | Create `.env` and `.env.example` with `VITE_SUPABASE_*` |
| Dev server | App root | `npm run dev` |
| Build | App root | `npm run build` |

After this setup, use [WEB_APP_BUILD_PROMPTS.md](./WEB_APP_BUILD_PROMPTS.md) in each app folder to implement the full UI and Supabase integration with the structure above.
