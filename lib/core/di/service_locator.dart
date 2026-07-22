import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import '../config/app_config.dart';
import '../constants/app_constants.dart';
import '../localization/locale_cubit.dart';
import '../network/dio_client.dart';
import '../network/interceptors/auth_interceptor.dart';
import '../network/interceptors/locale_interceptor.dart';
import '../storage/secure_storage.dart';
import '../theme/theme_cubit.dart';
import '../lookup/lookup_service.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login.dart';
import '../../features/auth/domain/usecases/register.dart';
import '../../features/auth/domain/usecases/verify_otp.dart';
import '../../features/auth/domain/usecases/forgot_password_usecases.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/cubit/forgot_password_cubit.dart';
import '../../features/home/data/datasources/home_remote_data_source.dart';
import '../../features/home/data/repositories/home_repository_impl.dart';
import '../../features/home/domain/repositories/home_repository.dart';
import '../../features/home/domain/usecases/get_city_market_stats.dart';
import '../../features/home/domain/usecases/get_featured_brokers.dart';
import '../../features/home/domain/usecases/get_featured_developers.dart';
import '../../features/home/domain/usecases/get_market_districts.dart';
import '../../features/home/domain/usecases/get_projects.dart';
import '../../features/home/presentation/cubit/explore_cubit.dart';
import '../../features/home/presentation/cubit/home_cubit.dart';
import '../../features/home/presentation/cubit/market_map_cubit.dart';
import '../../features/home/presentation/cubit/market_stats_cubit.dart';
import '../../features/home/presentation/cubit/search_box_cubit.dart';
import '../session/session_state.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

import '../analytics/analytics_service.dart';
import '../errors/api_result.dart';
import '../utils/formatters.dart';
import '../storage/recent_searches_store.dart';
import '../storage/saved_searches_store.dart';
import '../../features/properties/data/datasources/property_remote_data_source.dart';
import '../../features/properties/data/repositories/property_repository_impl.dart';
import '../../features/properties/domain/repositories/property_repository.dart';
import '../../features/properties/domain/usecases/get_properties.dart';
import '../../features/properties/domain/usecases/get_property_detail.dart';
import '../../features/properties/domain/usecases/search_properties.dart';
import '../../features/properties/presentation/cubit/properties_cubit.dart';
import '../../features/properties/presentation/cubit/property_detail_cubit.dart';
import '../../features/properties/data/datasources/favorites_local_data_source.dart';
import '../../features/properties/data/repositories/favorites_repository_impl.dart';
import '../../features/properties/domain/repositories/favorites_repository.dart';
import '../../features/properties/domain/usecases/favorites_usecases.dart';
import '../../features/properties/presentation/cubit/favorites_cubit.dart';
import '../../features/ai_sales_agent/data/datasources/groq_sales_remote_data_source.dart';
import '../../features/ai_sales_agent/data/datasources/sales_chat_local_data_source.dart';
import '../../features/ai_sales_agent/data/datasources/sales_remote_data_source.dart';
import '../../features/ai_sales_agent/data/datasources/serper_search_data_source.dart';
import '../../features/ai_sales_agent/data/repositories/listing_search_repository_impl.dart';
import '../../features/ai_sales_agent/data/repositories/sales_agent_repository_impl.dart';
import '../../features/ai_sales_agent/data/repositories/sales_chat_repository_impl.dart';
import '../../features/ai_sales_agent/domain/repositories/listing_search_repository.dart';
import '../../features/ai_sales_agent/domain/repositories/sales_agent_repository.dart';
import '../../features/ai_sales_agent/domain/repositories/sales_chat_repository.dart';
import '../../features/ai_sales_agent/domain/usecases/chat_history.dart';
import '../../features/ai_sales_agent/domain/usecases/search_listings.dart';
import '../../features/ai_sales_agent/domain/usecases/send_sales_message.dart';
import '../../features/ai_sales_agent/presentation/cubit/sales_agent_cubit.dart';
import '../db/app_database.dart';
import '../../features/ai_search/domain/usecases/interpret_ai_query.dart';
import '../../features/ai_search/presentation/cubit/ai_search_cubit.dart';
import '../speech/speech_service.dart';
import '../speech/tts_service.dart';
import '../../features/home/domain/usecases/get_all_agents.dart';
import '../../features/home/domain/usecases/get_all_brokers.dart';
import '../../features/home/domain/usecases/get_all_developers.dart';
import '../../features/home/domain/usecases/get_project_detail.dart';
import '../../features/home/presentation/cubit/developers_directory_cubit.dart';
import '../../features/home/presentation/cubit/project_detail_cubit.dart';
import '../../features/properties/presentation/cubit/compare_cubit.dart';
import '../../features/properties/presentation/cubit/type_counts_cache.dart';
import '../../features/properties/presentation/cubit/type_counts_cubit.dart';
import '../../features/estimate/data/datasources/estimate_local_data_source.dart';
import '../../features/estimate/data/repositories/estimate_repository_impl.dart';
import '../../features/estimate/domain/repositories/estimate_repository.dart';
import '../../features/estimate/domain/usecases/calculate_estimate.dart';
import '../../features/estimate/domain/usecases/get_estimates.dart';
import '../../features/estimate/domain/usecases/save_estimate.dart';
import '../../features/estimate/presentation/cubit/estimate_cubit.dart';
import '../../features/market_insights/data/datasources/market_insight_remote_data_source.dart';
import '../../features/market_insights/data/repositories/market_insight_repository_impl.dart';
import '../../features/market_insights/domain/repositories/market_insight_repository.dart';
import '../../features/market_insights/domain/usecases/get_market_insight_lookups.dart';
import '../../features/market_insights/domain/usecases/get_market_insight_series.dart';
import '../../features/market_insights/presentation/cubit/market_insight_cubit.dart';

