# My Fitness Date — Apple OAuth, identity and canonical welcome

## Roles are independent of login providers
- `julio.villeda@live.com.mx` is the verified active owner in `app_private.brand_administrators`.
- `witchet43@gmail.com` is an existing confirmed member, **not** an administrator.
- `brand_admin_status()` and `brand_admin_session()` remain the authorization source; never infer administrative access from a provider, email or client metadata. Administrative access requires AAL2 (MFA).
- Using Google to sign in does not grant elevated privileges.

## Canonical welcome and logout
- All V26 build paths use `PublicEntryShell` as the sole public entry.
- `main.dart` does **not** launch the legacy `FitnessDateApp` when V26 is disabled.
- On logout, Supabase ends the session, the member state refreshes, and Navigator returns to the root route; previous member/admin pages may not remain navigable via Back.
- Hosted QA currently uses `https://landing-redesign.my-fitness-date.pages.dev/`; production `https://my-fitness-date.pages.dev/` is a separate Cloudflare branch and must not silently replace the preview.

## Apple Developer setup (must be performed in the owner's account)
Supabase hosted project: `jtrdvnwbxpfdnbzasvcj`.
1. Apple Developer > Certificates, Identifiers & Profiles: configure a **Services ID** for web sign-in and enable Sign in with Apple.
2. For its domain and return URL, use the registered web domain and the Supabase callback: `https://jtrdvnwbxpfdnbzasvcj.supabase.co/auth/v1/callback`.
3. Create a **Sign in with Apple** private key, record Team ID, Key ID, Services ID and create a short-lived client secret JWT per Apple's requirements. Never commit or send the `.p8` private key through a chat.
4. Configure those values in Supabase Dashboard > Authentication > Providers > Apple and enable the provider. Add exact target URLs to Authentication > URL Configuration > Redirect URLs, including `https://landing-redesign.my-fitness-date.pages.dev/**` for QA and `https://my-fitness-date.pages.dev/**` for production.
5. Confirm `GET /auth/v1/settings` (with publishable key) reports `external.apple=true`. The preview workflow then enables the Apple button during Flutter compilation.
6. Verify the full OAuth round trip in a real browser using a dedicated QA Apple ID, followed by logout and a fresh session. Verify that return stays on the **same preview hostname**, not the old production homepage.
7. Repeat for production only after independent release acceptance. Apple's OAuth client secret requires periodic renewal, typically every six months.

## Go/no-go
Do not claim Apple sign-in works until both hosted settings and real-user OAuth round trip pass. The system may expose the button visually while keeping it disabled until then. The broader FitDating release gates remain closed.
