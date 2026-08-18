import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wed_plan_pilot/core/state/resource.dart';
import 'package:wed_plan_pilot/core/theme/app_theme.dart';
import 'package:wed_plan_pilot/features/vendor/screens/lead_inbox_screen.dart';
import 'package:wed_plan_pilot/models/messaging.dart';
import 'package:wed_plan_pilot/providers/vendor_own_provider.dart';
import 'package:wed_plan_pilot/widgets/wed_button.dart';

/// Answering a lead is the whole job of the inbox, and it used to cost four
/// taps through a dialog stacked on a bottom sheet. It is now one tap with an
/// undo — which only stays safe if the undo actually reverts the status it
/// came from, so that is what these pin.
class _RecordingVendorOwn extends VendorOwnNotifier {
  _RecordingVendorOwn(super.ref, List<Inquiry> inquiries) {
    state = Resource(
      status: ResourceStatus.ready,
      data: VendorOwnState(inquiries: inquiries),
    );
  }

  /// Every (id, status, reason) this notifier was asked to write, in order.
  final List<(String, InquiryStatus, String?)> calls = [];

  /// Set to make the next call fail the way the API layer would.
  String? failWith;

  @override
  Future<String?> markInquiryStatus(
    String id,
    InquiryStatus status, {
    String? declineReason,
  }) async {
    calls.add((id, status, declineReason));
    if (failWith != null) return failWith;

    // Mirror the real notifier: reflect the new status back into state so the
    // card rebuilds the way it would against a live backend. Inquiry has no
    // copyWith, so this rebuilds the row.
    final current = state.data!;
    state = Resource(
      status: ResourceStatus.ready,
      data: VendorOwnState(
        inquiries: [
          for (final i in current.inquiries)
            if (i.id == id) _restatus(i, status) else i,
        ],
      ),
    );
    return null;
  }
}

Inquiry _restatus(Inquiry i, InquiryStatus status) => Inquiry(
      id: i.id,
      coupleId: i.coupleId,
      vendorId: i.vendorId,
      coupleName: i.coupleName,
      status: status,
      message: i.message,
      createdAt: i.createdAt,
      weddingDate: i.weddingDate,
    );

Inquiry _lead(String id, InquiryStatus status) => Inquiry(
      id: id,
      coupleId: 'c1',
      vendorId: 'v1',
      coupleName: 'Amara & Chanda',
      status: status,
      message: 'Are you free on our date?',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    );

Future<_RecordingVendorOwn> _pumpInbox(
  WidgetTester tester, {
  required List<Inquiry> inquiries,
}) async {
  tester.view.physicalSize = const Size(412, 915);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  late _RecordingVendorOwn notifier;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        vendorOwnProvider.overrideWith((ref) {
          notifier = _RecordingVendorOwn(ref, inquiries);
          return notifier;
        }),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: const LeadInboxScreen(),
      ),
    ),
  );
  await tester.pump();
  return notifier;
}

