# Architecture — Current & Target

## Current (verified)

```mermaid
flowchart LR
  subgraph Presentation
    UI[Screens/Widgets<br/>go_router shell · 5 tabs] --> CUBITS[Cubits<br/>sealed states]
  end
  subgraph Domain
    UC[Use cases] --> REPOI[(Repository<br/>interfaces)]
    ENT[Entities · ApiResult&lt;T&gt; · Failure]
  end
  subgraph Data
    REPO[Repository impls<br/>DioException→Failure] --> DS[Remote data sources]
    DS --> DIO[Dio + Auth/Locale/Logging interceptors<br/>+ refresh Dio]
  end
  CUBITS --> UC
  REPO -.implements.-> REPOI
  DIO --> API[(api.dwelleo.sa /api/v1)]
  subgraph Core
    DI[get_it] --- SS[SecureStorage] --- L10N[EN/AR + RTL] --- THEME
    IMG[Image optimizer bridge] --- STORES[SharedPrefs stores] --- LOOKUP
  end
  BOOT[bootstrap: Firebase/Crashlytics/Perf] --> DI
```

Rules enforced today: presentation→domain→data only; domain has zero Flutter
imports; cubits depend on use cases only; shared code in `core/`; no codegen/Freezed.

## Target production architecture (additive — no rewrite)

```mermaid
flowchart TB
  ENV[Env config: dev/staging/prod<br/>flavors + dart-define, no secrets in repo] --> BOOT
  BOOT --> DI
  DI --> FEATURES[auth · properties · home/market · projects · partners<br/>+ ai_search · subscriptions · seller · insights]
  FEATURES --> SESSION[Session manager:<br/>refresh, expiry, logout invalidation, restore]
  FEATURES --> ENTITLE[Entitlement service<br/>store billing + server receipt validation]
  FEATURES --> AISVC[AI gateway client<br/>streaming, quotas, guardrails, fallback to classic search]
  FEATURES --> CACHE[Read-through cache/offline layer<br/>for catalog + market reads]
  SEC[App Check → Play Integrity/App Attest · freerasp wired ·<br/>log redaction · pinning decision ADR] --> DIO
  OBS[Analytics taxonomy → Firebase+Amplitude/PostHog ·<br/>Crashlytics keys · Performance traces] --> FEATURES
  CI[GitHub Actions: PR gates → dev builds → release lanes<br/>fastlane · signed via CI secrets] -.governs.-> ALL[(repo)]
```

Decisions requiring ADRs before build: offline/cache store choice; billing
approach (store vs backend-managed for KSA); pinning strategy; AI streaming
transport; entitlement sync model. ADR template: handoff `architecture/adr/0001`.
