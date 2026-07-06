# Three-Way Traceability Matrix

Website requirement ↔ Handoff specification ↔ Repository implementation.
(H:… = handoff path; R:… = repo path. Class codes as in 03.)

| # | Requirement | Website evidence | Handoff ref | Repository implementation | Class | Target PR |
|---|---|---|---|---|---|---|
| T01 | Email/password auth + OTP + forgot | login works on site | H:api/endpoint_status_matrix (VERIFIED) | R:features/auth/** (live-tested) | V-B | PR-6 hardening |
| T02 | Nafath identity login | not exposed on public site | H:03_ASSUMPTIONS (unknown payloads) | R:api_endpoints `@bodyPending`; R:docs/api/REAL_API_SPEC **contradicts** repo reality — reconcile | PB | PR-6 |
| T03 | Token refresh | n/a | H:matrix “PARTIAL — endpoint not implemented” | R:auth_interceptor + refresh Dio; route UNCONFIRMED | PB | PR-5 |
| T04 | Property catalog + filters | for-sale/for-rent pages, 78-page search | H:api/proposed-mobile-api.yaml | R:properties feature; Spatie params in `api_endpoints.dart` | V-B (envelope of filtered search PB) | PR-7 |
| T05 | Property details | slug pages | H:matrix VERIFIED | R:property_detail_* | V-B | PR-7 |
| T06 | Projects / off-plan | Explore Projects by Cities | H:matrix (stale “PARTIAL”) | R:home feature `/projects` LIVE | V-B (fix handoff) | PR-9 detail |
| T07 | Developers rail | Featured Developers | H:matrix | R:`/developers` LIVE | V-B | PR-9 profiles |
| T08 | Brokers rail | Top Real Estate Brokers tab | absent in handoff | R:`filter[user_type]=broker` (captured 2026-07-02) | V-B | PR-9 |
| T09 | City Intelligence buy/rent × apt/villa | live tables incl. SAR/mo | absent (params) | R:market feature; params+shapes captured | V-B | done; PR-10 extends |
| T10 | Market map + districts drill-down | Interactive Market map | H:architecture/data_flow (generic) | R:MarketMapCubit + `/market/districts` captured | V-B | PR-10 |
| T11 | Rental returns / trends / ROI | marketed on site | H:product/PRD (concepts) | none; no public endpoint | PB | PR-10 |
| T12 | Travel-time search (modes, peak) | site feature; `commute_time/from_area/to_area` in bundle | H:PRD | none | V-W+PB | PR-8 |
| T13 | Listings map view + clustering | site map experiences | H:mobile_architecture | none | V-W | PR-8 |
| T14 | Compare properties | brief lists; not directly observed this audit | H:use_cases | none | PB (verify on site first) | PR-7 |
| T15 | Contact/WhatsApp/lead ingestion | phone + WhatsApp CTAs | H:api leads (payload unknown) | data fields present; `leads/ingest @bodyPending` | PB | PR-7 |
| T16 | Consumer AI Search (text+voice) | AI Search page | H:ai/ai_search_spec + voice_search_spec | STUB screen; `/user/ai/*` uncaptured | PB/PA | PR-11 |
| T17 | AI Sales Agent (developer product) | “For Developers … BANT-grade” banner | H:ai/ai_sales_agent_spec (“aspirational”) | none | BLK (framework naming PA: BITEP vs BANT) | PR-12 |
| T18 | Subscriptions & entitlements | /get-started/plans | H:monetization/* (placeholders) | STUB; live API returns empty plans | BLK | PR-13 |
| T19 | List Property (seller flow) | site CTA | H:matrix PROPOSED | none; write bodies uncaptured | PB | post-PR-7 |
| T20 | AR/EN + RTL | full site parity | H:design notes | full l10n, RTL-safe layout | V-B | maintained |
| T21 | Dark/light theming | site toggle | H:design_tokens (WRONG palette) | site-calibrated tokens in code | V-B (handoff PD) | PR-14 audit |
| T22 | Analytics/observability | n/a | H:observability/* | Firebase wired; Amplitude/PostHog declared unwired | P | PR-14 |
| T23 | Security hardening (App Check, RASP, pinning) | n/a | H:security/threat_model | freerasp declared unwired; App Check unverified | P/PB | PR-14 |
| T24 | CI/CD + signing + stores | n/a | H:devops/*, stores/* | none in repo | P/BLK(signing) | PR-3/4/15 |
| T25 | Privacy/PDPL/consent | site cookie banner | H:security/pdpl_*, privacy_readiness | none | PL | PR-14/15 |
