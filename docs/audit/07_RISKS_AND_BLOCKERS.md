# Risk Register & Blocker Map

## Risk register

| # | Risk | Prob. | Impact | Mitigation | Owner | Blocking? |
|---|---|---|---|---|---|---|
| R1 | Historical Maps API keys in git history abused | M | H | Rotate keys now; restrict by bundle/appId + API; add secret scanning (PR-4) | Hakem + Dwelleo infra | No (do immediately) |
| R2 | Uncommitted dep bumps break tree (geocoding 5) | Certain (observed) | M | PR-2: pin `geocoding:^4` or migrate 2 call sites; land bumps green | Eng | Yes for PR-2 |
| R3 | Backend contracts uncaptured (OTP/leads/subs/AI/write-side) | H | H | Backend capture session; update OpenAPI + `@bodyPending` removals | Dwelleo backend | Yes: PR-6/7(partial)/11/12/13 |
| R4 | Single-machine builds; no CI | H | H | PR-3/4 pipelines; fastlane; protections | Eng | Yes for release claims |
| R5 | Image delivery depends on dwelleo.sa `_next/image` | M | M | Keep raw-S3 fallback; ask Dwelleo for CDN/resize contract | Eng+Dwelleo | No |
| R6 | Subscriptions mis-modeled before pricing exists | M | H | Keep BLOCKED; ADR on store-vs-backend billing first | Product | Yes: PR-13 |
| R7 | AI Sales Agent scope drift (consumer/dev merge, framework naming) | M | M | Enforce split; resolve BITEP-vs-BANT (site says “BANT-grade”) | Product/AI | Yes: PR-12 |
| R8 | Committed `google-services.json` + config sprawl across flavors | M | M | Per-flavor Firebase config via CI-injected files; document | Eng | No |
| R9 | PDPL/store privacy claims unbacked | M | H | Legal review checklist (handoff seed); consent flow PR-14 | Legal | Yes: store submit |
| R10 | Handoff staleness misleads planning | Observed | M | This audit re-baselines; treat handoff as PROPOSED unless re-verified | Eng | No |
| R11 | `analysis_options` scans `build/` → devs ignore analyzer noise | Certain (observed) | M | PR-2 exclude; CI keeps truth | Eng | No |
| R12 | RTL/AR regressions as features grow | M | M | AR+RTL rows in widget tests; screenshot diffs in CI later | Eng/QA | No |

## Blocker map (dependency → what it unblocks)

- **Backend capture session** → OTP names → PR-6; leads payload + favorite-write + filtered-search envelope → PR-7; AI contracts → PR-11/12; subscription payloads → PR-13.
- **Business decisions** → plans & pricing (PR-13); BITEP/BANT + agent scope (PR-12); compare feature placement (PR-7 scope).
- **Assets/access** → Apple/Google dev accounts, signing, store listings (PR-15); GitHub protections/admin (PR-4); design tokens/Figma (PR-7+ UI debt); AI provider choice (PR-11/12).
- **Legal** → PDPL/consent/data-deletion sign-off (PR-14/15).

## Immediate no-regret actions (this week)

1. Rotate Google Maps keys; restrict them. 2. Merge PR-1 (this branch). 3. Land PR-2
(geocoding fix + analyzer exclude + validated bumps + gitignore noise). 4. Enable
GitHub protections + secret scanning + dependency review. 5. Book backend capture session.
