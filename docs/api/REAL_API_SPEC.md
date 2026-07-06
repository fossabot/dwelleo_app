# Dwelleo — Verified Real API Specification

> Source of truth for the Flutter data layer. Every entry marked **CONFIRMED** was
> observed directly from the live backend on 2026-06-25. Entries marked **PENDING**
> are not yet verified and **must not be guessed** — they will be captured from live
> network traffic (Chrome) or from official docs before any model is coded against them.

## Backend facts (CONFIRMED)

- **Base URL (production):** `https://api.dwelleo.sa`
- **Stack:** Laravel 11.51 / PHP 8.3 (confirmed via root response).
- **API prefix:** `/api/v1` (the bare `/api/...` prefix returns empty — wrong).
- **Reads are public:** property/project/developer/lookup lists return data with **no auth header**.
- **Media/asset host:** AWS S3 `https://dwelleo-app-eu-backend-storage-8j2gffse.s3.eu-west-1.amazonaws.com/{id}/{key}.{ext}`
  - Every image object is `{ id, path, path_thumbnail, mime_type }`. `path` and `path_thumbnail`
    are absolute S3 URLs. `mime_type` observed: `image/png`, `image/jpeg`.
- **Response envelope:** `{ "message": string|null, "data": object|array }`.
  - Some endpoints embed a `pagination` object; others (home/featured sets) do not. See per-endpoint notes.
- **Pagination object shape (CONFIRMED on /developers):**
  `{ "total": int, "count": int, "per_page": int, "current_page": int, "total_pages": int }`
  - `per_page` is **server-fixed at 20** — passing `?per_page=N` is **ignored**.
  - Page is selected with `?page=N` (standard Laravel; treat as CONFIRMED-by-convention, re-verify in traffic).

## Confirmed endpoints

### 1. GET `/api/v1/properties` — home / featured property set  **CONFIRMED**
- Returns `{ message, data: { properties: [Property] } }`.
- **No `pagination` key** on the bare call → this is the curated home set, not the search results.
- The paginated, filterable search (the `/en/properties/for-sale` page, 78 pages, type counts
  Apartment•528 / Villa•189 / Townhouse•13 / Penthouse•19 / Studio•5 / land•39 / office•5 / Roof•13 /
  shop•8 / building•23 / Floor•92 / Other•20) uses query params whose **names are PENDING** (see below).
- `?per_page` ignored. `?filter[property_type]=N` did **not** filter (returned mixed types) → wrong param name.

#### Property object (CONFIRMED fields)
```
id, slug, title, description,
owner: { id, name, phone, email, verified(bool), user_type, image{img}, lat, lng,
         cookie_consent, consent_timestamp },
is_favorite(bool), is_featured(bool), is_boosted(bool), map_priority,
image{img}, images: [img], property_video,
tags: [{ id, title, color, name, translations{ ar{name}, en{name} } }],
ai_tags,
location: { address, lat, lng, additional_contact, ad_license_number, direction,
            building_year, surrounding_streets },
region: { id, title, name, translations{ar,en} },
city:   { id, ai_id, region_id, title, slug, lat, lng, name, translations{ar,en} },
area:   { id, ai_id, city_id, title, lat, lng, name, translations{ar,en} },
area_sqm, bedrooms, bathrooms, driver_room, maid_room, floor_number, price,
number_of_images, has_slider,
listing_type: { key, label },          // key: "for-sale" | "for-rent" ; label is localized
property_type: { id, title, name, translations{ar,en} },
status,                                  // observed: "publish"
furnishing_status,                       // "unfurnished" | "partially_furnished" | "semi-furnished" | ...
availability, availability_status,       // availability_status observed: "available"
handover_date, distance, badge_status,
amenities: [{ id, title, image{img}, types, name, translations{ar,en} }],
types, land_type,                        // land_type observed: "residential"
compound, parking_space, commute_badge,
number_of_floors, number_of_flats, build_permit_floors, utility_availability,
has_pool, number_of_wells, number_of_entrances, fit_out,
number_of_offices, number_of_entrance_points, number_of_shops,
translations: { ar{ title, description }, en{ title, description } }
```
`img` = `{ id, path, path_thumbnail, mime_type }`.

#### Confirmed enum values (from live data)
- `listing_type.key`: `for-sale`, `for-rent`
- `owner.user_type` / property card role: `developer`, `broker`, `agent`, `individual_broker`
- `status`: `publish`
- `furnishing_status`: `unfurnished`, `partially_furnished`, `semi-furnished`
- `availability_status`: `available`
- `land_type`: `residential`

### 2. GET `/api/v1/projects` — off-plan / projects list  **CONFIRMED**
Returns `{ message, data: { projects: [Project] } }`.
```
Project: id, slug, image{img}, images:[img],
location_coordinates{lat,lng},
developer: { id, name, phone, whatsapp, image{img}, is_verified(bool) },
launch_date, is_off_plan(bool), expected_handover_date, location,
city: { id, ai_id, region_id, title, slug, lat, lng, name, translations{ar,en} },
amenities: [{ id, icon{img}, name, translations{ar,en} }],
overview_description, gallery, starting_price, is_favorite(bool),
seo: { meta_title, meta_description, meta_keywords, og_title, og_description, og_image,
       og_type, twitter_card, twitter_title, twitter_description, twitter_image,
       canonical_url, robots, structured_data },
name, description, translations{ ar{name,description}, en{name,description} }
```

