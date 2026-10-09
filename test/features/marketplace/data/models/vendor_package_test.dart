import 'package:eventsrus_ui/features/marketplace/data/models/vendor_package.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('VendorPackage.fromJson parses a FIXED-pricing package with images and groups', () {
    final package = VendorPackage.fromJson({
      'id': 1,
      'name': 'Premium Wedding Package',
      'description': 'Full day coverage',
      'packageType': 'SERVICE',
      'pricingType': 'FIXED',
      'price': 15000.0,
      'minPrice': null,
      'maxPrice': null,
      'active': true,
      'images': [
        {
          'id': 10,
          'imageUrl': 'https://cdn.example.com/photo.jpg',
          'caption': 'Setup',
          'createdAt': '2026-01-01T10:00:00Z',
          'tags': ['featured'],
        },
      ],
      'groups': ['Weddings', 'Premium'],
    });

    expect(package.id, 1);
    expect(package.name, 'Premium Wedding Package');
    expect(package.packageType, PackageType.service);
    expect(package.pricingType, PackagePricingType.fixed);
    expect(package.price, 15000.0);
    expect(package.minPrice, isNull);
    expect(package.active, isTrue);
    expect(package.images, hasLength(1));
    expect(package.images.single.imageUrl, 'https://cdn.example.com/photo.jpg');
    expect(package.images.single.tags, ['featured']);
    expect(package.groups, ['Weddings', 'Premium']);
  });

  test('VendorPackage.fromJson parses a RANGE-pricing package with no images/groups', () {
    final package = VendorPackage.fromJson({
      'id': 2,
      'name': 'Basic Catering',
      'description': null,
      'packageType': 'PRODUCT',
      'pricingType': 'RANGE',
      'price': null,
      'minPrice': 5000.0,
      'maxPrice': 10000.0,
      'active': false,
      'images': [],
      'groups': [],
    });

    expect(package.packageType, PackageType.product);
    expect(package.pricingType, PackagePricingType.range);
    expect(package.minPrice, 5000.0);
    expect(package.maxPrice, 10000.0);
    expect(package.active, isFalse);
    expect(package.images, isEmpty);
    expect(package.groups, isEmpty);
  });

  test('VendorPackage.fromJson parses a QUOTE-pricing package with no price fields', () {
    final package = VendorPackage.fromJson({
      'id': 3,
      'name': 'Custom Event Design',
      'description': null,
      'packageType': 'SERVICE',
      'pricingType': 'QUOTE',
      'price': null,
      'minPrice': null,
      'maxPrice': null,
      'active': true,
    });

    expect(package.pricingType, PackagePricingType.quote);
    expect(package.price, isNull);
    expect(package.minPrice, isNull);
    expect(package.maxPrice, isNull);
    // images/groups are omitted entirely in this payload - must default to
    // empty rather than throwing.
    expect(package.images, isEmpty);
    expect(package.groups, isEmpty);
  });

  test('VendorPackage.fromJson defaults a missing pricingType to FIXED (pre-pricing-types backend compatibility)', () {
    final package = VendorPackage.fromJson({
      'id': 4,
      'name': 'Legacy Package',
      'description': null,
      'packageType': 'SERVICE',
      'price': 100.0,
      'active': true,
    });

    expect(package.pricingType, PackagePricingType.fixed);
  });

  test('every PackagePricingType round-trips through toApi/fromApi', () {
    for (final type in PackagePricingType.values) {
      expect(PackagePricingTypeApi.fromApi(type.toApi()), type);
    }
  });

  test('every PackageType round-trips through toApi/fromApi', () {
    for (final type in PackageType.values) {
      expect(PackageTypeApi.fromApi(type.toApi()), type);
    }
  });
}
