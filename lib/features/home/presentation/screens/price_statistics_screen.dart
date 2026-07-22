import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/dwelleo_app_bar.dart';
import '../cubit/market_stats_cubit.dart';
import '../widgets/market_table_section.dart';

/// Full-page Price Statistics (owner review: the home quick action must be a
/// real feature). Reuses the LIVE City Intelligence table — /market/cities
/// with the Buy|Rent x Apartment|Villa toggles and animated bars.
class PriceStatisticsScreen extends StatelessWidget {
  const PriceStatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DwelleoAppBar(),
      body: BlocProvider(
        create: (_) => sl<MarketStatsCubit>()..load(),
        child: ListView(
          padding: const EdgeInsets.only(bottom: 28),
          children: const [MarketTableSection()],
        ),
      ),
    );
  }
}
