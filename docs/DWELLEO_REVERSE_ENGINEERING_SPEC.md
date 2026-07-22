# Dwelleo — Website → Flutter Reverse-Engineering Spec

**Owner:** Mohamed Hakem · **Reference:** dwelleo.sa · **Captured:** 2026-07-21
**Rule:** every number, endpoint and token below was verified live. Nothing here
is inferred. If something is unknown it says UNKNOWN — do not fill gaps by guessing.

---

## 0. The three root causes found this session

These are systemic — each one explains a whole class of "it looks wrong" bugs.

### 0.1 Arabic has no font → **the AR rendering bug**

`app_theme.dart` sets `fontFamily: 'RocGrotesk'` globally. RocGrotesk is a Latin
display face with **no Arabic glyphs**, so every Arabic string falls back to a
platform default — wrong weight, wrong metrics, inconsistent between iOS and
Android. This is almost certainly what "AR render false" refers to.

The website solves it explicitly:

```css
--font-roc-grotesk: "RocGrotesk-Regular", var(--font-tajawal), sans-serif;
```

**Fix:** ship **Tajawal** (Google Fonts, SIL OFL, free) and either
- set `fontFamilyFallback: ['Tajawal']` on the global text theme, or
- switch `fontFamily` by locale in `AppTheme` (`ar` → Tajawal, `en` → RocGrotesk).

Fallback is preferred: mixed AR/EN strings (very common here — "Makkiyoon - مكيون")
then render each script in its correct face inside one `Text`.

### 0.2 Our icon set is the wrong visual language

The site uses **Lucide** — confirmed from live DOM classes:
`lucide-calculator`, `lucide-moon`, `lucide-user-round`, `lucide-menu`,
`lucide-plus`, `lucide-chevron-down`, `lucide-phone`, `lucide-chart-line`,
`lucide-funnel`, `lucide-minus`.

Lucide is a 24×24, `stroke-width: 2`, round-cap/round-join **outline** set.
We are using Material's filled/rounded icons — a completely different weight and
personality. That mismatch is why the app's icons read as "low quality" beside
the site, not the icons themselves.

