/// Dwelleo API endpoints — base https://api.dwelleo.sa (Laravel 11), prefix /api/v1.
///
/// Verified 2026-06-25 against the live backend AND the production web frontend's
/// JavaScript bundle (the routes below are the exact strings the official web app
/// calls). See docs/api/REAL_API_SPEC.md for evidence.
///
/// Routes are CONFIRMED-REAL (present in the live frontend bundle / returned data).
/// Where the HTTP METHOD or request BODY is not yet observed from a live call, it is
/// marked `@bodyPending` — capture the exact payload from network traffic before coding
/// the request model. Do NOT invent payloads.
abstract final class ApiEndpoints {
  static const String _base = '/api/v1';

  // ---- Reads: catalog (public, no auth) ------------------------------------
  /// GET — dual-mode (re-verified live 2026-07-06):
  ///  • bare call → curated home/featured set `{message,data:{properties}}`
  ///  • with `?page=N` → PAGINATED SEARCH: `{message,data:{properties[20],
  ///    pagination{total,count,per_page:20,current_page,total_pages}}}`,
  ///    honoring filter[listing_type|city_id|bedrooms|min_price|max_price]
  ///    and filter[property_types][] (array syntax). Corpus at capture:
  ///    1,912 properties / 96 pages.
  static const String properties = '$_base/properties';
  static String propertyBySlug(String slug) => '$_base/properties/$slug';

  /// GET — `{message,data:{projects:[...]}}`. Detail by id below.
  static const String projects = '$_base/projects';
  static String projectById(String id) => '$_base/projects/$id';

  /// GET — `{message,data:{developers:[...],pagination:{...}}}`. Page via `?page=N`.
  static const String developers = '$_base/developers';
  static String developerById(String id) => '$_base/developers/$id';
  static const String developerLocations = '$_base/developers/locations';

  /// GET — filter lookups `{amenities,property_types,tags,cities,areas}`.
  static const String lookup = '$_base/lookup';

  /// GET — content lists.
  static const String testimonials = '$_base/testimonials';
  static const String subscriptions = '$_base/subscriptions';

  // ---- Market insights -----------------------------------------------------
  // CAPTURED from live site traffic (2026-07-02): both take
  //   ?unit_type_id={1|2}&heatmap=price&transaction_type={buy|rent}
  // and /districts additionally takes &city_id={id}.
  // buy → filtered_stats{price_of_meter,median}; rent → {monthly_price,
  // annual_price,median}. Envelope: {success, data:[...]}.
  static const String marketCities = '$_base/market/cities';
  static const String marketDistricts = '$_base/market/districts';

  // ---- Auth: email/password (CONFIRMED live) -------------------------------
  // POST {email,password} -> envelope {message,data:{...}}. The exact token
  // field inside `data` is @bodyPending (capture from a real login).
  static const String login = '$_base/auth/login';

  // ---- Auth: NAFATH (Saudi national identity) ------------------------------
  // NOTE: Nafath flow (alongside email/password). initiate -> poll status -> complete.
  @bodyPending
  static const String nafathInitiate = '$_base/auth/nafath/initiate';
  @bodyPending
  static const String nafathStatus = '$_base/auth/nafath/status';
  @bodyPending
  static const String nafathComplete = '$_base/auth/nafath/complete';
  // POST — creates the account and issues a 4-digit OTP; NO login token is
  // returned (the user must verify the OTP, then log in). Verified shapes in
  // docs/HANDOFF_AUTH_FINISH.md §1.
  static const String register = '$_base/auth/register';

  // OTP verify/resend for the sign-up flow. PENDING: confirm the exact path +
  // body keys from a live register→"Verify Code" capture (HANDOFF §1 ACTION).
  // Doc's best guess: POST /auth/verify-otp {email, code}.
  @bodyPending
  static const String verifyOtp = '$_base/auth/verify-otp';
  @bodyPending
  static const String resendOtp = '$_base/auth/resend-otp';

  // ---- Forgot password (VERIFIED live — HANDOFF §Forgot Password) ----------
  // 1) POST /auth/send-otp  {email, type:"forgot_password"} -> {verification_token}
  //    (rate-limited; only "forgot_password" is a valid type).
  // 2) POST /auth/verify    {verification_token, otp}
  // 3) POST /auth/reset-password {verification_token, new_password,
  //    new_password_confirmation} (pw: upper+lower+digit+symbol, min 8).
  static const String sendOtp = '$_base/auth/send-otp';
  static const String verify = '$_base/auth/verify';
  static const String resetPassword = '$_base/auth/reset-password';

  @bodyPending
  static const String authConsent = '$_base/auth/consent';
  @bodyPending
  static const String logout = '$_base/auth/logout';

  /// UNCONFIRMED. No token-refresh route was found in the real frontend bundle;
  /// Nafath sessions may not use refresh tokens at all. Kept only so the legacy
  /// AuthInterceptor compiles — revisit when the real Nafath token flow is captured.
  @bodyPending
  static const String refreshToken = '$_base/auth/token/refresh';

