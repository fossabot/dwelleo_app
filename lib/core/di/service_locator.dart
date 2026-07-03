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
import '../storage/recent_searches_store.dart';
import '../../features/properties/data/datasources/property_remote_data_source.dart';
import '../../features/properties/data/repositories/property_repository_impl.dart';
import '../../features/properties/domain/repositories/property_repository.dart';
import '../../features/properties/domain/usecases/get_properties.dart';
import '../../features/properties/domain/usecases/get_property_detail.dart';
import '../../features/properties/presentation/cubit/properties_cubit.dart';
import '../../features/properties/presentation/cubit/property_detail_cubit.dart';

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
  sl.registerLazySingleton<LookupService>(() => LookupService(sl<Dio>()));

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
  sl.registerLazySingleton(() => GetPropertyDetail(sl<PropertyRepository>()));
  sl.registerFactory(() => PropertiesCubit(sl<GetProperties>()));
  sl.registerFactory(() => PropertyDetailCubit(sl<GetPropertyDetail>()));

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
  sl.registerLazySingleton<RecentSearchesStore>(RecentSearchesStore.new);
  sl.registerFactory(
    () => HomeCubit(
      sl<GetProperties>(),
      sl<GetProjects>(),
      sl<GetFeaturedDevelopers>(),
      sl<GetFeaturedBrokers>(),
    ),
  );
  sl.registerFactory(() => ExploreCubit(sl<GetProjects>()));
  sl.registerFactory(() => MarketStatsCubit(sl<GetCityMarketStats>()));
  sl.registerFactory(
    () => MarketMapCubit(sl<GetCityMarketStats>(), sl<GetMarketDistricts>()),
  );
  sl.registerFactory(
    () => SearchBoxCubit(sl<LookupService>(), sl<RecentSearchesStore>()),
  );
}