**Fix:** add the Lucide Flutter port and replace icons app-wide. This gives exact
parity with the website for free — no Figma needed, no hand-drawn SVGs.
Verify the current package name/version on pub.dev before adding
(`lucide_icons_flutter` at time of writing; confirm, don't assume).

### 0.3 Our dark palette is not the site's

| Token | Website | Ours |
|---|---|---|
| background | `#141414` | `#0A0A0A` (true black) |
| surface | `#1a1a1a` | — |
| sidebar | `#191919` | — |
| surface-alt | `#262626` | — |
| nav-active | `#393e23` | — |
| accent | `#d1f145` | `#D1F145` ✅ |
| muted text | `#a0a0a0` | — |
| toggle-off | `#444` | — |
| danger surface | `#311d1d` | — |

The accent matches exactly. Everything else does not: the site uses a **near-black
ladder** with four distinct elevation surfaces, we use flat true-black.

**DECISION NEEDED (owner):** you explicitly asked for true black earlier. The site
is `#141414`. Options: (a) adopt the site ladder for parity, (b) keep true black as
a deliberate mobile-native choice (OLED power saving is a real argument), or
(c) keep `#0A0A0A` background but adopt the `#1a1a1a`/`#262626` surface ladder for
cards — which is probably the best of both.

---

## 1. Verified API surface

Base: `https://api.dwelleo.sa/api/v1` · Header `Accept: application/json`.
**Localization is header-driven:** `Accept-Language: en|ar` works, `?locale=` is
ignored. `LocaleInterceptor` already sends this — verified present and wired.

### 1.1 Properties

| Endpoint | Notes |
|---|---|
| `GET /properties` | envelope `{message, data:{properties, pagination}}`; `pagination.total` = 3,995 |
| `GET /properties/{slug}` | detail; **publicly** ships `price_prediction`, `investment_scores`, `lifestyle_score`, `roi`, `project`, `spots` |

Filters (verified):
- `filter[listing_type]` = `for-sale` \| `for-rent`
- `filter[property_types][]=<id>` — **array syntax required**; comma-joined → 422
- `filter[city_id]`, `filter[area_id]`, `filter[developer_id]`, `filter[project_id]`
- `filter[bedrooms]`, `filter[bathrooms]`, `filter[min_price]`, `filter[max_price]`

**Type counts** (the site's strip) come from `pagination.total` with a type filter:
type 1 → **2,321**, type 2 → **926** — matches the website's printed numbers.

**`is_off_plan` / `off_plan` are NO-OPS.** All spellings return the unfiltered
3,995. The site's All / Off-plan / Ready tabs are **not** backed by this endpoint.
Off-plan inventory lives in `/projects` (which has a real `is_off_plan` field).

List payload carries `number_of_images` (photo-count badge), `area_sqm`,
`owner.phone` (per-card Call/WhatsApp), `furnishing_status`, `maid_room`.
It does **not** carry AI scores — those are detail-only.

### 1.2 Partners — three distinct sets

`GET /developers?filter[user_type]=<role>`, envelope `{data:{developers, pagination}}`:

| role | total |
|---|---|
| `developer` | 59 |
| `broker` | 116 |
| `agent` | 26 |

`GET /developers/{id}` → **404**. The site's developer page is SSR-rendered.
Build the profile from the list payload + verified sub-queries
(`filter[developer_id]` for listings, client-filtered `/projects` for projects).

**Site's developer Overview block** (screenshot): Projects Delivered, Cities
Covered, Ongoing Projects, Units Sold, plus bio and WhatsApp/Direct Contact.
Those counters are **not in any endpoint we can reach** — they come from SSR.
Do NOT invent them. Either omit, or derive only what's genuinely derivable
(e.g. project count from the filtered `/projects` list) and label it honestly.

### 1.3 Projects

`GET /projects` · `GET /projects/{id}` — **verified**, rich payload:
`amenities`, `key_features`, `overview_description`, `gallery`, `developer`,
`launch_date`, `expected_handover_date`, `location`, `classification`, `is_off_plan`.

### 1.4 Market — City Intelligence

`GET /market/cities`, `GET /market/districts?city_id=` with
`unit_type_id` (1 apartment, 2 villa) and `transaction_type=buy|rent`.
- buy → `price_of_meter` = **SAR per m²**
- rent → `monthly_price` = **absolute monthly**, NOT per m²

### 1.5 Market Insights — **found this session**

Namespace: `/market-insights/{insight_type}/...`. Only **`rental`** exists;
`sale` returns 404 (the site's Rent/Sale toggle has no Sale data live).

| Endpoint | Shape |
|---|---|
| `/market-insights/rental/lookups` | `regions`(13), `cities`(214), `unit_types`(7), `unit_purposes`(3), `years`(2019-2024) |
| `/market-insights/rental/top-cities-commercial-growth` | 15 × `{city, commercial_2020, commercial_2024}` |
| `/market-insights/rental/highest-commercial-growth-cities` | 10 × `{city, commercial_2020, commercial_2024}` |
| `/market-insights/rental/commercial-units-growth` | 13 × `{region, commercial_2020, commercial_2024}` |

Each response also returns `chart_type`, `name`, `description`, `filters_applied`
— **localized by `Accept-Language`**, so the chart titles come from the API and
must NOT be hardcoded in ARB.

**Math verified against the site:**
- growth % = `(v2024 - v2020) / v2020` → Riyadh 10.3→15.37 = **+49%**, exactly
  matching the website badge
- multiplier = `v2024 / v2020` → shown as `×1.5`
- header totals = sum across the returned rows (2020 total, 2024 total, overall growth)

### 1.6 Estimate — **no API exists**

`/estimates`, `/estimate`, `/shared-estimate`, `/valuations`, `/estimate/share`
→ 404 on GET and POST. The site's phone → WhatsApp → `?token=` flow runs through a
private backend route we cannot reach.

Submitting the site's wizard fires **no backend call** — only analytics. The
valuation is computed **client-side**. Our implementation does the same, over
verified `/market/districts` numbers:

```
mid  = area × district SAR/m²
low  = mid × 0.91      (exact ratio observed live)
high = mid × 1.07      (exact ratio observed live)
annual rent = district monthly × 12
net yield   = annual rent / sale price
```

Sample that pinned the formula: Riyadh · Al Amal Dist. · apartment · 180 m² →
7,747 SAR/m² → 1,394,400 mid / 1,268,904 low / 1,492,008 high.

**NOT implemented on purpose:** the site's "expected days to sell" (45–75 days).
One observed sample is not a model; fabricating a selling timeline for a seller
is the kind of invention that discredits the whole feature.

---

## 2. Screen-by-screen gap list

### 2.1 Property detail — MISSING
- **Location map** — site shows a Google map with POI pins. Detail payload has
  `location` + `spots`. We render neither.
- **Reviews** — "Leave a Review" ★×5 + 500-char comment + Submit. UNKNOWN whether
  a reviews endpoint exists — **probe before building**; if none, it's SSR-only
  and must not be faked.
- **AI Price Prediction chart** — we print the number only. The site renders a
  gradient range bar with the marker positioned between min/max, a
  `1100k … Predicted range … 1400k` axis, and a verdict sentence
  ("Price 4,727 SAR/sqm is 13% above predicted market price (4,174 SAR/sqm)").
  All inputs are already in `price_prediction` — this is pure UI work.
- **"Our AI rates this price"** band — EXCEPTIONAL / FAIR / MARKET / HIGH /
  OVERPRICED with a gradient rail, marker, and an assessment card. Maps to the
  existing `benchmark_level`.

### 2.2 Price Statistics — wrong feature entirely
Currently a wrapper around the City Intelligence table. The site's Market Insights
is a different page: hero, Filters, Rent/Sale toggle, three tabs
(Commercial Growth · Rental Contracts · Market Breakdown) and three chart types:
1. **Dumbbell/range chart** — 2020 dot (purple) → 2024 dot (lime), value + % badge
2. **Ranked gradient bars** — +% and ×multiplier, legend by growth tier
3. **Region cards** — units, colored progress bar, `base → current`, % badge

All backed by §1.5. Keep our City Intelligence table as a separate, still-valid
screen — it uses a different endpoint and is not a duplicate.

### 2.3 Estimate → Sarah handoff — dead button
"Discuss with Sarah" switches tabs and does nothing. Should open a **new
conversation pre-seeded** with the estimate (district, type, area, band) so Sarah
opens with context. The website's phone→WhatsApp flow is not reproducible (§1.6)
and is worse mobile UX anyway: the app already has the user.

### 2.4 Search fields — theming
Must use `AppColors.accentFor(brightness)` (lime dark / purple light) for focus
state, cursor and prefix icon. Currently neutral grey in both themes.

### 2.5 RTL audit — needs a real pass
Owner reports RTL "feels weak". Known-good: `EdgeInsetsDirectional` and
`PositionedDirectional` are used widely. Needs verifying per screen:
`TextAlign` vs `TextAlign.start`, `Row` ordering, chevron/arrow icon mirroring
(Lucide chevrons must flip in RTL), number formatting (Arabic-Indic vs Latin
digits — the site uses **Latin digits in Arabic**, confirm and match).

---

## 3. Execution order (highest proposal impact first)

1. **Design-system pass** — Tajawal + Lucide + surface ladder. One PR, touches
   every screen, fixes the whole "feels low quality" class of complaint. Do this
   first: everything after inherits it.
2. **Estimate → Sarah handoff** — kills the dead button, showcases the
   differentiator.
3. **Property detail** — prediction chart + price-rating band + location map.
   Highest-traffic screen; all data already in the payload.
4. **Market Insights** — new feature on §1.5, three real charts.
5. **Developer profile** — Overview block with only honest, derivable numbers.
6. **RTL + l10n audit** — systematic pass with the app in Arabic.

---

## 4. Standing rules for this codebase

- **Evidence law.** No endpoint, parameter, price or AI structure gets written
  from memory. Probe first; if it 404s, report it — never fake the UI.
- Architecture: presentation → domain → data. Cubits depend only on use cases.
  Domain has zero Flutter imports. Shared code (2+ uses) → `core/`.
- No Freezed, no build_runner. Dart 3 `sealed class` + pattern matching.
- Never `context.push()` a bottom-tab branch route — it duplicates the shell's
  page key and throws `!keyReservation.contains(key)` (red screen). Use `go()`.
- Secrets only via `--dart-define`; never in the repo.
- No commits without the owner's say-so.