  // ---- Authenticated profile ----------------------------------------------
  @bodyPending
  static const String profile = '$_base/profile';
  @bodyPending
  static const String changePassword = '$_base/profile/change-password';

  // ---- Authenticated user / seller workspace -------------------------------
  static const String userProperties = '$_base/user/properties';
  static String userPropertyById(String id) => '$_base/user/properties/$id';
  static const String userProjects = '$_base/user/projects';
  static const String userAds = '$_base/user/ads';
  static const String userSubscriptions = '$_base/user/subscriptions';
  static const String userSubscriptionInvoice =
      '$_base/user/subscriptions/invoice';

  // ---- AI services (authenticated) -----------------------------------------
  static const String aiHealth = '$_base/user/ai/health';
  @bodyPending
  static const String aiApartmentPrediction =
      '$_base/user/ai/apartment-prediction';
  @bodyPending
  static const String aiVillaPrediction = '$_base/user/ai/villa-prediction';
  @bodyPending
  static const String aiRentalPrediction = '$_base/user/ai/rental-prediction';
  static const String aiPoiCategories = '$_base/user/ai/poi/categories';
  @bodyPending
  static const String aiPoiNearby = '$_base/user/ai/poi/nearby';
  @bodyPending
  static const String aiVoiceProcess =
      '$_base/user/ai/voice/conversations/process';

  // ---- Leads / contact / misc ----------------------------------------------
  @bodyPending
  static const String leadsIngest = '$_base/leads/ingest';
  @bodyPending
  static const String leadsIngestBatches = '$_base/leads/ingest/batches';
  @bodyPending
  static const String contactUs = '$_base/contact-us';
  @bodyPending
  static const String complains = '$_base/complains';
  @bodyPending
  static const String newsletterSubscribe = '$_base/newsletter/subscribe';
  @bodyPending
  static const String subscribe = '$_base/subscribe';
  @bodyPending
  static const String upload = '$_base/upload';
  @bodyPending
  static const String listingsGenerateAiContent =
      '$_base/listings/generate-ai-content';
}

/// Spatie query-builder filter keys for the property search (confirmed from the web bundle).
/// Usage: `?filter[listing_type]=for-sale&filter[city_id]=..&filter[min_price]=..&page=N`.
/// (Exact pagination envelope of the FILTERED search is still to be captured from a live call.)
abstract final class PropertyFilters {
  static const String listingType =
      'filter[listing_type]'; // for-sale | for-rent

  /// On /developers: `broker` returns the brokers list (the website's
  /// "Top Real Estate Brokers" tab). CAPTURED live 2026-07-02.
  static const String userType = 'filter[user_type]';

  /// VERIFIED NO-OP (live probe 2026-07-06): the backend accepts this key
  /// but does not filter by it. Kept only as documentation — do not send.
  static const String propertyType = 'filter[property_type]';

  /// VERIFIED (live probe 2026-07-06): must use ARRAY syntax — repeat
  /// `filter[property_types][]=id`; comma-joined values return HTTP 422
  /// ("must be an array"). `filter[property_types][]=2` → 286 villas,
  /// matching the website's type-menu count.
  static const String propertyTypes = 'filter[property_types]';
  static const String propertyTypesArray = 'filter[property_types][]';
  static const String unitType = 'filter[unit_type]';
  static const String bedrooms = 'filter[bedrooms]';
  static const String bathrooms = 'filter[bathrooms]';
  static const String minPrice = 'filter[min_price]';
  static const String maxPrice = 'filter[max_price]';
  static const String cityId = 'filter[city_id]';
  static const String areaId = 'filter[area_id]';
  static const String regionId = 'filter[region_id]';
  static const String developerId = 'filter[developer_id]';
  static const String projectId = 'filter[project_id]';
  static const String ownerId = 'filter[owner_id]';
  static const String amenities = 'filter[amenities]';
  static const String furnishingStatus = 'filter[furnishing_status]';
  static const String availabilityStatus = 'filter[availability_status]';
  static const String isFavorite = 'filter[is_favorite]';
  static const String isFeatured = 'filter[is_featured]';
  static const String featured = 'filter[featured]';
  static const String featuredInHome = 'filter[featuredInHome]';
  static const String locations = 'filter[locations]';
  static const String fromArea = 'filter[from_area]';
  static const String toArea = 'filter[to_area]';
  static const String minHandoverDate = 'filter[min_handover_date]';
  static const String maxHandoverDate = 'filter[max_handover_date]';
  static const String commuteTime = 'filter[commute_time]';
  static const String languageSpoken = 'filter[language_spoken]';
  static const String sortCreatedAt =
      'sort[created_at]'; // value: created_at | -created_at
  static const String page = 'page';
}

/// Marker: HTTP method/body of this endpoint is not yet observed from a live call.
/// Capture the exact request before building its model. Never invent the payload.
const Object bodyPending = _BodyPending();

class _BodyPending {
  const _BodyPending();
}

abstract final class AppCheckHeaders {
  static const String xFirebaseAppCheck = 'X-Firebase-AppCheck';
}
