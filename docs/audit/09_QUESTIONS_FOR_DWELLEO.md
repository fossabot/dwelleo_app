# Questions Requiring Dwelleo Input

Only items that block verification or implementation. Each lists what it unblocks.

1. **Backend traffic-capture session** (highest value, ~2h with a backend engineer):
   confirm OTP body field names; filtered/paginated search envelope; favorite
   (save) write; `leads/ingest` payload; `user/properties` create/update;
   subscription endpoints; AI Search request/response (+streaming?); refresh-token
   route reality. → Unblocks PR-6, PR-7 (full), PR-11, PR-13.
2. **AI Sales Agent framework naming**: the live site banner says “BANT-grade”;
   the upgrade brief mandates **BITEP**. Which is the product’s official
   framework? → Unblocks PR-12 spec + copy.
3. **AI Sales Agent scope on mobile**: is a developer-facing companion app
   experience approved (roles/permissions/backend)? → Gate for PR-12.
4. **Subscription plans & pricing**: plan names, price points, free-plan limits,
   billing route (App Store/Play billing vs backend-managed for KSA) —
   `/subscriptions` currently returns an empty list. → Unblocks PR-13 + ADR.
5. **Store & signing assets**: Apple Developer + Play Console access, bundle
   IDs/appIds to reserve per flavor, signing strategy (who holds keys; CI
   secrets). → Unblocks PR-3 finalization and PR-15.
6. **GitHub administration**: enable protections/secret scanning/dependency
   review per audit `07`; confirm reviewers for CODEOWNERS (auth/payments/AI/security
   need 2 approvals). → Unblocks PR-4 enforcement.
7. **Design source of truth**: are official tokens/Figma available? Handoff
   `design_tokens.json` contradicts the shipped brand (navy/green vs lime/purple).
   → Unblocks design-debt items in PR-7+ (app continues with site-calibrated tokens meanwhile).
8. **Image delivery contract**: mobile currently uses the public
   `dwelleo.sa/_next/image` optimizer with S3 fallback — approve, or provide a
   CDN/resize endpoint for apps. → De-risks R5.
9. **Compare properties**: confirm where this lives on the current site (not
   observed during capture) so PR-7 scopes it correctly — or defer.
10. **Legal/PDPL**: contact for consent flow + privacy declarations review
    (Apple privacy manifest, Play Data Safety). → Gates PR-14/15 claims.
