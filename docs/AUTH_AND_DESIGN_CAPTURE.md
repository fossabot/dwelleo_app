# Dwelleo — Auth + Design Capture (from the LIVE site) for VS Code Opus

> Captured directly from dwelleo.sa via browser inspection (the cowork agent is
> connected to the site; VS Code is not). Everything here is REAL — do not guess.
> Append to / pair with `docs/HANDOFF_PROMPT_FOR_VSCODE.md` and
> `docs/api/REAL_API_SPEC.md`.

## 1) Auth API contracts (REAL)

### Email/password login — CONFIRMED live
```
POST  https://api.dwelleo.sa/api/v1/auth/login
Headers: Content-Type: application/json, Accept: application/json,
         Accept-Language: en|ar
Body:   { "email": "<email>", "password": "<password>" }
```
- Response is the standard envelope `{ "message": ..., "data": { ... } }`.
- **Confirm on a real login** (dummy creds get rate-limited/401): the exact token
  field(s) in `data` — expected `data.token` or `data.access_token` (+ maybe
  `refresh_token`) and a `data.user` object. Store via the existing `SecureStorage`
  (`setAccessToken` / `setRefreshToken`); the `AuthInterceptor` already attaches the
  Bearer token and the `LocaleInterceptor` the language header.
- "Remember Me" is a client preference (persist the token vs session-only); it is not
  part of the request body.

### Register — endpoint known, capture body on a real submit
```
POST  https://api.dwelleo.sa/api/v1/auth/register
```
- Do NOT auto-create accounts to capture this. Fill the real form once (a throwaway
  account) and read the request, OR have the client do it. Likely body keys mirror the
  form fields below.

### Other auth (from the bundle, for later)
`/auth/nafath/initiate|status|complete`, `/auth/consent`, `/auth/logout`,
`/profile`, `/profile/change-password`. Google sign-in goes through the backend
OAuth (capture its redirect/exchange when wiring; for native use `google_sign_in`
then exchange the token with the backend — confirm the endpoint on the site).

## 2) Sign-up form — fields & per-role differences
Phase-2 ("Personal Information") fields seen on `/register` (★ = required):
`Full Name★`, `Email★`, `Phone Number★` (+966, country selectable),
`WhatsApp Number`, `City` (dropdown), `District`, `Preferred languages★`
(multi, English/العربية), `Password★`, `Confirm Password★`, `Description` (0/1000),
`Location` (map picker), `I agree to Terms & Privacy★`.
- **Per-role:** inspect `/register` after choosing each role — Developer/Agent/Broker
  add company/license fields vs Buyer/Renter. Build the field set per role; don't
  assume they're identical.
- **Create Account** stays grey+disabled until all ★ are valid AND Terms is checked,
  then becomes the accent color (purple light / lime dark) — already wired in theme.

## 3) Lookups (feed the dropdowns from the backend — no hardcoding)
- **City dropdown:** `GET /api/v1/lookup` → `data.cities` (each has `id`, `name`,
  ar/en translations). Make it searchable. (Also `data.areas` for District if it is
  area-bound; verify on the site which list District uses.)
- **Preferred languages:** static `en` / `ar`.
- **Phone country selector:** this is a CLIENT widget (the site uses an intl phone
  input with a searchable country list, default **Saudi Arabia +966**). In Flutter
  use a package like `intl_phone_field` / `phone_form_field` — default SA, full
  searchable country list (the screenshots show searching "eg" → Egypt +20, etc.).
  No backend needed for the country list.

## 4) Location picker (Google Maps) — REAL
- **Maps API key (from the live site):** `<redacted — leaked key; rotated in Google Cloud>`
  (Google Maps JS key — for native, create/restrict an Android + iOS key in the same
  Google Cloud project; this web key may be HTTP-referrer-restricted, so confirm with
  the client before shipping).
- The site's **"Select Location"** modal = search bar (Google Places autocomplete) +
  **Use Current Location** + an interactive map with a draggable pin + Confirm. It
  returns a formatted address + lat/lng (e.g. "7250, Alsahafa, Riyadh 12251, Saudi
  Arabia").
- Flutter: `google_maps_flutter` (already a dependency) + `geolocator` (already a
  dependency) for current location + Google Places API for the address search.
  Recreate the modal: search field, map with center pin ("move the map to position
  the pin"), Use Current Location button, Confirm Location → store address + lat/lng.

## 5) Design tokens — captured from the live login/signup card
Page background (dark): **`#1B1B1B`** (`rgb(27,27,27)`).
Form **card** (the "grey/glassy panel" you asked for):
```
dark:  background rgba(255,255,255,0.10)   // 10% white over the dark page
       border     1px  rgba(255,255,255,0.10)
       radius     24px
       shadow     none
light: a near-white panel on the #F6F7F3 page — a faint translucent panel
       (≈ white / 4–6% black overlay), same 24px radius + hairline border.
       (Capture exact light value from /en/login in light mode if needed.)
```
Inputs sit **inside** the card: white fields in light mode, dark translucent fields
in dark mode, rounded ~14–16px, with a leading icon (mail/lock). Build the auth
screens as: page bg → centered title ("Welcome Back") → **this card** wrapping the
fields, not flat on the page. Reuse the same card for Login and both Sign-up steps.

## 6) Onboarding icon fix (your point #1)
- In light mode the **first** hero shows grey and is **oversized** vs slides 2–3.
- Fix: tint ALL three onboarding visuals with `AppColors.accentFor(brightness)`
  (purple in light, lime in dark) and use a **uniform size** (~110–120 px) for all
  three. The brand mark hero should use the accent color, not a desaturated grey PNG;
  the glow should also use `accentFor`. Match the role-icon treatment that already
  works on the sign-up screen.

## 7) Wire it up (your points #4–#8)
Build an **Auth feature** (clean-arch, per CLAUDE.md): `AuthRemoteDataSource`
(POST login/register), `AuthRepository` (→ `ApiResult`), use cases
(`Login`, `Register`), `AuthCubit` (sealed states: idle/loading/success/failure).
- On **Sign In** success: persist token(s) in `SecureStorage`, then `context.go` to
  **Home** (build a Home shell route if not present).
- On **Create Account** success: same — store the returned user/session.
- Map field/validation errors (HTTP 422) to inline messages (the API returns an
  `errors` map on validation failures — confirm keys on a real call).
- Every button that is currently a no-op (Sign In, Create Account, Continue with
  Google, Forgot password) must call its real flow; leave a clear `// PENDING capture`
  only where the exact contract still needs a live request (register body, Google
  exchange, login token field).

## 8) Quick reference
| Thing | Value |
|---|---|
| API base | `https://api.dwelleo.sa/api/v1` |
| Login | `POST /auth/login` `{email,password}` (CONFIRMED) |
| Register | `POST /auth/register` (capture body) |
| City list | `GET /lookup` → `data.cities` |
| Maps key | `<redacted — leaked key; rotated in Google Cloud>` |
| Card (dark) | bg `rgba(255,255,255,.10)`, radius 24, border 1px `rgba(255,255,255,.10)` |
| Page bg (dark) | `#1B1B1B` |
| Phone field | `intl_phone_field`-style, default SA +966, searchable |
