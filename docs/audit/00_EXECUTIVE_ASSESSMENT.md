# Executive Technical Assessment — dwelleo_app Production Upgrade

Audit date: 2026-07-06 · Auditor: Principal Flutter Architect (AI-assisted) · Mode: AUDIT_AND_PLANNING
Sources: live dwelleo.sa (network-captured), repo `hakemm663/dwelleo_app` @ `development`, `dwelleo_mobile_product_handoff.zip` (87 files).

## Verdict

The repository is a **strong pre-production foundation, not a prototype**: feature-first
Clean Architecture with enforced layer purity, Cubit + get_it + Dio + go_router, a
**verified real API integration** (auth, properties, projects, developers, market
stats — captured from live traffic, not guessed), bilingual EN/AR with full RTL,
theme parity with the brand, and **50 passing tests** at `development` HEAD.

What separates it from production is a mix of **product-parity work and
engineering-infrastructure work**: no CI/CD, no tags/releases, branch protections
and rulesets were not verified, no fastlane, no signing pipeline, secrets hygiene
debt, unconfirmed backend contracts for every write-side flow (OTP bodies, leads,
subscriptions, AI), and store readiness work that has not started.

## Three headline risks

1. **Secrets**: Google Maps keys existed in git history (removed by commit
   `c5ab08c`, but history retains them) → keys must be **rotated**;
   `google-services.json` is committed as Firebase client configuration; Security Rules, App Check, API-key restrictions, and environment review are still required. Secret-scanning alert status and push protection were not verified.
2. **Contract debt**: all revenue- and growth-critical flows (subscriptions,
   leads, AI, OTP) are `@bodyPending`. Correctly not guessed — but they block
   PRs 6/11/12/13 until a backend capture session happens.
3. **Single-machine release process**: iOS/Android builds run only on the
   maintainer's Mac; no reproducible pipeline, no protected environments.

## Recommended path (summary)

PR-1 (this branch: audit docs only) → PR-2 quality baseline (geocoding fix,
analyzer excludes, validated dependency bumps) → PR-3 flavors/env → PR-4 CI
gates → PR-5 core session/networking hardening → PR-6 auth production
readiness → PR-7 marketplace parity → … per `08_ROADMAP_AND_PR_SEQUENCE.md`.

**First safe milestone:** PR-1 + PR-2 merged — a documented, traceable,
locally green tree on developer machines; PR-4 separately establishes CI-green acceptance.
