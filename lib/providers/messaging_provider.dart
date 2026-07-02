import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/messaging.dart';

final conversationsProvider = FutureProvider<List<Conversation>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 500));
  return _mockConversations;
});

final vendorConversationsProvider =
    Provider.family<AsyncValue<List<Conversation>>, String>((ref, vendorId) {
  return ref.watch(conversationsProvider).whenData(
        (list) => list.where((c) => c.vendorId == vendorId).toList(),
      );
});

final messagesProvider = FutureProvider.family<List<Message>, String>(
  (ref, convoId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockMessages[convoId] ?? [];
  },
);

final chatMessagesProvider =
    StateNotifierProvider.family<ChatNotifier, List<Message>, String>(
  (ref, convoId) => ChatNotifier(convoId),
);

class ChatNotifier extends StateNotifier<List<Message>> {
  final String convoId;
  ChatNotifier(this.convoId) : super(_mockMessages[convoId] ?? []);

  void sendMessage(String senderId, String content) {
    final message = Message(
      id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
      convoId: convoId,
      senderId: senderId,
      content: content,
      sentAt: DateTime.now(),
    );
    state = [...state, message];
  }
}

final _mockConversations = [
  Conversation(
    id: 'convo-001',
    coupleId: 'profile-001',
    vendorId: 'v-001',
    vendorName: 'Blossom Photography',
    lastMessageText: 'Thank you for your inquiry! We\'d love to be part of your special day.',
    lastMessageAt: DateTime.now().subtract(const Duration(hours: 2)),
    unreadCount: 1,
  ),
  Conversation(
    id: 'convo-002',
    coupleId: 'profile-001',
    vendorId: 'v-003',
    vendorName: 'The Garden Venue',
    lastMessageText: 'Your date is available! Shall we schedule a tour?',
    lastMessageAt: DateTime.now().subtract(const Duration(days: 1)),
    unreadCount: 0,
  ),
  // Vendor-side conversations (vendorId matches logged-in vendor 'vendor-001')
  Conversation(
    id: 'convo-v01',
    coupleId: 'profile-002',
    vendorId: 'vendor-001',
    coupleName: 'Chanda & Mutale',
    vendorName: 'Mukuba Gardens',
    lastMessageText: 'Hi! We love your garden venue and would like to inquire about our wedding.',
    lastMessageAt: DateTime.now().subtract(const Duration(hours: 2)),
    unreadCount: 1,
  ),
  Conversation(
    id: 'convo-v02',
    coupleId: 'profile-003',
    vendorId: 'vendor-001',
    coupleName: 'Nkemba & Lweendo',
    vendorName: 'Mukuba Gardens',
    lastMessageText: 'Thank you for the quick reply! We will confirm the date by end of week.',
    lastMessageAt: DateTime.now().subtract(const Duration(hours: 8)),
    unreadCount: 0,
  ),
];

final _mockMessages = {
  'convo-001': [
    Message(
      id: 'msg-001',
      convoId: 'convo-001',
      senderId: 'profile-001',
      senderName: 'Alex & Jordan',
      content: 'Hi! We love your work and would like to inquire about our wedding on June 14, 2027.',
      sentAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    Message(
      id: 'msg-002',
      convoId: 'convo-001',
      senderId: 'v-001',
      senderName: 'Blossom Photography',
      content: 'Thank you for your inquiry! We\'d love to be part of your special day. Your date looks available!',
      sentAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
  ],
  'convo-002': [
    Message(
      id: 'msg-003',
      convoId: 'convo-002',
      senderId: 'profile-001',
      senderName: 'Alex & Jordan',
      content: 'We are interested in booking The Garden Venue for June 14, 2027 for approximately 120 guests.',
      sentAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Message(
      id: 'msg-004',
      convoId: 'convo-002',
      senderId: 'v-003',
      senderName: 'The Garden Venue',
      content: 'Your date is available! Shall we schedule a tour?',
      sentAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ],
};
