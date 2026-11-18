# Supabase backend integration

## State
Implemented in source control, **not deployed**. No Supabase project credentials have been provided. The Expo app runs with synthetic data without env settings. When env settings are provided, the **Dating** tab switches to Supabase sign-in and remote discovery.

## Setup (a development environment only)
1. Create a Supabase development project with Data API exposed schema set to **public** only. Never expose app_private.
2. Apply supabase/migrations/202610260001_private_dating.sql with the Supabase SQL editor or CLI in that project. Read/review the SQL before deployment.
3. Copy .env.example to .env and enter the project's URL and **publishable** (not secret/service_role) key. .env is gitignored. Expo variables are public inside the mobile app.
4. Run npm install then npm start. Create at least two **test-only** accounts and use clearly synthetic names; signup email confirmation may be required.
5. In Dating, sign in, declare age, fill in dating preferences, choose a synthetic gym, and explore results.

## Exposure model
- auth.users is owned by Supabase Auth.
- public.gyms is a read-only gym catalog; synthetic entries must be replaced before any beta.
- app_private.dating_profiles, app_private.training_slots and app_private.user_blocks have no direct client permissions and are intentionally outside exposed schemas.
- app_private.* SECURITY DEFINER functions are deliberately not exposed by the Data API and check auth.uid().
- public.* RPC wrappers are SECURITY INVOKER and callable only to authenticated role; they return the user's own settings or an allowed **safe card** (id/name/city/sports), without gym IDs or schedule.
- Dating consent is separate from being signed up to the application. Inactive users cannot discover or appear in candidates.
- The two server-side rules are reciprocal, with a 30-minute buffer. Same-gym matches require nonempty valid schedules for both profiles.

## Current limits: NOT PRODUCTION READY
- A user may self-report DOB but is **not identity/age verified**.
- The client currently lets editing one recurrent time interval on several days. API accepts up to 14 slots.
- Canonical gym list uses **synthetic data**. Gym chain vs branch identity needs policy.
- No rate limiting, abuse monitoring, chat, mutual likes, moderation, reporting, age-verification provider, profile photo controls, deletion/account export, or privacy-law review.
- An attacker may infer attributes by manipulating their own settings and observing recommendation changes. Add rate controls and risk assessment before beta.
- Supabase is not connected/deployed in this code change. GitHub Actions tests use a minimal PostgreSQL auth stub; test again in a real isolated Supabase project before public release.

## Automated validation
GitHub Actions runs TypeScript/unit tests plus a disposable PostgreSQL 16 instance. Bootstrap shims mimic auth.uid(), roles and auth.users for integration tests; never run bootstrap.sql on Supabase itself.

## API operations
- RPC save_dating_setup(...) — writes only own setup; rejects minors by DOB.
- RPC my_dating_setup() — returns only caller's private preferences.
- RPC discover_dating_candidates(p_limit) — eligible cards only; p_limit 1..30.
- RPC disable_dating() — hides user immediately while retaining account.
- RPC block_user(p_blocked_user_id) — unilateral block applies in both directions to candidate discovery.
