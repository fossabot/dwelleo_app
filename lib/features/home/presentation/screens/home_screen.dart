import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/dwelleo_app_bar.dart';
import '../../../../core/widgets/motion.dart';
import '../cubit/home_cubit.dart';
import '../cubit/market_map_cubit.dart';
import '../cubit/market_stats_cubit.dart';
import '../cubit/search_box_cubit.dart';
import '../widgets/ai_agent_banner.dart';
import '../widgets/featured_properties_section.dart';
import '../widgets/home_hero.dart';
import '../widgets/home_nav_strip.dart';
import '../widgets/market_map_section.dart';
import '../widgets/market_table_section.dart';
import '../widgets/partners_section.dart';
import '../widgets/projects_section.dart';
import '../widgets/quick_actions.dart';
import '../widgets/search_card.dart';

/// Post-auth landing — dwelleo.sa's home translated to mobile, top to
/// bottom like the site: nav strip, hero, AI-agent banner, search box,
/// quick actions, featured properties, projects by city, City Intelligence
/// table, Interactive Market map and featured developers/brokers.
///
/// The market table and map own separate cubits so their toggles stay
/// independent — exactly like the website.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeCubit _homeCubit;
  late final MarketStatsCubit _tableCubit;
  late final MarketMapCubit _mapCubit;
  late final SearchBoxCubit _searchCubit;

  /// Anchors: "Price Statistics" quick action → table; Explore ▾ →
  /// Developers → partners section.
  final GlobalKey _marketKey = GlobalKey();
  final GlobalKey _partnersKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _homeCubit = sl<HomeCubit>()..load();
    _tableCubit = sl<MarketStatsCubit>()..load();
    _mapCubit = sl<MarketMapCubit>()..load();
    _searchCubit = sl<SearchBoxCubit>()..init();
  }

  @override
  void dispose() {
    _homeCubit.close();
    _tableCubit.close();
    _mapCubit.close();
    _searchCubit.close();
    super.dispose();
  }

  Future<void> _refresh() {
    return Future.wait([
      _homeCubit.refresh(),
      _tableCubit.refresh(),
      _mapCubit.refresh(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _homeCubit),
        BlocProvider.value(value: _tableCubit),
        BlocProvider.value(value: _mapCubit),
        BlocProvider.value(value: _searchCubit),
      ],
      child: Scaffold(
        appBar: const DwelleoAppBar(),
        body: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              // Above-the-fold entrance: quick stagger, then sections animate
              // in as they're built on scroll (ListView laziness = free).
              FadeSlideIn(
                child: HomeNavStrip(
                  onDevelopers: () =>
                      context.push(RoutePaths.developersDirectory),
                ),
              ),
              const FadeSlideIn(
                delay: Duration(milliseconds: 60),
                child: HomeHero(),
              ),
              const FadeSlideIn(
                delay: Duration(milliseconds: 120),
                child: AiAgentBanner(),
              ),
              const FadeSlideIn(
                delay: Duration(milliseconds: 180),
                child: SearchCard(),
              ),
              FadeSlideIn(
                delay: const Duration(milliseconds: 240),
                child: const QuickActions(),
              ),
              const FadeSlideIn(child: FeaturedPropertiesSection()),
              const FadeSlideIn(child: ProjectsSection()),
              KeyedSubtree(
                key: _marketKey,
                child: const FadeSlideIn(child: MarketTableSection()),
              ),
              const FadeSlideIn(child: MarketMapSection()),
              KeyedSubtree(
                key: _partnersKey,
                child: const FadeSlideIn(child: PartnersSection()),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}
