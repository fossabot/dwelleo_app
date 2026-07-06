# Implementation Roadmap, Branch & PR Sequence, First Milestone

Long-lived: `main` (production) · `development` (integration). Release: `release/x.y.z`. Hotfix: `hotfix/*`.
All feature branches cut from `development`; one concern per PR; squash merge; protections per `docs/audit/07` immediate actions and the upgrade brief §8.

## Phased roadmap

| Phase | Goal | PRs | Exit criteria |
|---|---|---|---|
| 0 · Baseline (now) | Truthful docs + green tree everywhere | 1–2 | audit merged; analyze/test green on CI-less machines incl. maintainer Mac |
| 1 · Rails | Envs + CI + protections | 3–4 | PR pipeline red/green gates; dev/staging builds reproducible |
| 2 · Core | Session/network hardening + auth production | 5–6 | refresh/expiry/restore/logout verified; account deletion path |
| 3 · Marketplace | Filters, pagination, contact/leads, compare(if confirmed), map+travel time | 7–8 | parity rows in 03 flip to LIVE with tests |
| 4 · Ecosystem & insights | Partner profiles, project details, insights expansion | 9–10 | |
| 5 · AI & revenue | AI Search; then Agent + Subscriptions when unblocked | 11–13 | contracts captured; entitlements server-validated |
| 6 · Hardening & release | Security/privacy/analytics; integration suite; stores | 14–15 | store submissions accepted |

## PR sequence (dependency-aware)

1. **PR-1 `chore/handoff-audit-and-traceability`** — this branch. Docs only. *No code.*
2. **PR-2 `chore/quality-baseline`** — pin `geocoding:^4` **or** migrate `location_picker` (2 call sites) [ADR-lite in PR]; land remaining validated bumps; `analysis_options`: exclude `build/**`; gitignore local noise (scheme backups, swiftpm); remove unused `fl_chart` (or keep w/ justification); l10n missing-key check script. Acceptance: analyze 0 / tests green / maintainer-machine analyze noise gone.
3. **PR-3 `chore/flavors-and-environments`** — appId/bundleId suffixes, per-flavor Firebase strategy (files via CI, not repo), API base per env, logging levels, app names/icons per flavor.
4. **PR-4 `chore/ci-quality-gates`** — adopt+review handoff `devops/ci_workflow.yaml` + fastlane skeleton; PR pipeline (format/analyze/unit/widget), dev+staging builds, secret scanning, dependency review; protections + CODEOWNERS activation (needs repo admin).
5. **PR-5 `refactor/core-session-and-network`** — session manager extraction, refresh-route confirmation handling, standardized retry/backoff, error envelope alignment, auth-expired UX contract.
6. **PR-6 `feature/auth-production-readiness`** — logout invalidation, session restore, account deletion, role handling; OTP field names post-capture; Nafath only when confirmed.
7. **PR-7 `feature/marketplace-mobile-parity`** — filter sheets/chips/saved searches, filtered-search pagination (post-envelope capture), favorite write, contact actions + lead events, compare (if confirmed), showcase-card unification + partner-arrow site styling (carry-over UI debt).
8. **PR-8 `feature/map-and-travel-time`** — listings map + clustering, travel-time UX (post param semantics), permissions.
9. **PR-9 `feature/developers-brokers-projects`** — partner profile screens, project details page, agents (post-endpoint).
10. **PR-10 `feature/market-insights`** — trends/returns/forecast **only** with verified endpoints; extend tables/map.
11. **PR-11 `feature/ai-search`** — contracts, streaming UI, voice, quotas, fallback.
12. **PR-12 `feature/ai-sales-agent`** — BLOCKED until product+backend confirm (incl. BITEP/BANT naming).
13. **PR-13 `feature/subscriptions-and-entitlements`** — after plans/pricing + billing ADR.
14. **PR-14 `feature/observability-and-security`** — analytics taxonomy, consent, freerasp/App Check, redaction, a11y hardening.
15. **PR-15 `test/production-integration-suite` + release** — integration tests, store readiness, `release/1.0.0`.

## First safe implementation milestone (definition of done)

- PR-1 merged to `development` (docs only, zero risk).
- PR-2 merged: tree green (`analyze` 0, tests ≥50 green) with updated deps on **all** machines; Maps keys rotated (outside repo); protections enabled.
- Outcome: every later PR lands on a truthful, reproducible baseline.
