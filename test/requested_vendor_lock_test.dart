import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wed_plan_pilot/models/messaging.dart';
import 'package:wed_plan_pilot/models/vendor_profile.dart';
import 'package:wed_plan_pilot/providers/booking_provider.dart';
import 'package:wed_plan_pilot/providers/vendor_ai_provider.dart';
import 'package:wed_plan_pilot/providers/vendor_provider.dart';

/// A vendor the couple has already sent a booking request to is a decision,
/// not a candidate. Re-running the plan must not re-propose them, must not
/// quietly swap them for a different vendor in the same category, and must
/// treat the money already committed to them as spent.
///
/// Before this, nothing between the vendor pool fetch and the final picks in
/// `vendorMatchValidationProvider` knew the couple's inquiries existed at all,
/// so every re-run re-decided categories the couple had already acted on.

VendorProfile _vendor({
  required String id,
  required String category,
  required String name,
  double price = 20000,
}) =>
    VendorProfile(
      id: id,
      userId: 'user-$id',
      businessName: name,
      category: category,
      location: 'Ndola, Copperbelt',
      tier: VendorTier.pro,
      verificationStatus: VerificationStatus.verified,
      rating: 4.5,
      feedbackCount: 20,
      compositeScore: 80,
      services: [
        VendorService(
          id: '$id-svc',
          vendorId: id,
          title: 'Package',
          priceMin: price,
          priceMax: price,
          unit: 'package',
          // Stated capacity lives on the service; VendorProfile derives
          // maxGuestCapacity from it. Set high so the guest-capacity stage
          // never removes a fixture and confuses these assertions.
          maxGuests: 500,
        ),
      ],
    );

Inquiry _inquiry(String vendorId, InquiryStatus status) => Inquiry(
      id: 'inq-$vendorId-${status.name}',
      coupleId: 'couple-1',
      vendorId: vendorId,
      status: status,
      message: 'test',
      createdAt: DateTime(2026, 1, 1),
    );

final _pool = [
  _vendor(id: 'venue-1', category: 'Venue', name: 'Grand Hall', price: 30000),
  _vendor(id: 'venue-2', category: 'Venue', name: 'Garden Estate', price: 25000),
  _vendor(id: 'catering-1', category: 'Catering', name: 'Zambezi Catering', price: 20000),
  _vendor(id: 'catering-2', category: 'Catering', name: 'Copper Pot', price: 18000),
];

/// Builds a container wired to a fixed vendor pool and a fixed set of the
/// couple's own bookings. [vendorPoolProvider] is the same seam the real
/// pipeline reads from, so this exercises production wiring rather than a
/// parallel code path.
ProviderContainer _container({required List<Inquiry> bookings}) {
  final container = ProviderContainer(
    overrides: [
      vendorPoolProvider.overrideWith((ref, categories) async => _pool),
      myBookingsProvider.overrideWith((ref) async => bookings),
    ],
  );
  addTearDown(container.dispose);
  container.read(selectedServiceCategoriesProvider.notifier).state =
      ['Venue', 'Catering'];
  container.read(wizardLocationProvider.notifier).state = 'Ndola';
  container.read(wizardBudgetProvider.notifier).state = 200000;
  container.read(wizardGuestCountProvider.notifier).state = 100;
  return container;
}

