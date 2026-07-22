import 'package:dwelleo_app/core/theme/app_theme.dart';
import 'package:dwelleo_app/features/market_insights/domain/entities/market_insight.dart';
import 'package:dwelleo_app/features/market_insights/presentation/widgets/market_insight_charts.dart';
import 'package:dwelleo_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// LAYOUT REGRESSION GUARD.
///
/// The app theme sets `minimumSize: Size.fromHeight(54)` on buttons, which is
/// `Size(double.infinity, 54)` — an INFINITE minimum width. Any themed button
/// dropped somewhere width is unbounded (a bare Row child, a horizontal
/// ListView) throws "BoxConstraints forces an infinite width" at runtime.
///
/// Unit tests and the analyzer both pass that bug straight through — only
/// pumping the widget catches it. These tests render the charts for real, in
/// both text directions, so a layout break fails CI instead of the device.
MarketInsightSeries _series(MarketInsightChart chart) => MarketInsightSeries(
  chart: chart,
  name: 'Top 15 Cities - Commercial Contracts Growth',
  description: 'Top cities by total rental contracts.',
  baseYear: 2020,
  latestYear: 2024,
  points: const [
    MarketInsightPoint(label: 'Riyadh', base: 10.3, latest: 15.37),
    MarketInsightPoint(label: 'Jeddah', base: 7.57, latest: 12.79),
    MarketInsightPoint(label: 'Sajir', base: 12.96, latest: 35.32),
  ],
);

Widget _host(Widget child, {TextDirection direction = TextDirection.ltr}) {
  return MaterialApp(
    theme: AppTheme.dark,
    locale: Locale(direction == TextDirection.rtl ? 'ar' : 'en'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: SingleChildScrollView(
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    ),
  );
}

void main() {
  group('Market Insights charts render without layout errors', () {
    for (final chart in MarketInsightChart.values) {
      testWidgets('${chart.name} lays out in LTR', (tester) async {
        final series = _series(chart);

        await tester.pumpWidget(
          _host(
            Column(
              children: [
                MarketInsightTotals(series: series),
                switch (chart) {
                  MarketInsightChart.topCitiesCommercialGrowth => DumbbellChart(
                    series: series,
                  ),
                  MarketInsightChart.highestCommercialGrowthCities =>
                    RankedGrowthChart(series: series),
                  MarketInsightChart.commercialUnitsGrowth => RegionGrowthChart(
                    series: series,
                  ),
                },
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Riyadh'), findsOneWidget);
      });

      testWidgets('${chart.name} lays out in RTL', (tester) async {
        final series = _series(chart);

        await tester.pumpWidget(
          _host(
            Column(
              children: [
                MarketInsightTotals(series: series),
                switch (chart) {
                  MarketInsightChart.topCitiesCommercialGrowth => DumbbellChart(
                    series: series,
                  ),
                  MarketInsightChart.highestCommercialGrowthCities =>
                    RankedGrowthChart(series: series),
                  MarketInsightChart.commercialUnitsGrowth => RegionGrowthChart(
                    series: series,
                  ),
                },
              ],
            ),
            direction: TextDirection.rtl,
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('the totals block shows the site-verified growth', (
      tester,
    ) async {
      final series = _series(MarketInsightChart.topCitiesCommercialGrowth);

      await tester.pumpWidget(_host(MarketInsightTotals(series: series)));
      await tester.pumpAndSettle();

      // 30.83 → 63.48 over the three sample rows = +106%.
      expect(find.text('+106%'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an empty series does not throw', (tester) async {
      const empty = MarketInsightSeries(
        chart: MarketInsightChart.commercialUnitsGrowth,
        name: '',
        description: '',
        points: [],
      );

      await tester.pumpWidget(
        _host(
          Column(
            children: [
              MarketInsightTotals(series: empty),
              RegionGrowthChart(series: empty),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
