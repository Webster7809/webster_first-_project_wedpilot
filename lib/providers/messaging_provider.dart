import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/messaging.dart';
import '../core/services/messaging_api_service.dart';
import 'auth_provider.dart';

final conversationsProvider = FutureProvider<List<Conversation>>((ref) async {
  final token = ref.watch(authProvider.notifier).accessToken;
  if (token == null) return [];
  return MessagingApiService.instance.fetchConversations(token);
});

final chatMessagesProvider =
    StateNotifierProvider.family<ChatNotifier, AsyncValue<List<Message>>, String>(
  (ref, convoId) => ChatNotifier(ref, convoId),
);

class ChatNotifier extends StateNotifier<AsyncValue<List<Message>>> {
  ChatNotifier(this._ref, this.convoId) : super(const AsyncValue.loading()) {
    load();
    // There's no push/websocket layer behind this chat, so "seen" only ever
    // becomes true on the *other* side's next fetch (see the read-marking in
    // GET /conversations/:id/messages). Polling while this screen is open is
    // what turns that into something that visibly updates on its own instead
    // of only refreshing the next time the thread is reopened.
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => load());
  }

  final Ref _ref;
  final String convoId;
  Timer? _pollTimer;

  String? get _token => _ref.read(authProvider.notifier).accessToken;

  Future<void> load() async {
    final token = _token;
    if (token == null) {
      state = const AsyncValue.data([]);
      return;
    }
    try {
      final messages = await MessagingApiService.instance.fetchMessages(token, convoId);
      state = AsyncValue.data(messages);
    } catch (e, st) {
      // A poll tick failing shouldn't blank out a thread that loaded fine a
      // moment ago — only surface the error state if there's nothing on
      // screen yet.
      if (state.valueOrNull == null) state = AsyncValue.error(e, st);
    }
  }

  Future<void> sendMessage(String content) async {
    final token = _token;
    if (token == null || content.trim().isEmpty) return;
    try {
      final message = await MessagingApiService.instance.sendMessage(token, convoId, content.trim());
      state = AsyncValue.data([...state.valueOrNull ?? [], message]);
      // The conversation list's last-message preview and unread counts are
      // derived server-side, so refresh it now that this thread has moved.
      _ref.invalidate(conversationsProvider);
    } on MessagingApiException {
      // Leave state as-is; the message simply doesn't appear, which is an
      // honest reflection of "it wasn't actually sent."
    }
  }

  /// Returns an error message on failure, null on success — same convention
  /// as the rest of this app's mutating provider methods.
  Future<String?> editMessage(String messageId, String content) async {
    final token = _token;
    if (token == null) return 'Not signed in.';
    try {
      final updated =
          await MessagingApiService.instance.editMessage(token, convoId, messageId, content);
      state = AsyncValue.data([
        for (final m in state.valueOrNull ?? []) if (m.id == messageId) updated else m,
      ]);
      return null;
    } on MessagingApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> deleteMessage(String messageId) async {
    final token = _token;
    if (token == null) return 'Not signed in.';
    try {
      final updated = await MessagingApiService.instance.deleteMessage(token, convoId, messageId);
      state = AsyncValue.data([
        for (final m in state.valueOrNull ?? []) if (m.id == messageId) updated else m,
      ]);
      return null;
    } on MessagingApiException catch (e) {
      return e.message;
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
