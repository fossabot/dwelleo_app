# Gap Analysis (18 categories → owning PR)

**Product** — Compare, List Property, contact/lead loop, insights beyond city/district stats, FAQ/contact/complaints content. → PR-7/9/10/14. Verify “Compare” placement on site before scoping.

**UI/UX** — Filters UI (bottom sheets + chips + saved searches), map/list toggle, property gallery, skeleton coverage on remaining screens, empty/offline states standardization, showcase-card unification for featured rail (open item from home review), partner arrow styling to site spec. → PR-7 + design debt list.

**Flutter architecture** — Extract session manager from interceptor; introduce cache layer decision (ADR); formalize per-screen state contract (loading/empty/offline/error/auth-expired). → PR-5.

**API integration** — Filtered-search envelope capture; write-side bodies (leads, user/properties, OTP names confirmed); error envelope standardization vs `DioClient._extractMessage`; retry/backoff policy. → PR-5/7 + capture session.

**Authentication** — Refresh route confirmation; logout invalidation; session restore edge cases; account deletion (store requirement); role-based UX (buyer/seller/…); Nafath after contracts. → PR-6.

**Marketplace** — Pagination on filtered search; filter UI; compare; save/heart toggle endpoint (favorite WRITE uncaptured — reads work); attribution polish. → PR-7.

**Maps & travel time** — Listings map + clustering; travel-time UX (modes, peak) pending param semantics; location permission flows; iOS `Info.plist`/Android manifest permission copy audit. → PR-8.

**AI Search** — Contracts, streaming, quotas, voice pipeline (`record` present), guardrails, fallback to classic search. → PR-11.

**AI Sales Agent** — Everything (BLOCKED): product confirmation, framework naming (BITEP vs site’s “BANT-grade”), backend, roles/permissions, CRM, auditability. → PR-12.

**Subscriptions** — Plans/pricing (API empty), store-billing decision ADR, receipt validation, entitlements, restore, retain-until-period-end semantics. → PR-13.

**Localisation** — AR copy review pass (native review), Arabic numerals policy, date/number locale audit (prices deliberately Latin like site — document), missing-key CI check. → PR-2 (check) / PR-14.

**Accessibility** — Semantics audit beyond nav (labels on icon-only actions, tap-target sizes, contrast in light mode lime-on-white CTAs, dynamic type stress pass, screen-reader order). → PR-14 + per-feature acceptance.

**Security** — Rotate historical Maps keys; secret scanning; decide on committed `google-services.json`; wire freerasp; App Check enforce; release log stripping (LoggingInterceptor audit); pinning ADR; deep-link validation. → PR-2 (rotation action) / PR-14.

**Privacy** — Consent flow (analytics off until consent), PDPL checklist with legal, data-deletion path, store privacy forms. → PR-14/15 + legal.

**Analytics** — Event taxonomy (handoff observability/metrics_catalog is a good seed), wire Amplitude/PostHog or remove, funnel events for leads/search/AI. → PR-14.

**QA** — Bloc tests for auth flows; widget tests for cards/filters in AR+RTL and dark/light; integration suite (auth, search, detail, contact, maps); device matrix runs; adopt handoff `qa/*` after re-baselining. → PR-4 seeds + test/production-integration-suite.

**DevOps** — Everything from zero: PR pipeline, dev/staging builds, release lanes, artifact retention, App Distribution; adopt+review handoff `devops/ci_workflow.yaml` + fastlane skeleton; branch protections + CODEOWNERS + secret scanning + dependency review. → PR-3/4.

**iOS release** — Signing assets/accounts, bundle IDs per flavor, privacy manifest + declarations, TestFlight lane, archive validation on macOS CI. → PR-15 (+PR-3).

**Android release** — Keystore mgmt via CI secrets, appId suffixes per flavor, AAB lane, Play internal track, Data Safety form, targetSdk/API-matrix verification. → PR-15 (+PR-3).
