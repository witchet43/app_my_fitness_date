# Fitted — Experience, locale and explainable compatibility v1

## Naming and visual system
- **Fitted** is a working name, not legally or commercially finalized.
- The existing **Diseñador de Marca** controls the brand's displayed name, typography, approved logo and palette globally. Do not hardcode `Fitted` as an immutable product name.
- The default editorial palette is midnight teal `#101B21`, champagne `#D5BE8A`, sage `#9FB5A9`, ivory `#F4F0E8`; no red heart motifs.
- Messaging: **people in motion**, training, recovery, intentional routines, authentic lifestyle alignment and serious relationships.
- Existing brand settings in Supabase take precedence over application defaults; owners can update the live identity only after backend owner-role and MFA verification.

## Language model
- Supported initial locales: `es`, `en`, selected per authenticated user and stored as `user_metadata.preferred_language`. Never use this metadata for access control.
- The welcome, legal action labels and global navigation start the bilingual migration. All remaining static strings require catalog extraction, interpolation, plural rules, language QA and accessible labels before claiming 100% multilingual readiness.
- User language and partner language are independent. An AI match explanation must render in the **requesting viewer's** locale, not leak the other person's preference.

## Compatibility is not linear
Scoring configuration v1 is a set of **six bounded factors**, total weight exactly 100:
- Intent (25), lifestyle (20), training rhythm (20), recovery (15), autonomy (10) and complementary sports (10).
- Zero weight disables a factor. Input fields must be known validated enumerations; absent/insufficient evidence cannot produce a percentage.
- The same sport gives a factor score of 100, a different sport 75: different disciplines are **not** a rejection. Shared values and intentions may dominate.
- The percentage is a deterministic weighted average of available evidence, coverage threshold 70%, rounded to an integer. `fitted-compatibility-v1` identifies the ruleset.
- Example fixtures (not real user data): a runner and a strength athlete with aligned lifestyles can score higher than two runners whose priorities and intentions differ.
- The engine emits evidence codes; translations render non-sensitive explanations. No raw DOB, precise location, training venue, private schedule or intimate behavioral inference is sent to an external AI provider.

## Administrator panel
- **Diseñador de Marca**: live global branding and history.
- **Calculadora del match**: synthetic cross-sport scenarios; adjustable weights; optimistic versioning, owner/AAL2 authorization and audit of proposed changes.
- Migration `202611140025_fitted_match_policy_v1.sql` provides dedicated private policy storage, version validation and audit. It has not been applied to the hosted environment as part of this UI change.
- Admin policy saves do not auto-activate dating or change an existing user's eligibility.

## AI explanation and governance, separate from the score
- Phase A: use deterministic, tested score and evidence-code translations; no API key required.
- Phase B, once a restricted server-side OpenAI integration is enabled: generate a short, bilingual **wording only** from the fixed score, disclosed reason codes and algorithm version. Require structured JSON, no unsupported claims, no new personal facts; keep a deterministic fallback.
- Phase C: offer suggested weight configurations based on consented aggregate evaluation, tested offline for disparate impact and drift. Each candidate configuration requires an explicit MFA owner approval and a new immutable policy version. Never let the model silently change global weights.
- Log policy/version, anonymized evaluation metrics, model version, safety failures and override actions. Do not log private member answers or generated personal inferences.

## Server release gate
- Hosted Supabase migration inventory must include B11 `202611120024` before actual personalized recommendations or percentage display is enabled. The current hosted project had not applied B11 during this work.
- Independent age and consent, block/suspension filtering, user privacy settings, abuse throttles, audit and safety approvals remain mandatory.
- Do not treat a candidate compatibility score as a mutual match. A mutual match is created **only after explicit, independent interest from both sides**.
- Do not ship matching to real users on the strength of Flutter simulator tests.

## Acceptance criteria still pending
- Complete ES/EN localization across all member/admin screens; persist language across devices.
- Deploy/audit server policy; implement an authorized server-side scoring endpoint fed by private owner-consented answers; version and evaluate scores.
- Independently review AI wording, privacy, fairness and age/consent gates.
- Validate a real two-account scenario with different sports, changing weights, observable policy version, no sensitive data exposure and actual reciprocal interest.
