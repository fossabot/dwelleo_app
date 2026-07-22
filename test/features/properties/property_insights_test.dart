import 'package:dwelleo_app/features/properties/data/models/property_model.dart';
import 'package:dwelleo_app/features/properties/domain/entities/property.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Property.galleryImages (duplicate first-image bug)', () {
    test('drops the cover when it is already the first entry of images', () {
      // Reproduces the owner-reported bug: the API's `images` array already
      // contains the cover, so prepending `image` (cover) duplicated the
      // first photo. dedupe by path must remove it.
      const cover = MediaImage(id: 1, path: 'https://s3/cover.jpg');
      const property = Property(
        id: 1,
        slug: 'villa',
        title: 'Villa',
        coverImage: cover,
        images: [
          MediaImage(id: 1, path: 'https://s3/cover.jpg'),
          MediaImage(id: 2, path: 'https://s3/second.jpg'),
        ],
      );

      final gallery = property.galleryImages;

      expect(gallery, hasLength(2));
      expect(gallery.first.path, 'https://s3/cover.jpg');
      expect(gallery[1].path, 'https://s3/second.jpg');
    });

    test('keeps the cover first when images does NOT contain it', () {
      const property = Property(
        id: 1,
        slug: 'villa',
        title: 'Villa',
        coverImage: MediaImage(id: 1, path: 'https://s3/cover.jpg'),
        images: [MediaImage(id: 2, path: 'https://s3/second.jpg')],
      );

      final gallery = property.galleryImages;

      expect(gallery.map((i) => i.path), [
        'https://s3/cover.jpg',
        'https://s3/second.jpg',
      ]);
    });

    test('no cover → gallery is just the images, still deduped', () {
      const property = Property(
        id: 1,
        slug: 'villa',
        title: 'Villa',
        images: [
          MediaImage(id: 2, path: 'https://s3/a.jpg'),
          MediaImage(id: 3, path: 'https://s3/a.jpg'),
          MediaImage(id: 4, path: 'https://s3/b.jpg'),
        ],
      );

      expect(property.galleryImages.map((i) => i.path), [
        'https://s3/a.jpg',
        'https://s3/b.jpg',
      ]);
    });

    test('empty when there are no images at all', () {
      const property = Property(id: 1, slug: 'villa', title: 'Villa');
      expect(property.galleryImages, isEmpty);
    });
  });

  group('AI insights parsing (verified public payload)', () {
    Property parse(Map<String, dynamic> insights) =>
        PropertyModel.detailFromEnvelope({
          'data': {
            'property': {
              'id': 1,
              'slug': 'villa',
              'title': 'Villa',
              ...insights,
            },
          },
        });

    test('price_prediction maps min/mid/max/predicted', () {
      final p = parse({
        'price_prediction': {
          'min_price': 1000000,
          'mid_price': 1250000,
          'max_price': 1500000,
          'predicted_price': 1300000,
        },
      });

      expect(p.pricePrediction, isNotNull);
      expect(p.pricePrediction!.min, 1000000);
      expect(p.pricePrediction!.mid, 1250000);
      expect(p.pricePrediction!.max, 1500000);
      expect(p.pricePrediction!.predicted, 1300000);
    });

    test('price_prediction is null when the API omits it', () {
      expect(parse(const {}).pricePrediction, isNull);
    });

    test('investment_scores maps total, factors, and bilingual reasons', () {
      final p = parse({
        'investment_scores': {
          'total_score': 82,
          'value_vs_market_score': 70,
          'location_quality_score': 90,
          'income_return_score': 60,
          'market_saturation_score': 75,
          'benchmark_level': 'excellent',
          'reasons': {
            'value_vs_market': {
              'en': 'Priced below comparable listings',
              'ar': 'السعر أقل من العقارات المماثلة',
            },
          },
        },
      });

      final inv = p.investmentScores;
      expect(inv, isNotNull);
      expect(inv!.total, 82);
      expect(inv.valueVsMarket, 70);
      expect(inv.locationQuality, 90);
      expect(inv.benchmarkLevel, 'excellent');

      final reason = inv.reason('value_vs_market');
      expect(reason, isNotNull);
      // The API ships BOTH languages, so switching never refetches.
      expect(reason!.forArabic(true), 'السعر أقل من العقارات المماثلة');
      expect(reason.forArabic(false), 'Priced below comparable listings');
    });

    test('investment_scores is null without a total_score', () {
      expect(parse({'investment_scores': const {}}).investmentScores, isNull);
    });

    test('lifestyle_score maps total and per-metric scores', () {
      final p = parse({
        'lifestyle_score': {
          'scores': {'lifestyle_total': 88, 'walkability': 72, 'noise': 40},
        },
      });

      final life = p.lifestyleScore;
      expect(life, isNotNull);
      expect(life!.total, 88);
      expect(life.metrics['walkability'], 72);
      expect(life.metrics['noise'], 40);
      // lifestyle_total must not leak into the per-metric bars.
      expect(life.metrics.containsKey('lifestyle_total'), isFalse);
    });
  });
}
