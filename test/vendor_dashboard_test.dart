import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wed_plan_pilot/core/state/resource.dart';
import 'package:wed_plan_pilot/core/theme/app_theme.dart';
import 'package:wed_plan_pilot/features/vendor/screens/vendor_dashboard_screen.dart';
import 'package:wed_plan_pilot/models/messaging.dart';
import 'package:wed_plan_pilot/models/notification_model.dart';
import 'package:wed_plan_pilot/models/vendor_profile.dart';
import 'package:wed_plan_pilot/providers/notification_provider.dart';
import 'package:wed_plan_pilot/providers/vendor_own_provider.dart';

/// The dashboard's numbers are all derived, not stored — inquiries this week,
/// new-inquiry badge, bookings today. These pin that each one counts the
/// right rows.
final _vendor = VendorProfile(
  id: 'v1',
  userId: 'u1',
  businessName: 'Kabwe Bridal & Tailoring',
  category: 'Attire',
  location: 'Ndola',
  tier: VendorTier.pro,
  verificationStatus: VerificationStatus.verified,
  rating: 4.8,
  feedbackCount: 24,
  compositeScore: 88,
);

Inquiry _inq(
  String id,
  InquiryStatus status, {
  int daysAgo = 1,
  DateTime? weddingDate,
}) =>
    Inquiry(
      id: id,
      coupleId: 'c1',
      vendorId: 'v1',
      status: status,
      message: 'Are you free?',
      createdAt: DateTime.now().subtract(Duration(days: daysAgo)),
      weddingDate: weddingDate,
    );

class _FakeVendorOwn extends VendorOwnNotifier {
  _FakeVendorOwn(super.ref, VendorOwnState data) {
    state = Resource(status: ResourceStatus.ready, data: data);
  }
}

NotificationModel _notif(String id, {required bool isRead}) => NotificationModel(
      id: id,
      userId: 'u1',
      type: 'inquiry',
      title: 'New inquiry',
      body: 'body',
      isRead: isRead,
      sentAt: DateTime.now(),
    );

Future<void> _pumpDashboard(
  WidgetTester tester, {
  required VendorOwnState data,
  List<NotificationModel> notifications = const [],
  Size size = const Size(390, 844),
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        vendorOwnProvider.overrideWith((ref) => _FakeVendorOwn(ref, data)),
        notificationsProvider.overrideWith((ref) async => notifications),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const VendorDashboardScreen(),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  final today = DateTime.now();

  final fullState = VendorOwnState(
    profile: _vendor,
    inquiries: [
      _inq('1', InquiryStatus.newInquiry),
      _inq('2', InquiryStatus.newInquiry),
      _inq('3', InquiryStatus.newInquiry),
      _inq('4', InquiryStatus.viewed, daysAgo: 2),
      // Older than a week, so it counts toward "total" but not "this week".
      _inq('5', InquiryStatus.booked, daysAgo: 20, weddingDate: today),
    ],
    services: List.generate(
      4,
      (i) => VendorService(
        id: 's$i',
        vendorId: 'v1',
        title: 'Package $i',
        priceMin: 1000,
        priceMax: 2000,
        unit: 'package',
      ),
    ),
  );

  testWidgets('renders the header, both stats and every action card',
      (tester) async {
    await _pumpDashboard(tester, data: fullState);

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Kabwe Bridal & Tailoring'), findsWidgets);

    // 4 of the 5 inquiries were created inside the last week.
    expect(find.text('Inquiries this week'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('Average rating'), findsOneWidget);
    expect(find.text('4.8'), findsOneWidget);

    for (final label in const [
      'Listings',
      'Inquiries',
      'Feedback',
      'Calendar',
      'Analytics',
      'Upgrade',
    ]) {
      expect(find.text(label), findsOneWidget, reason: '$label card missing');
    }

    expect(find.text('4 active'), findsOneWidget);
    expect(find.text('5 total'), findsOneWidget);
    expect(find.text('4.8 avg'), findsOneWidget);
    expect(find.text('Go Pro'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('the new-inquiry badge counts only newInquiry rows',
      (tester) async {
    await _pumpDashboard(tester, data: fullState);
    expect(find.text('3 new'), findsOneWidget);
  });

  testWidgets('no badge when nothing is new', (tester) async {
    await _pumpDashboard(
      tester,
      data: VendorOwnState(
        profile: _vendor,
        inquiries: [_inq('1', InquiryStatus.viewed)],
      ),
    );
    expect(find.textContaining(' new'), findsNothing);
  });

  testWidgets("calendar counts today's confirmed bookings only",
      (tester) async {
    await _pumpDashboard(tester, data: fullState);
    // Only inquiry 5 is booked with a wedding date of today.
    expect(find.text('1 today'), findsOneWidget);
  });

  testWidgets('the bell badge shows unread notifications only',
      (tester) async {
    await _pumpDashboard(
      tester,
      data: fullState,
      notifications: [
        _notif('a', isRead: false),
        _notif('b', isRead: false),
        _notif('c', isRead: true),
      ],
    );
    await tester.pump();
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('a vendor with no ratings does not show a fake average',
      (tester) async {
    await _pumpDashboard(
      tester,
      data: const VendorOwnState(profile: null),
    );
    expect(find.text('—'), findsOneWidget);
    expect(find.text('No ratings yet'), findsOneWidget);
  });

  testWidgets('the header logout icon asks for confirmation before signing out',
      (tester) async {
    await _pumpDashboard(tester, data: fullState);

    expect(find.text('Are you sure you want to log out?'), findsNothing);
    await tester.tap(find.byTooltip('Log out'));
    await tester.pumpAndSettle();

    // "Log Out" appears twice — the dialog title and the confirm button —
    // so the unique prompt text is what pins the dialog actually opened.
    expect(find.text('Are you sure you want to log out?'), findsOneWidget);

    // Cancel dismisses without navigating away from this screen.
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Are you sure you want to log out?'), findsNothing);
  });

  group('lays out without overflow', () {
    for (final size in const [
      Size(320, 568),
      Size(390, 844),
      Size(412, 915),
      Size(768, 1024),
    ]) {
      // Both axes matter: the action cards' height is driven by their text,
      // so a narrow screen and a large type scale fail for different reasons.
      for (final scale in const [1.0, 1.3]) {
        testWidgets('${size.width.toInt()}x${size.height.toInt()} @ ${scale}x',
            (tester) async {
          await _pumpDashboard(
            tester,
            data: fullState,
            size: size,
            textScale: scale,
          );
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}
