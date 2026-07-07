# Dwelleo AI GitHub Repos — Alignment Audit (2026-07-07)

Audited on request: do these two repos align with dwelleo.sa and this app's
production plan (PR-11 `feature/ai-search`, PR-12 `feature/ai-sales-agent`)?

| Repo | Stack | What it is |
|---|---|---|
| `ahmedhamed1997/dwelleo-support-assistant` (master, 1 commit) | FastAPI + ChromaDB RAG + local sentence-transformers + **Google Gemini**; `/health`, `/chat`; tickets → local JSON | AI **customer-support** assistant PoC (KB Q&A + support-ticket collection) |
| `roaa-mamdouh/dwelleo-support-assistant` (main, 1 commit) | n8n AI-Agent + FastAPI + Postgres/pgvector hybrid RAG (RRF); tools: support ticket, refund, waitlist; static `X-API-Key`, localhost | AI **customer-support** assistant PoC — README calls Dwelleo "a fictional real-estate listings platform" |

## Verdict: NOT the AI Search / AI Sales Agent services — do not integrate

1. **They implement the *Support Assistant* track, not ours.** The handoff's
   `ai/support_assistant_spec.md` says it explicitly: *"A proof-of-concept
   exists in separate GitHub repositories (dwelleo-support-assistant), but
   integration into the mobile app is not yet implemented."* Both repos match
   that spec's shape (KB-grounded answers + ticket action), and look like two
   parallel candidate/PoC implementations of the same brief (1 commit each,
   "what I'd do with more time" sections, one self-describes Dwelleo as
   fictional).
2. **Zero contract value for our PENDING endpoints.** Neither repo calls
   `api.dwelleo.sa` nor implements any `/user/ai/*` route (predictions, POI,
   `voice/conversations/process`) — so `@bodyPending` stays PENDING; nothing
   here may be treated as a captured contract.
3. **Not production surfaces.** Localhost stacks, static API keys/local JSON
   persistence, third-party personal repos. Nothing to embed in a store build.
4. **Useful later, narrowly.** If Dwelleo green-lights an in-app *support
   chat* (separate from AI Search and the developer-facing Sales Agent), these
   PoCs are reference input for that future feature only.

## Bonus finding from the live site (`/en/ai-Sales`, captured 2026-07-07)

- **BITEP is now CONFIRMED on the website**: "5-Dimension Lead Scoring —
  BITEP framework: Budget, Intent, Timeline, Eligibility, Preferences." The
  earlier BANT-vs-BITEP conflict (PENDING_AI_CONFIRMATION) is resolved by the
  site itself; handoff and website now agree → use **BITEP** everywhere.
- Product map on the site: 01 AI Broker ("CURRENT PRODUCT"), 02 AI Sales
  Agent, 03 **AI Search Agent** ("Conversational property discovery in Arabic
  & English"), 04 Decision Engine. AI Sales page is a *marketing/demo-booking*
  page (Schedule Demo → external zbooking.us) — there is no in-page product
  API to capture, reinforcing that PR-12 remains blocked on backend contracts.

## Impact on the roadmap

- **PR-11 `feature/ai-search`** — proceeds now with the on-device interpreter
  over verified `/properties` + `/lookup` contracts (this branch); remote
  `/user/ai/*` adapter slots in after a backend capture session.
- **PR-12 `feature/ai-sales-agent`** — still BLOCKED for product surface
  (developer-facing; site page is marketing + external demo booking; no
  captured API). Naming unblocked: BITEP.