final sl = GetIt.instance;

Future<void> setupServiceLocator() async {
  // ── Storage ──────────────────────────────────────────────────────────────
  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );
  sl.registerLazySingleton<SecureStorage>(
    () => SecureStorage(sl<FlutterSecureStorage>()),
  );

  // In-memory auth/onboarding snapshot for the router guard (populated in
  // bootstrap before runApp).
  sl.registerLazySingleton<SessionState>(() => SessionState());

  // ── Locale & Theme ─────────────────────────────────────────────────────────
  sl.registerLazySingleton<LocaleCubit>(() => LocaleCubit(sl<SecureStorage>()));
  sl.registerLazySingleton<ThemeCubit>(() => ThemeCubit(sl<SecureStorage>()));

  // ── Network ──────────────────────────────────────────────────────────────
  // Dedicated Dio for token refresh — no AuthInterceptor to prevent re-entry,
  // but carries LocaleInterceptor so the server sees the correct locale.
  final refreshDio = Dio(
    BaseOptions(
      baseUrl: AppConfig.instance.apiBaseUrl,
      connectTimeout: const Duration(milliseconds: AppConstants.connectTimeout),
      receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeout),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  )..interceptors.add(LocaleInterceptor(sl<SecureStorage>()));

  sl.registerLazySingleton<Dio>(
    () => DioClient.create(
      baseUrl: AppConfig.instance.apiBaseUrl,
      interceptors: [
        LocaleInterceptor(sl<SecureStorage>()),
        AuthInterceptor(sl<SecureStorage>(), refreshDio),
      ],
    ),
  );

  // ── Lookups (cities, …) ────────────────────────────────────────────────────
  sl.registerLazySingleton<LookupService>(
    () => LookupService(sl<Dio>(), sl<SecureStorage>()),
  );

  // ── Feature: Auth ──────────────────────────────────────────────────────────
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(sl<Dio>()),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl<AuthRemoteDataSource>()),
  );
  sl.registerLazySingleton(() => Login(sl<AuthRepository>()));
  sl.registerLazySingleton(() => Register(sl<AuthRepository>()));
  sl.registerLazySingleton(() => VerifyOtp(sl<AuthRepository>()));
  sl.registerLazySingleton(() => ResendOtp(sl<AuthRepository>()));
  sl.registerFactory(
    () => AuthCubit(
      sl<Login>(),
      sl<Register>(),
      sl<VerifyOtp>(),
      sl<ResendOtp>(),
      sl<SecureStorage>(),
      sl<SessionState>(),
    ),
  );
  // Forgot password (send-otp → verify → reset-password).
  sl.registerLazySingleton(() => SendResetCode(sl<AuthRepository>()));
  sl.registerLazySingleton(() => VerifyResetCode(sl<AuthRepository>()));
  sl.registerLazySingleton(() => ResetPassword(sl<AuthRepository>()));
  sl.registerFactory(
    () => ForgotPasswordCubit(
      sl<SendResetCode>(),
      sl<VerifyResetCode>(),
      sl<ResetPassword>(),
    ),
  );

  // ── Feature: Properties ──────────────────────────────────────────────────
  sl.registerLazySingleton<PropertyRemoteDataSource>(
    () => PropertyRemoteDataSourceImpl(sl<Dio>()),
  );
  sl.registerLazySingleton<PropertyRepository>(
    () => PropertyRepositoryImpl(sl<PropertyRemoteDataSource>()),
  );
  sl.registerLazySingleton(() => GetProperties(sl<PropertyRepository>()));
  sl.registerLazySingleton(() => SearchProperties(sl<PropertyRepository>()));
  sl.registerLazySingleton(() => GetPropertyDetail(sl<PropertyRepository>()));
  sl.registerFactory(() => PropertiesCubit(sl<SearchProperties>()));
  sl.registerFactory(() => PropertyDetailCubit(sl<GetPropertyDetail>()));
  // Local favorites (Saved tab + hearts everywhere + Sarah's buyer context).
  sl.registerLazySingleton<FavoritesLocalDataSource>(
    () => FavoritesLocalDataSource(sl<AppDatabase>()),
  );
  sl.registerLazySingleton<FavoritesRepository>(
    () => FavoritesRepositoryImpl(sl<FavoritesLocalDataSource>()),
  );
  sl.registerLazySingleton(() => GetFavorites(sl<FavoritesRepository>()));
  sl.registerLazySingleton(() => GetFavoriteIds(sl<FavoritesRepository>()));
  sl.registerLazySingleton(() => ToggleFavorite(sl<FavoritesRepository>()));
  sl.registerLazySingleton(() => RemoveFavorite(sl<FavoritesRepository>()));
  sl.registerFactory(
    () => FavoritesCubit(sl<GetFavorites>(), sl<RemoveFavorite>()),
  );

  // ── Feature: AI Search (PR-11) ───────────────────────────────────────────
  // On-device interpreter over verified /properties filters; SpeechService is
  // widget-layer voice input (cubit stays use-case-only per CLAUDE.md).
  sl.registerLazySingleton(() => InterpretAiQuery(sl<LookupService>()));
  sl.registerLazySingleton<SpeechService>(() => SpeechService());
  sl.registerLazySingleton<TtsService>(() => TtsService());
  sl.registerFactory(
    () => AiSearchCubit(sl<InterpretAiQuery>(), sl<SearchProperties>()),
  );

  // ── Feature: AI Sales Agent (Groq free-tier + Serper listing search) ─────
  // All data sources use their own Dio instances — Dwelleo auth/locale
  // interceptors must never reach third-party hosts.
  sl.registerLazySingleton<SalesRemoteDataSource>(
    () => GroqSalesRemoteDataSource(),
  );
  sl.registerLazySingleton<SalesAgentRepository>(
    () => SalesAgentRepositoryImpl(sl<SalesRemoteDataSource>()),
  );
  sl.registerLazySingleton(
    () => SendSalesMessage(
      sl<SalesAgentRepository>(),
      // Sarah reads the buyer's SAVED listings (owner vision: user actions
      // in the local DB feed the agent's thinking). Failure ⇒ null ⇒ chat
      // proceeds without context.
      buyerContext: () async {
        final result = await sl<GetFavorites>()();
        return switch (result) {
          ApiSuccess(:final data) when data.isNotEmpty =>
            data
                .take(5)
                .map(
                  (p) =>
                      '- ${p.title}'
                      '${p.price != null ? ' (${Formatters.price(p.price)})' : ''}'
                      '${p.cityName != null ? ' — ${p.cityName}' : ''}',
                )
                .join('\n'),
          _ => null,
        };
      },
    ),
  );
  sl.registerLazySingleton<SerperSearchDataSource>(
    () => SerperSearchDataSource(),
  );
  sl.registerLazySingleton<ListingSearchRepository>(
    () => ListingSearchRepositoryImpl(sl<SerperSearchDataSource>()),
  );
  sl.registerLazySingleton(() => SearchListings(sl<ListingSearchRepository>()));
  // Chat history: local SQLite (core/db), Claude-app-style persistence.
  sl.registerLazySingleton<AppDatabase>(() => AppDatabase());
  sl.registerLazySingleton<SalesChatLocalDataSource>(
    () => SalesChatLocalDataSource(sl<AppDatabase>()),
  );
  sl.registerLazySingleton<SalesChatRepository>(
    () => SalesChatRepositoryImpl(sl<SalesChatLocalDataSource>()),
  );
  sl.registerLazySingleton(() => ChatHistory(sl<SalesChatRepository>()));
  sl.registerFactory(
    () => SalesAgentCubit(
      sl<SendSalesMessage>(),
      sl<SearchListings>(),
      sl<ChatHistory>(),
    ),
  );

  // ── Feature: Home / Explore ───────────────────────────────────────────────
  sl.registerLazySingleton<HomeRemoteDataSource>(
    () => HomeRemoteDataSourceImpl(sl<Dio>()),
  );
  sl.registerLazySingleton<HomeRepository>(
    () => HomeRepositoryImpl(sl<HomeRemoteDataSource>()),
  );
  sl.registerLazySingleton(() => GetProjects(sl<HomeRepository>()));
  sl.registerLazySingleton(() => GetFeaturedDevelopers(sl<HomeRepository>()));
  sl.registerLazySingleton(() => GetFeaturedBrokers(sl<HomeRepository>()));
  sl.registerLazySingleton(() => GetCityMarketStats(sl<HomeRepository>()));
  sl.registerLazySingleton(() => GetMarketDistricts(sl<HomeRepository>()));
  sl.registerLazySingleton(() => GetProjectDetail(sl<HomeRepository>()));
  sl.registerLazySingleton(() => GetAllDevelopers(sl<HomeRepository>()));
  sl.registerLazySingleton(() => GetAllBrokers(sl<HomeRepository>()));
  sl.registerLazySingleton(() => GetAllAgents(sl<HomeRepository>()));

  // ── Market Insights (live /market-insights/rental/* charts) ───────────
  sl.registerLazySingleton<MarketInsightRemoteDataSource>(
    () => MarketInsightRemoteDataSourceImpl(sl<Dio>()),
  );
  sl.registerLazySingleton<MarketInsightRepository>(
    () => MarketInsightRepositoryImpl(sl<MarketInsightRemoteDataSource>()),
  );
  sl.registerLazySingleton(
    () => GetMarketInsightSeries(sl<MarketInsightRepository>()),
  );
  sl.registerLazySingleton(
    () => GetMarketInsightLookups(sl<MarketInsightRepository>()),
  );
  sl.registerFactory(
    () => MarketInsightCubit(
      sl<GetMarketInsightSeries>(),
      sl<GetMarketInsightLookups>(),
    ),
  );

  // ── Estimate Property (6-phase wizard over verified market data) ──────
  sl.registerLazySingleton<EstimateLocalDataSource>(
    () => EstimateLocalDataSource(sl<AppDatabase>()),
  );
  sl.registerLazySingleton<EstimateRepository>(
    () => EstimateRepositoryImpl(sl<EstimateLocalDataSource>()),
  );
  sl.registerLazySingleton(() => CalculateEstimate(sl<GetMarketDistricts>()));
  sl.registerLazySingleton(() => SaveEstimate(sl<EstimateRepository>()));
  sl.registerLazySingleton(() => GetEstimates(sl<EstimateRepository>()));
  sl.registerLazySingleton<RecentSearchesStore>(RecentSearchesStore.new);
  sl.registerLazySingleton<SavedSearchesStore>(SavedSearchesStore.new);
  sl.registerLazySingleton<AnalyticsService>(
    () => AnalyticsService(FirebaseAnalytics.instance),
  );
  sl.registerFactory(
    () => HomeCubit(
      sl<GetProperties>(),
      sl<GetProjects>(),
      sl<GetFeaturedDevelopers>(),
      sl<GetFeaturedBrokers>(),
    ),
  );
  sl.registerFactory(() => ExploreCubit(sl<GetProjects>()));
  sl.registerFactory(() => ProjectDetailCubit(sl<GetProjectDetail>()));
  sl.registerFactory(
    () => DevelopersDirectoryCubit(
      sl<GetAllDevelopers>(),
      sl<GetAllBrokers>(),
      sl<GetAllAgents>(),
    ),
  );
  // Compare tray is app-wide state (toggle on any property, view at /compare).
  sl.registerLazySingleton<CompareCubit>(CompareCubit.new);
  // Session-scoped so the type-count strip survives across list-screen visits
  // and revisits skip the per-type fan-out.
  sl.registerLazySingleton<TypeCountsCache>(
    () => TypeCountsCache(sl<SecureStorage>()),
  );
  sl.registerFactory(
    () => TypeCountsCubit(
      sl<SearchProperties>(),
      sl<LookupService>(),
      sl<TypeCountsCache>(),
    ),
  );
  sl.registerFactory(
    () => EstimateCubit(
      sl<CalculateEstimate>(),
      sl<SaveEstimate>(),
      sl<GetMarketDistricts>(),
      sl<LookupService>(),
    ),
  );
  sl.registerFactory(() => MarketStatsCubit(sl<GetCityMarketStats>()));
  sl.registerFactory(
    () => MarketMapCubit(sl<GetCityMarketStats>(), sl<GetMarketDistricts>()),
  );
  sl.registerFactory(
    () => SearchBoxCubit(sl<LookupService>(), sl<RecentSearchesStore>()),
  );
}