### 3. GET `/api/v1/developers` — developers list  **CONFIRMED**
Returns `{ message, data: { developers: [Developer], pagination{...} } }`.
```
Developer (list item): id, name, image{img}, rating(number), featured(bool), featuredInHome(bool)
```
- `pagination`: total 49, count 20, per_page 20, total_pages 3 (observed). Use `?page=N`.

### 4. GET `/api/v1/lookup` — filter lookups  **CONFIRMED**
Returns `{ message, data: { amenities, property_types, tags, cities, areas } }`.
- `amenities[]`: `{ id, title, image{img}, types, name, translations{ar,en} }`
- `property_types[]`: `{ id, title, image{img}, types, name, translations{ar,en} }`
- `tags[]`, `cities[]`, `areas[]`: same translation pattern.
- Cache client-side (these change rarely).

### 5. GET `/api/v1/subscriptions` — subscription plans  **CONFIRMED (empty)**
Returns `{ message: "Subscription plans retrieved successfully", data: [] }`.
- Endpoint exists and is correct; currently returns no plans. Shape of a plan is **PENDING**
  (will appear when plans are populated, or capture from the `/get-started/plans` page traffic).

## How data is fetched (IMPORTANT)

The web app is **Next.js App Router with server-side rendering**. Property/project/developer
lists are fetched **on the Next.js server** (React Server Components) — there are **no
client-side XHR calls to api.dwelleo.sa** on page load (browser only loads images/analytics/maps).
The mobile app must call `api.dwelleo.sa` directly. CORS for browser origins is therefore not
guaranteed; use a native HTTP client (Dio), not browser fetch.

## Full real endpoint inventory (extracted from the production web bundle, 2026-06-25)

Every path below is a literal string the official web frontend calls. Methods are CONFIRMED
where observed; otherwise inferred (verify body before coding — see `@bodyPending` in code).

**Catalog (GET, public):**
`/properties`, `/properties/{slug}`, `/projects`, `/projects/{id}`, `/developers`,
`/developers/{id}`, `/developers/locations`, `/lookup`, `/testimonials`, `/subscriptions`

**Market insights (GET):** `/market/cities`, `/market/districts`

**Auth — NAFATH (Saudi national identity), NOT email/password:**
`/auth/nafath/initiate`, `/auth/nafath/status`, `/auth/nafath/complete`,
`/auth/register`, `/auth/consent`, `/auth/logout`
- Flow: initiate (returns a Nafath transaction/random number) → user approves in the Nafath app
  → poll `status` → `complete` issues the session/token. **Exact payloads PENDING** — capture
  during a real login. The old `auth/login` + email/password + OTP design was INVENTED; discard it.

**Profile (auth):** `/profile`, `/profile/change-password`

**Seller/user workspace (auth):** `/user/properties`, `/user/properties/{id}`, `/user/projects`,
`/user/ads`, `/user/ads/{id}`, `/user/subscriptions`, `/user/subscriptions/invoice`

**AI services (auth):** `/user/ai/health`, `/user/ai/apartment-prediction`,
`/user/ai/villa-prediction`, `/user/ai/rental-prediction`, `/user/ai/poi/categories`,
`/user/ai/poi/nearby`, `/user/ai/voice/conversations/process`

**Leads / contact / misc:** `/leads/ingest`, `/leads/ingest/batches`, `/contact-us`,
`/complains`, `/newsletter/subscribe`, `/subscribe`, `/upload`,
`/listings/generate-ai-content`, `/company-brief/document-templates`,
`/company-brief/price-lists`, `/audit/transitions`, `/pipeline/queue`

## Property search — real filter params (Spatie query builder, from the bundle)

The filterable search uses bracketed `filter[...]` params + `sort[...]` + `page`:

```
filter[listing_type]        for-sale | for-rent
filter[property_type]       (single id)        filter[property_types]   (multiple)
filter[unit_type]
filter[bedrooms]            filter[bathrooms]
filter[min_price]           filter[max_price]
filter[city_id]             filter[area_id]    filter[region_id]
filter[developer_id]        filter[project_id] filter[owner_id]
filter[amenities]
filter[furnishing_status]   filter[availability_status]
filter[is_favorite]         filter[is_featured]  filter[featured]  filter[featuredInHome]
filter[locations]           filter[from_area]   filter[to_area]    (travel-time search)
filter[min_handover_date]   filter[max_handover_date]
filter[commute_time]        filter[language_spoken]
sort[created_at]            page
```
Brackets must be URL-encoded (`filter%5Blisting_type%5D`).

> **RESOLVED 2026-07-06 (live probes, PR-7):** the FILTERED/PAGINATED search is
> `/properties` itself — sending `?page=N` switches it into search mode and the
> response gains `data.pagination {total, count, per_page:20 (fixed),
> current_page, total_pages}` (corpus at capture: 1,912 / 96 pages).
> CONFIRMED filters: `filter[listing_type]`, `filter[city_id]`,
> `filter[bedrooms]`, `filter[min_price]`, `filter[max_price]`, and
> `filter[property_types][]` — ARRAY syntax required (repeat the key per value;
> comma-joined returns HTTP 422 `{message, errors{field:[…]}}` localized).
> `filter[property_types][]=2` → 286 results, matching the site's Villa count.
> The singular `filter[property_type]` is accepted but DOES NOT FILTER — never send it.
>
> **Still PENDING:** exact **request bodies** for all POST endpoints (Nafath,
> leads/ingest, contact-us, complains, predictions, voice) — capture live.

## Localization
- Send `Accept-Language: ar` or `en`. Localized fields are delivered both as a resolved
  `name`/`title`/`label`/`description` **and** a full `translations{ar,en}` object — so the client
  can switch language without refetching. RTL applies for `ar`.
