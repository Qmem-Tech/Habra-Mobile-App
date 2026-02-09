# Documentation Index

Welcome to the Habra Mobile App documentation! This folder contains all documentation files for the project.

## 📚 Documentation Files

### Getting Started
- **[SETUP_GUIDE.md](./SETUP_GUIDE.md)** - Detailed setup instructions for the project
- **[SETUP_CHECKLIST.md](./SETUP_CHECKLIST.md)** - Checklist for project setup and verification

### Architecture & Design
- **[ARCHITECTURE.md](./ARCHITECTURE.md)** - Clean Architecture overview and principles
- **[NAMING_CONVENTIONS.md](./NAMING_CONVENTIONS.md)** - Code naming conventions and standards
- **[DEVELOPMENT_RULES.md](./DEVELOPMENT_RULES.md)** - App development general rules we must always follow (e.g. who runs commands)

### Backend
- **[SUPABASE_BACKEND_DESIGN.md](./SUPABASE_BACKEND_DESIGN.md)** - Supabase backend design: schema, RLS, user flows (Community + Business Owner + Admin), migration, and implementation phases
- **[SUPABASE_BACKEND_BUILD_GUIDE.md](./SUPABASE_BACKEND_BUILD_GUIDE.md)** - Step-by-step backend build: project setup, migrations, RLS, Auth, Storage, Edge Functions, and testing
- **[supabase/habra_full_schema.sql](./supabase/habra_full_schema.sql)** - Single copy-paste SQL file: full schema, RLS, triggers (run in Supabase SQL Editor **once**)
- **[supabase/habra_teardown_schema.sql](./supabase/habra_teardown_schema.sql)** - Reset script: drops all Habra tables/functions/enums so you can run the full schema again (use if you ran the schema twice or need a clean slate)
- **[supabase/HABRA_SUPABASE_CONFIG.md](./supabase/HABRA_SUPABASE_CONFIG.md)** - Dashboard configuration after running schema: Auth, redirect URLs, Storage buckets, first admin; what to do if you ran the schema twice
- **[supabase/habra_seed.sql](./supabase/habra_seed.sql)** - Optional seed: categories, boost_plans, app_settings (run in SQL Editor after schema)
- **[supabase/habra_seed_data.json](./supabase/habra_seed_data.json)** - Same seed data in JSON (reference or for scripts)
- **[SUPABASE_CLIENT_INTEGRATION_GUIDE.md](./SUPABASE_CLIENT_INTEGRATION_GUIDE.md)** - Integrating the Supabase backend with the Flutter mobile app and business owner / super admin web apps
- **[SUPABASE_STAGING_AND_PRODUCTION_GUIDE.md](./SUPABASE_STAGING_AND_PRODUCTION_GUIDE.md)** - Staging and production environment setup: two Supabase projects, app config per environment, workflow, and testing
- **[WEB_APP_BUSINESS_OWNER_IMPLEMENTATION.md](./WEB_APP_BUSINESS_OWNER_IMPLEMENTATION.md)** - Business owner web app: theme/UI aligned to mobile, end-to-end Supabase integration (Auth, businesses, deals, jobs, reviews, applicants, boosts, Storage)
- **[WEB_APP_ADMIN_IMPLEMENTATION.md](./WEB_APP_ADMIN_IMPLEMENTATION.md)** - Super admin web app: theme/UI aligned to mobile, end-to-end Supabase integration (users, business approval, content moderation, boost plans, audit log, app settings)
- **[FIREBASE_BACKEND_DEVELOPMENT_GUIDE.md](./FIREBASE_BACKEND_DEVELOPMENT_GUIDE.md)** - Firebase backend setup (current/auth); see Supabase doc for migration path

### Implementation Guides
- **[APP_IMPLEMENTATION_GUIDE.md](./APP_IMPLEMENTATION_GUIDE.md)** - Comprehensive implementation guide for all features (Customer, Business Owner, Admin)
- **[HOME_FEATURE_IMPLEMENTATION.md](./HOME_FEATURE_IMPLEMENTATION.md)** - Home feature implementation details
- **[IMPLEMENTATION_SUMMARY.md](./IMPLEMENTATION_SUMMARY.md)** - Quick summary of implemented features

### Assets & Resources
- **[ASSETS_GUIDE.md](./ASSETS_GUIDE.md)** - Guide for managing assets (images, icons, etc.)
- **[ASSET_PATHS_QUICK_REFERENCE.md](./ASSET_PATHS_QUICK_REFERENCE.md)** - Quick reference for asset paths
- **[APP_ICONS_GUIDE.md](./APP_ICONS_GUIDE.md)** - App icon generation and usage guide

### Maintenance & Updates
- **[UPDATE_GUIDE.md](./UPDATE_GUIDE.md)** - Guide for updating dependencies and packages
- **[SDK_VERSIONING_GUIDE.md](./SDK_VERSIONING_GUIDE.md)** - SDK versioning and compatibility guide
- **[APP_SIZE_OPTIMIZATION.md](./APP_SIZE_OPTIMIZATION.md)** - App size optimization tips and techniques

### Status & Progress
- **[UI_UX_STATUS.md](./UI_UX_STATUS.md)** - UI/UX implementation status

## 📖 Quick Links

- [Main README](../README.md) - Project overview and quick start
- [Architecture Details](./ARCHITECTURE.md) - Deep dive into architecture
- [Setup Instructions](./SETUP_GUIDE.md) - Step-by-step setup
- [Implementation Guide](./APP_IMPLEMENTATION_GUIDE.md) - Full feature implementation roadmap

## 📝 Document Maintenance

All documentation files are maintained by the development team. If you find any discrepancies or need to update documentation, please:
1. Update the relevant markdown file
2. Update the last modified date in the document
3. Notify the team of significant changes

---

**Last Updated**: 2024
