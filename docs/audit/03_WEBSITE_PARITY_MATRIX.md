# Website → Mobile Parity Matrix

Status: LIVE = working in app on real API · PARTIAL · STUB = branded placeholder · MISSING.
Class: V-W (verified from website), V-R (repo), V-B (both), P (proposed), PB/PD/PA/PL (pending backend/design/AI/legal), BLK (blocked).

## Marketplace
| Capability | Status | Class | Evidence / notes |
|---|---|---|---|
| Buy / Rent lists | LIVE | V-B | `filter[listing_type]` |
| Off-plan (projects) | LIVE | V-B | `/projects`, Explore tab + home rail |
| Commercial | PARTIAL | PB | tab present; commercial filter param uncaptured (`@bodyPending` discipline) |
| Featured & new listings | LIVE | V-B | curated `/properties` home set |
| Property types | LIVE | V-B | `/lookup` property_types (Apartment=1, Villa=2 …) |
| Search (city/area/project text) | LIVE | V-B | text→lookup city resolution; site uses slug routes |
| Advanced filters (price/beds/baths…) | PARTIAL | V-W | params captured in web bundle; filter UI = PR-7 |
| Pagination | PARTIAL | PB | `?page=N` known; filtered-search envelope uncaptured |
| Property details | LIVE | V-B | `/properties/{slug}` |
| Map view (listings on map) | MISSING | V-W | PR-8 |
| Compare properties | MISSING | PB | not directly observed on site this audit — verify placement before build |
| Call / WhatsApp actions | PARTIAL | V-B | data present (`owner.phone`, project `whatsapp`); native actions + lead events = PR-7 |
| Verified listings/agents | PARTIAL | V-B | `verified` flags rendered in sheets; listing-level badge TBD |
| Seller/broker/developer attribution | LIVE | V-B | owner/user_type on property; partner sheets → `filter[developer_id]` list |

## Advanced discovery
| Travel-time search (destination, max time, car/metro/walk, peak) | MISSING | V-W + PB | `filter[from_area]/[to_area]/[commute_time]` in bundle; semantics/UI need capture — PR-8 |

## Ecosystem
| Developers / Brokers rails + tabs | LIVE | V-B | brokers = `filter[user_type]=broker` (captured) |
| Developer profile pages | MISSING | V-W | site `/developers/{id-slug}`; PR-9 |
| Agents discovery | MISSING | PB | source endpoint unconfirmed |
| Projects & project details | PARTIAL | V-B | list LIVE; detail page = PR-9 (quick-look sheet exists) |
| Market Insights: City Intelligence (buy/rent × apt/villa) | LIVE | V-B | captured params; table matches site numbers |
| Interactive market map + district drill-down | LIVE | V-B | `/market/districts` captured (121 Riyadh districts) |
| Rental returns / trends / ROI forecasting | MISSING | PB | site markets concepts; no public endpoints captured |

## AI products
| AI Search (text) / voice | STUB | PB/PA | endpoints exist (`/user/ai/*`), contracts uncaptured — PR-11 |
| AI Sales Agent (developer-facing, BITEP-or-BANT, scheduling, escalation, docs, CRM) | MISSING | BLK | site markets it (“BANT-grade” banner); zero public contract — PR-12 after confirmation |

## Subscriptions
| Plans (free/monthly/yearly), up/downgrade, cancel, retain-until-period-end | STUB | BLK | `/subscriptions` live but returns `data: []`; store billing decision + prices needed — PR-13 |

## Supporting
| Login/registration/OTP/forgot | LIVE | V-B | + remember-me & route guard |
| List Property | MISSING | PB | `/user/properties` write bodies uncaptured |
| Contact / FAQ / Complaints / Privacy / Terms | MISSING | V-W + PL | content endpoints/pages; PR-14 scope |
| AR/EN + RTL | LIVE | V-B | full l10n incl. AR error messages |
| Dark/Light | LIVE | V-B | site-calibrated accent flip |
| Consent (cookies/analytics) | MISSING | PL | PR-14 |
| Store distribution | MISSING | BLK | PR-15; accounts/signing unconfirmed |
