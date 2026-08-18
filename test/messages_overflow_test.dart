import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wed_plan_pilot/core/theme/app_theme.dart';
import 'package:wed_plan_pilot/features/couple/screens/chat_screen.dart';
import 'package:wed_plan_pilot/features/couple/screens/couple_messages_screen.dart';
import 'package:wed_plan_pilot/models/messaging.dart';
import 'package:wed_plan_pilot/providers/messaging_provider.dart';

/// The conversation row packs an avatar, a vendor name, a timestamp, a message
/// preview and an unread badge onto two lines. Every one of those is variable
/// width, and the worst case — a long business name next to a long relative
/// timestamp, with a three-digit unread count — is exactly what a real inbox
/// produces after a busy week.
Conversation _conv({
  required String id,
  String? vendorName,
  String? lastMessage,
  DateTime? lastAt,
  int unread = 0,
}) =>
    Conversation(
      id: id,
      coupleId: 'c1',
      vendorId: 'v-$id',
      vendorName: vendorName,
      lastMessageText: lastMessage,
      lastMessageAt: lastAt,
      unreadCount: unread,
    );

Future<void> _pump(
  WidgetTester tester,
  List<Conversation> conversations, {
  required double width,
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        conversationsProvider.overrideWith((ref) async => conversations),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const CoupleMessagesScreen(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  final now = DateTime.now();

  final worstCase = [
    _conv(
      id: '1',
      vendorName: 'Chembe Gardens Conference & Events Centre, Lusaka',
      lastMessage:
          'Thank you for reaching out about your wedding on the 12th of '
          'September — we do still have that date available and would love '
          'to talk through the package options with you.',
      lastAt: now.subtract(const Duration(days: 400)),
      unread: 128,
    ),
    _conv(id: '2', vendorName: 'Kabwe Bridal & Tailoring'),
    _conv(
      id: '3',
      vendorName: null,
      lastMessage: null,
      lastAt: now.subtract(const Duration(minutes: 3)),
      unread: 1,
    ),
  ];

  group('conversation list fits', () {
    for (final width in const [320.0, 360.0, 412.0]) {
      for (final scale in const [1.0, 1.3]) {
        testWidgets('${width.toInt()}px @ ${scale}x', (tester) async {
          await _pump(tester, worstCase, width: width, textScale: scale);
          expect(tester.takeException(), isNull,
              reason: 'conversation row overflowed at ${width}px, scale $scale');
        });
      }
    }
  });

  testWidgets('the empty state fits too', (tester) async {
    await _pump(tester, const [], width: 320, textScale: 1.3);
    expect(find.text('No conversations yet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  // ── The thread itself ────────────────────────────────────────────────────
  //
  // The bubble caps at 72% of the screen and wraps, which handles prose. What
  // it cannot wrap is a single unbreakable token — a pasted URL or a long
  // reference number — because Flutter only breaks at word boundaries.
  group('chat thread fits', () {
    Future<void> pumpChat(
      WidgetTester tester,
      List<Message> messages, {
      required double width,
      double textScale = 1.0,
    }) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            conversationsProvider.overrideWith((ref) async => [
                  _conv(id: 'c', vendorName: 'Chembe Gardens Events Centre'),
                ]),
            chatMessagesProvider('c').overrideWith(
              (ref) => _StaticChat(ref, messages),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(textScale)),
              child: child!,
            ),
            home: const ChatScreen(convoId: 'c'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
    }

    Message msg(String id, String content, {bool mine = true}) => Message(
          id: id,
          convoId: 'c',
          senderId: mine ? 'me' : 'them',
          content: content,
          sentAt: DateTime.now(),
        );

    final hostile = [
      msg('1', 'Hi! Are you free on the 12th?'),
      // A pasted link with no spaces — the classic unbreakable token.
      msg('2',
          'https://www.chembegardens.co.zm/packages/2026/september/luxury-garden-marquee-package-full-details'),
      msg('3', 'A' * 120, mine: false),
      msg('4',
          'Thank you so much for getting in touch about your wedding — we do '
          'still have that date available and would love to walk you through '
          'the package options in person.',
          mine: false),
    ];

    for (final width in const [320.0, 360.0, 412.0]) {
      for (final scale in const [1.0, 1.3]) {
        testWidgets('${width.toInt()}px @ ${scale}x', (tester) async {
          await pumpChat(tester, hostile, width: width, textScale: scale);
          expect(tester.takeException(), isNull,
              reason: 'chat bubble overflowed at ${width}px, scale $scale');
        });
      }
    }
  });
}

/// A chat notifier that just holds the messages it was given.
///
/// [load] is overridden to a no-op: the real one runs from the constructor and
/// would asynchronously overwrite the fixture with an empty list once its
/// (token-less) fetch resolved.
class _StaticChat extends ChatNotifier {
  _StaticChat(Ref ref, this._messages) : super(ref, 'c') {
    state = AsyncValue.data(_messages);
  }

  final List<Message> _messages;

  @override
  Future<void> load() async {
    state = AsyncValue.data(_messages);
  }
}