void main() {
  test('a vendor with a live request locks its category and leaves the pool',
      () async {
    final container = _container(
      bookings: [_inquiry('catering-1', InquiryStatus.newInquiry)],
    );

    final result = await container.read(vendorMatchValidationProvider.future);

    expect(result.lockedCategories.keys, contains('Catering'),
        reason: 'Catering was already requested, so it must be locked');
    expect(result.lockedCategories['Catering']!.vendor.id, 'catering-1');

    // The locked category never reaches scoring at all — not even to pick a
    // *different* caterer, which would silently override the couple's choice.
    expect(result.byCategory.keys, isNot(contains('Catering')));
    expect(result.byCategory.keys, contains('Venue'));

    final everyCandidate =
        result.byCategory.values.expand((v) => v).map((v) => v.id);
    expect(everyCandidate, isNot(contains('catering-1')));
    expect(everyCandidate, isNot(contains('catering-2')),
        reason: 'the whole category is settled, not just that one vendor');
  });

  test('an accepted booking locks its category too', () async {
    final container = _container(
      bookings: [_inquiry('venue-1', InquiryStatus.booked)],
    );

    final result = await container.read(vendorMatchValidationProvider.future);

    expect(result.lockedCategories.keys, contains('Venue'));
    expect(result.byCategory.keys, isNot(contains('Venue')));
  });

  for (final finished in [InquiryStatus.declined, InquiryStatus.cancelled]) {
    test('a ${finished.name} request locks nothing — the vendor is matchable again',
        () async {
      final container = _container(
        bookings: [_inquiry('catering-1', finished)],
      );

      final result = await container.read(vendorMatchValidationProvider.future);

      expect(result.lockedCategories, isEmpty,
          reason: '${finished.name} is finished business and frees the category');
      expect(result.byCategory.keys, contains('Catering'));
      expect(
        result.byCategory['Catering']!.map((v) => v.id),
        contains('catering-1'),
        reason: 'the vendor itself must be re-proposable after a ${finished.name}',
      );
    });
  }

  test('the newest request wins when a vendor has finished ones behind it',
      () async {
    final container = _container(
      bookings: [
        Inquiry(
          id: 'old',
          coupleId: 'couple-1',
          vendorId: 'catering-1',
          status: InquiryStatus.declined,
          message: 'first try',
          createdAt: DateTime(2026, 1, 1),
        ),
        Inquiry(
          id: 'new',
          coupleId: 'couple-1',
          vendorId: 'catering-1',
          status: InquiryStatus.newInquiry,
          message: 'asked again',
          createdAt: DateTime(2026, 2, 1),
        ),
      ],
    );

    final result = await container.read(vendorMatchValidationProvider.future);

    expect(result.lockedCategories.keys, contains('Catering'));
    expect(result.lockedCategories['Catering']!.inquiry.id, 'new');
  });

  test('money committed to a requested vendor is not re-offered to other categories',
      () async {
    // Budget is exactly the two cheapest picks together, so if the locked
    // caterer's 20,000 were not deducted the venue would be funded from money
    // that is already spoken for.
    final locked = _container(
      bookings: [_inquiry('catering-1', InquiryStatus.newInquiry)],
    );
    locked.read(wizardBudgetProvider.notifier).state = 45000;

    final result = await locked.read(vendorMatchValidationProvider.future);

    expect(result.lockedCategories.keys, contains('Catering'));
    final venueCeiling = result.categoryBudgets['Venue'];
    expect(venueCeiling, isNotNull);
    expect(venueCeiling! <= 45000 - 20000 + 0.01, isTrue,
        reason: 'Venue was funded ${venueCeiling.toStringAsFixed(0)} from a '
            '45,000 budget with 20,000 already committed to Catering');
  });

  test('with every category requested there is nothing left to match', () async {
    final container = _container(
      bookings: [
        _inquiry('venue-1', InquiryStatus.newInquiry),
        _inquiry('catering-1', InquiryStatus.booked),
      ],
    );

    final result = await container.read(vendorMatchValidationProvider.future);

    // A success state, not a failure — the couple has simply finished.
    expect(result.isBlocked, isFalse);
    expect(result.lockedCategories.keys, containsAll(['Venue', 'Catering']));
    expect(result.byCategory, isEmpty);
  });

  test('with no requests at all nothing is locked', () async {
    final container = _container(bookings: const []);

    final result = await container.read(vendorMatchValidationProvider.future);

    expect(result.lockedCategories, isEmpty);
    expect(result.byCategory.keys, containsAll(['Venue', 'Catering']));
  });
}
