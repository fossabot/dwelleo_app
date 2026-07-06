import 'package:dwelleo_app/features/properties/data/models/property_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // A trimmed payload mirroring the REAL dwelleo.sa /api/v1/properties schema
  // (see docs/api/REAL_API_SPEC.md).
  final realEnvelope = <String, dynamic>{
    'message': null,
    'data': {
      'properties': [
        {
          'id': 12345,
          'slug': 'luxury-villa-in-al-rahmaniya',
          'title': 'Luxury Villa in Al Rahmaniya',
          'description': 'Elegant design & premium finishes',
          'price': 1300000,
          'area_sqm': 275,
          'bedrooms': 6,
          'bathrooms': 5,
          'maid_room': 1,
          'driver_room': 0,
          'floor_number': 2,
          'is_featured': true,
          'is_favorite': false,
          'is_boosted': false,
          'furnishing_status': 'unfurnished',
          'availability_status': 'available',
          'land_type': 'residential',
          'listing_type': {'key': 'for-sale', 'label': 'بيع'},
          'property_type': {
            'id': 2,
            'name': 'Villa',
            'translations': {
              'ar': {'name': 'فيلا'},
              'en': {'name': 'Villa'},
            },
          },
          'city': {'id': 11, 'name': 'Jeddah'},
          'region': {'id': 3, 'name': 'Makkah'},
          'owner': {
            'id': 357,
            'name': 'Al Khalidiya',
            'phone': '0567777390',
            'verified': true,
            'user_type': 'developer',
            'image': {
              'id': 24054,
              'path': 'https://s3.example.com/24054/logo.png',
              'path_thumbnail': 'https://s3.example.com/24054/logo_t.png',
              'mime_type': 'image/png',
            },
          },
          'image': {
            'id': 1,
            'path': 'https://s3.example.com/1/cover.jpg',
            'path_thumbnail': 'https://s3.example.com/1/cover_t.jpg',
            'mime_type': 'image/jpeg',
          },
          'images': [
            {'id': 2, 'path': 'https://s3.example.com/2/a.jpg'},
            {'id': 3, 'path': 'https://s3.example.com/3/b.jpg'},
          ],
          'location': {
            'address': 'Al Rahmaniya, Jeddah',
            'lat': 21.5,
            'lng': 39.2,
            'ad_license_number': '7200123456',
            'direction': 'north',
            'building_year': '2023',
          },
          'amenities': [
            {'id': 1, 'title': 'Pool'},
            {'id': 2, 'title': 'Gym'},
          ],
          'tags': [
            {'id': 9, 'title': 'New Listing', 'color': '#8CC63F'},
          ],
          'handover_date': '2025-12-01',
        },
      ],
    },
  };

  group('PropertyModel.listFromEnvelope', () {
    test('parses the real envelope into one property', () {
      final result = PropertyModel.listFromEnvelope(realEnvelope);
      expect(result, hasLength(1));
    });

    test('maps core scalar fields correctly', () {
      final p = PropertyModel.listFromEnvelope(realEnvelope).first;
      expect(p.id, 12345);
      expect(p.slug, 'luxury-villa-in-al-rahmaniya');
      expect(p.title, 'Luxury Villa in Al Rahmaniya');
      expect(p.price, 1300000);
      expect(p.areaSqm, 275);
      expect(p.bedrooms, 6);
      expect(p.bathrooms, 5);
      expect(p.isFeatured, isTrue);
      expect(p.isFavorite, isFalse);
      expect(p.furnishingStatus, 'unfurnished');
      expect(p.landType, 'residential');
    });

    test('maps nested objects (listing type, refs, owner, location)', () {
      final p = PropertyModel.listFromEnvelope(realEnvelope).first;
      expect(p.listingType?.key, 'for-sale');
      expect(p.listingType?.isForSale, isTrue);
      expect(p.propertyType?.name, 'Villa');
      expect(p.city?.name, 'Jeddah');
      expect(p.cityName, 'Jeddah');
      expect(p.owner?.userType, 'developer');
      expect(p.owner?.verified, isTrue);
      expect(p.location?.adLicenseNumber, '7200123456');
      expect(p.location?.point?.lat, 21.5);
    });

    test('maps media and collections', () {
      final p = PropertyModel.listFromEnvelope(realEnvelope).first;
      expect(p.coverImage?.path, 'https://s3.example.com/1/cover.jpg');
      expect(
        p.coverImage?.displayThumb,
        'https://s3.example.com/1/cover_t.jpg',
      );
      expect(p.images, hasLength(2));
      expect(p.amenities, hasLength(2));
      expect(p.tags.first.title, 'New Listing');
      expect(p.hasMaidRoom, isTrue);
      expect(p.hasDriverRoom, isFalse);
    });
  });

  group('type tolerance', () {
    test('parses numeric strings (price/area as String)', () {
      final p = PropertyModel.fromJson({
        'id': '77',
        'slug': 's',
        'title': 't',
        'price': '1,049,040',
        'area_sqm': '109',
        'bedrooms': '2',
      });
      expect(p.id, 77);
      expect(p.price, 1049040);
      expect(p.areaSqm, 109);
      expect(p.bedrooms, 2);
    });

    test('handles missing/null fields without throwing', () {
      final p = PropertyModel.fromJson({'id': 1, 'slug': 'x', 'title': 'y'});
      expect(p.listingType, isNull);
      expect(p.images, isEmpty);
      expect(p.amenities, isEmpty);
      expect(p.cityName, isNull);
    });

    test('empty/garbage envelope yields empty list', () {
      expect(PropertyModel.listFromEnvelope({'data': {}}), isEmpty);
      expect(PropertyModel.listFromEnvelope({}), isEmpty);
    });
  });

  group('detailFromEnvelope', () {
    test('reads property from data wrapper', () {
      final detail = PropertyModel.detailFromEnvelope({
        'data': {'id': 5, 'slug': 'abc', 'title': 'Detail'},
      });
      expect(detail.id, 5);
      expect(detail.slug, 'abc');
    });

    test('reads property from nested data.property wrapper', () {
      final detail = PropertyModel.detailFromEnvelope({
        'data': {
          'property': {'id': 9, 'slug': 'def', 'title': 'Nested'},
        },
      });
      expect(detail.id, 9);
      expect(detail.title, 'Nested');
    });
  });
}
