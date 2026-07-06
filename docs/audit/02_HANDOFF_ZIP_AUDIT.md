# Handoff Package Audit — dwelleo_mobile_product_handoff.zip

87 files / 580K across: root index+summaries (6), `ai/` (8), `api/` (6), `architecture/` (8),
`backlog/`, `design/` (4), `devops/` (8 incl. fastlane + ci_workflow.yaml), `monetization/` (5),
`observability/` (3), `operations/` (2), `product/` (7), `qa/` (6), `reports/` (4, one report ×4 formats),
`repository_ready/` (5), `security/` (7), `stores/` (5).
Uploaded `final_report.pdf` is byte-identical (md5 `7aaa8980…`) to `reports/final_report.pdf` — one document.

## Quality assessment

**Strengths:** assumptions are explicitly marked as assumptions
(`03_ASSUMPTIONS_AND_OPEN_QUESTIONS.md` is exemplary); endpoint matrix carries
source evidence + status column; AI Sales Agent spec self-declares
“aspirational, not implemented”; security/QA/store checklists are broad and usable.

**Weaknesses:** portions are stale vs `development` HEAD; several UI facts are wrong;
some “evidence” citations reference chat-session artifacts (`【7†L21-L63】`) not
reproducible files.

## Staleness / factual errors (handoff → reality)

| Handoff claim | Reality (verified) | Action |
|---|---|---|
| “Unit, bloc and widget tests are missing” | 50 green tests at HEAD | Re-baseline QA plan on existing suite |
| “/projects … code not inspected / PARTIAL” | Projects fully implemented on live endpoint | Correct matrix row to VERIFIED |
| Design: brand “navy, green and neutral greys” | Sampled brand: **lime `#D1F145` + purple `#6B4FA0`** on near-black/white (`app_colors.dart`, site-calibrated) | `design_tokens.json` = PENDING_DESIGN_CONFIRMATION; do not apply |
| Market endpoints listed without params | Params captured live: `unit_type_id`, `transaction_type=buy|rent`, `heatmap=price`, districts `city_id`; buy/rent return different `filtered_stats` shapes | Merge captures into `proposed-mobile-api.yaml` |
| Brokers source unstated | `GET /developers?filter[user_type]=broker` (captured) | Add to endpoint matrix |

## Contradictions requiring resolution

1. **Auth identity** — repo doc `docs/api/REAL_API_SPEC.md` says email/password was
   “INVENTED; discard for Nafath”, while `HANDOFF_AUTH_FINISH.md`, the endpoint
   matrix and **live testing** prove email/password + OTP works in production.
   → Both true: email/password is real *today*; Nafath is planned. Reconcile repo
   docs in PR-1 follow-up; Nafath = PENDING_BACKEND_CONFIRMATION.
2. **Qualification framework** — upgrade brief mandates **BITEP**; the **live site
   banner says “qualifies leads to BANT-grade”**; the handoff names **neither**.
   → PENDING_AI_CONFIRMATION (question #2 to Dwelleo). No code impact yet (agent unbuilt).
3. **AI product split** — handoff keeps consumer AI Search and developer AI Sales
   Agent separate (correct, matches brief); ensure future work never merges them.

## Classification summary (per-item classifications live in 04_TRACEABILITY_MATRIX.md)

- VERIFIED_FROM_BOTH: catalog reads (properties/projects/developers/lookup), market stats, auth login/register/forgot, EN/AR + RTL, dark/light.
- VERIFIED_FROM_WEBSITE (unbuilt): advanced filters UI, compare, travel-time search (`filter[from_area]/[to_area]/[commute_time]` exist in web bundle), FAQ/contact/complaints/policies, List Property.
- PROPOSED (adoptable after review): `devops/ci_workflow.yaml`, fastlane skeleton, `repository_ready/*` (PR template, commit guidelines, gitignore, analysis_options), observability strategy, QA plans.
- PENDING_BACKEND_CONFIRMATION: OTP bodies, Nafath, leads, subscriptions payloads, AI contracts, refresh-token route, filtered-search envelope.
- PENDING_DESIGN_CONFIRMATION: design_tokens.json, screen_inventory gaps.
- PENDING_LEGAL_CONFIRMATION: PDPL checklist claims, store privacy declarations.
- BLOCKED: AI Sales Agent build (backend+product), subscriptions build (plans/pricing empty), signing/store submission (no accounts/assets in evidence).
