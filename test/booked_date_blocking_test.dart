import 'package:flutter_test/flutter_test.dart';
import 'package:wed_plan_pilot/core/services/vendor_filtering_service.dart';
import 'package:wed_plan_pilot/models/vendor_profile.dart';

/// Accepting a booking writes the wedding date into `vendor.blocked_dates`
/// server-side, and the matcher must then keep that vendor away from any
/// other couple marrying on the same day — a vendor cannot be in two places
/// at once, so proposing them again is a promise the app can't keep.
///
/// Nothing asserted this before: the exclusion stage existed but was only
/// exercised incidentally by the pipeline tests, which never checked that a
/// blocked vendor actually disappears.
VendorProfile _vendor({
  required String id,
  required String category,
  List<String> blockedDates = const [],
}) =>
    VendorProfile(
      id: id,
      userId: 'user-$id',
      businessName: 'Vendor $id',
      category: category,
      location: 'Ndola, Copperbelt',
      tier: VendorTier.pro,
      verificationStatus: VerificationStatus.verified,
      rating: 4.5,
      feedbackCount: 20,
      compositeScore: 80,
      blockedDates: blockedDates,
      services: [
        VendorService(
          id: '$id-svc',
          vendorId: id,
          title: 'Package',
          priceMin: 20000,
          priceMax: 20000,
          unit: 'package',
          maxGuests: 500,
        ),
      ],
    );

void main() {
  const weddingDay = '2026-09-12';

  test('a vendor booked on the wedding date is dropped from the pool', () {
    final result = VendorFilteringService.excludeBookedOnDate({
      'Photography': [
        _vendor(id: 'free', category: 'Photography'),
        _vendor(
          id: 'taken',
          category: 'Photography',
          blockedDates: const [weddingDay],
        ),
      ],
    }, weddingDay);

    expect(result['Photography']!.map((v) => v.id), ['free']);
  });

  test('a booking on a different date does not block the vendor', () {
    final result = VendorFilteringService.excludeBookedOnDate({
      'Catering': [
        _vendor(
          id: 'busy-elsewhere',
          category: 'Catering',
          blockedDates: const ['2026-01-04', '2027-03-30'],
        ),
      ],
    }, weddingDay);

    expect(result['Catering']!.map((v) => v.id), ['busy-elsewhere']);
  });

  test('with no wedding date set, nothing is excluded', () {
    final pool = {
      'Decor': [
        _vendor(
          id: 'taken',
          category: 'Decor',
          blockedDates: const [weddingDay],
        ),
      ],
    };

    expect(
      VendorFilteringService.excludeBookedOnDate(pool, null)['Decor']!.length,
      1,
    );
    expect(
      VendorFilteringService.excludeBookedOnDate(pool, '')['Decor']!.length,
      1,
    );
  });

  test(
    'a category where every vendor is booked falls back to showing them, '
    'rather than showing the couple an empty category',
    () {
      final result = VendorFilteringService.excludeBookedOnDate({
        'Venue': [
          _vendor(
            id: 'a',
            category: 'Venue',
            blockedDates: const [weddingDay],
          ),
          _vendor(
            id: 'b',
            category: 'Venue',
            blockedDates: const [weddingDay],
          ),
        ],
      }, weddingDay);

      // Deliberate: the scoring penalty demotes them and the card warns
      // "already appears booked on your wedding date". An empty Venue
      // category would be a worse answer than a caveated one.
      expect(result['Venue']!.map((v) => v.id), ['a', 'b']);
    },
  );

  test('blocking is per category — one booked vendor does not clear others',
      () {
    final result = VendorFilteringService.excludeBookedOnDate({
      'Photography': [
        _vendor(
          id: 'photo-taken',
          category: 'Photography',
          blockedDates: const [weddingDay],
        ),
        _vendor(id: 'photo-free', category: 'Photography'),
      ],
      'Catering': [_vendor(id: 'cater-free', category: 'Catering')],
    }, weddingDay);

    expect(result['Photography']!.map((v) => v.id), ['photo-free']);
    expect(result['Catering']!.map((v) => v.id), ['cater-free']);
  });
}