void main() {
  testWidgets('a pending lead can be answered from the card itself',
      (tester) async {
    await _pumpInbox(tester, inquiries: [_lead('i1', InquiryStatus.newInquiry)]);

    // The point of the redesign: no sheet, no dialog, both answers on the card.
    expect(find.widgetWithText(WedButton, 'Accept'), findsOneWidget);
    expect(find.widgetWithText(WedButton, 'Decline'), findsOneWidget);
  });

  testWidgets('accept books in one tap, with no confirmation dialog',
      (tester) async {
    final notifier =
        await _pumpInbox(tester, inquiries: [_lead('i1', InquiryStatus.viewed)]);

    await tester.tap(find.widgetWithText(WedButton, 'Accept'));
    await tester.pump();

    expect(notifier.calls, [('i1', InquiryStatus.booked, null)]);
    expect(find.textContaining('Booked with'), findsOneWidget);
    expect(find.text('UNDO'), findsOneWidget);
  });

  testWidgets('undo reverts to the status the lead came from', (tester) async {
    final notifier =
        await _pumpInbox(tester, inquiries: [_lead('i1', InquiryStatus.quoted)]);

    await tester.tap(find.widgetWithText(WedButton, 'Accept'));
    await tester.pump();
    // Let the snack bar finish sliding in — tapping it mid-animation misses.
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('UNDO'));
    await tester.pump();

    expect(notifier.calls, [
      ('i1', InquiryStatus.booked, null),
      ('i1', InquiryStatus.quoted, null),
    ]);
  });

  testWidgets('undoing a never-opened lead returns it as viewed, not new',
      (tester) async {
    // By the time you can press undo you have certainly seen the lead —
    // putting it back as unread would be a lie the inbox then shows as a dot.
    final notifier = await _pumpInbox(
      tester,
      inquiries: [_lead('i1', InquiryStatus.newInquiry)],
    );

    await tester.tap(find.widgetWithText(WedButton, 'Accept'));
    await tester.pump();
    // Let the snack bar finish sliding in — tapping it mid-animation misses.
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('UNDO'));
    await tester.pump();

    expect(notifier.calls.last, ('i1', InquiryStatus.viewed, null));
  });

  testWidgets('a failed accept surfaces the error and offers no undo',
      (tester) async {
    final notifier =
        await _pumpInbox(tester, inquiries: [_lead('i1', InquiryStatus.viewed)]);
    notifier.failWith = 'You already have a confirmed booking on this date.';

    await tester.tap(find.widgetWithText(WedButton, 'Accept'));
    await tester.pump();

    expect(
      find.text('You already have a confirmed booking on this date.'),
      findsOneWidget,
    );
    // Offering to undo something that never happened would be worse than
    // saying nothing.
    expect(find.text('UNDO'), findsNothing);
  });

  testWidgets('decline asks first — it is final for the couple',
      (tester) async {
    final notifier =
        await _pumpInbox(tester, inquiries: [_lead('i1', InquiryStatus.viewed)]);

    await tester.tap(find.widgetWithText(WedButton, 'Decline'));
    await tester.pump();

    expect(find.text('Decline this booking?'), findsOneWidget);
    // Nothing is written until the vendor confirms.
    expect(notifier.calls, isEmpty);

    await tester.tap(find.text('Keep it'));
    await tester.pump();
    expect(notifier.calls, isEmpty);
  });

  testWidgets('confirming a decline writes a reason', (tester) async {
    final notifier =
        await _pumpInbox(tester, inquiries: [_lead('i1', InquiryStatus.viewed)]);

    await tester.tap(find.widgetWithText(WedButton, 'Decline'));
    await tester.pump();
    await tester.tap(find.text('Yes, decline'));
    await tester.pump();

    expect(notifier.calls.length, 1);
    final (id, status, reason) = notifier.calls.single;
    expect(id, 'i1');
    expect(status, InquiryStatus.declined);
    // The backend rejects a blank reason, so the dialog must always send one.
    expect(reason, isNotNull);
    expect(reason, isNotEmpty);
  });

  testWidgets('an already-answered lead offers no accept or decline',
      (tester) async {
    await _pumpInbox(tester, inquiries: [_lead('i1', InquiryStatus.booked)]);

    expect(find.widgetWithText(WedButton, 'Accept'), findsNothing);
    expect(find.widgetWithText(WedButton, 'Decline'), findsNothing);
  });

  group('lays out without overflow', () {
    // The booked state adds the "Awaiting service"/"Awaiting rating" chip and
    // the service-done section, which is where the reported overflow was.
    for (final status in const [
      InquiryStatus.newInquiry,
      InquiryStatus.viewed,
      InquiryStatus.booked,
      InquiryStatus.declined,
    ]) {
      for (final width in const [320.0, 360.0, 412.0]) {
        testWidgets('${status.name} at ${width.toInt()}px', (tester) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                vendorOwnProvider.overrideWith(
                  (ref) => _RecordingVendorOwn(ref, [
                    _lead('i1', status),
                    _lead('i2', status),
                  ]),
                ),
              ],
              child: MaterialApp(
                theme: AppTheme.light,
                home: const LeadInboxScreen(),
              ),
            ),
          );
          await tester.pump();

          expect(tester.takeException(), isNull,
              reason: '${status.name} lead overflowed at ${width}px');

          // And with the detail sheet open — that is where the service-done
          // section and the action buttons live, none of which the list shows.
          await tester.tap(find.text('Amara & Chanda').first);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));

          expect(tester.takeException(), isNull,
              reason: '${status.name} detail sheet overflowed at ${width}px');
        });
      }
    }
  });
}
