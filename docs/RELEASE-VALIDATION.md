# Release validation checklist

Use this checklist for the isolated test environment and before each production release. Never use real student records for synthetic authorization tests.

## 1. Environment and secrets
- [ ] Confirm project reference, region, and environment label before every database action.
- [ ] Use a Supabase development branch or separate test project; production data must not be copied into ad hoc test fixtures.
- [ ] Store Supabase URL and publishable key in deployment environment settings; keep service-role keys server-only.
- [ ] Confirm backups and recovery procedure before a production schema change.

## 2. Database and RLS
- [ ] Apply migrations to the isolated database in order.
- [ ] Run `supabase/tests/rls_schema_assertions.sql` against the isolated database.
- [ ] Create synthetic School A and School B, with an admin, teacher, and ordinary member in each.
- [ ] Verify School A cannot select, insert, update, or delete School B records across every tenant-owned table.
- [ ] Verify ordinary members cannot add, alter, deactivate, or delete school membership records.
- [ ] Verify school admins can manage only their own school's memberships and cannot grant platform/super-admin roles.
- [ ] Verify platform-admin behavior using a dedicated test account.
- [ ] Verify inactive and removed members lose access, including through RPCs and existing sessions.
- [ ] Verify parents see only linked children and teachers only assigned classes/sections.
- [ ] Verify Storage buckets and object policies are tenant-scoped.
- [ ] Review all SECURITY DEFINER function bodies, fixed search paths, authorization checks, and EXECUTE grants individually.
- [ ] Preserve intended QR/PIN attendance flow while testing invalid, expired, replayed, and cross-school tokens.

## 3. Application
- [ ] TypeScript check and production build pass in CI.
- [ ] Unauthenticated users are redirected from protected routes.
- [ ] Authenticated users without an active school membership see a safe access-pending state.
- [ ] Teacher/staff accounts reach their intended routes; school admins reach the admin dashboard.
- [ ] Tenant identity is resolved from server-verified membership, never trusted from browser state or query parameters.
- [ ] Test admissions, attendance, fee collection/reconciliation, report cards, notices, and user management using synthetic data.
- [ ] Verify mobile layout, loading states, empty states, error states, and session expiry.

## 4. Deployment and release
- [ ] Verify the hosting project is connected to the intended repository and branch.
- [ ] Confirm environment variables, build command, output mode, domain, and HTTPS.
- [ ] Review deployment preview and run smoke tests before production promotion.
- [ ] Apply only reviewed, backward-compatible migrations after isolated validation and backup confirmation.
- [ ] Run post-deploy login, tenant-isolation, and core workflow smoke tests.
- [ ] Record commit SHA, migration versions, test evidence, release owner, and rollback steps.

## Current known blockers
- Production CRM still has the legacy broad `school_users_access` policy; do not treat the merged SQL migration as deployed.
- Several policies on `events`, `exam_marks`, `notices`, and `report_cards` currently target `public`; review and replace with authenticated-role policies in an isolated migration.
- Production RPC EXECUTE grants include broad roles for some SECURITY DEFINER functions. Validate each function's intended unauthenticated use before adjusting grants.
- No isolated Supabase branch is currently provisioned. Branch creation requires a cost estimate and confirmation.
- Hosting linkage and production deployment have not been verified.
