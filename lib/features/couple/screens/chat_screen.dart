import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/messaging.dart';
import '../../../models/user.dart';
import '../../../providers/messaging_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/wed_avatar.dart';
import '../../../widgets/wed_text_field.dart';
import '../../../widgets/wed_skeleton.dart';
import '../../../widgets/wed_snack_bar.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String convoId;
  const ChatScreen({super.key, required this.convoId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  // Non-null while editing an existing message — the send button becomes an
  // update button and a banner above the input shows what's being edited,
  // same shape as WhatsApp's edit flow.
  Message? _editing;

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _cancelEdit() {
    setState(() {
      _editing = null;
      _msgCtrl.clear();
    });
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    if (_editing != null) {
      final editingId = _editing!.id;
      _msgCtrl.clear();
      setState(() => _editing = null);
      final error = await ref
          .read(chatMessagesProvider(widget.convoId).notifier)
          .editMessage(editingId, text);
      if (!mounted) return;
      if (error != null) showWedSnackBar(context, error, type: SnackType.error);
      return;
    }

    _msgCtrl.clear();
    await ref.read(chatMessagesProvider(widget.convoId).notifier).sendMessage(text);
    if (!mounted) return;
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showMessageActions(Message message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit message'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  setState(() {
                    _editing = message;
                    _msgCtrl.text = message.content;
                    _msgCtrl.selection = TextSelection.collapsed(offset: _msgCtrl.text.length);
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.error),
                title: const Text('Delete message',
                    style: TextStyle(color: AppColors.error)),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  final error = await ref
                      .read(chatMessagesProvider(widget.convoId).notifier)
                      .deleteMessage(message.id);
                  if (!mounted) return;
                  if (error != null) {
                    showWedSnackBar(context, error, type: SnackType.error);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessagesProvider(widget.convoId));
    final currentUserId = ref.watch(currentUserProvider)?.id;
    final currentUserRole = ref.watch(currentUserProvider)?.role;
    final conversation = ref
        .watch(conversationsProvider)
        .valueOrNull
        ?.where((c) => c.id == widget.convoId)
        .firstOrNull;

    final isVendorViewer = currentUserRole == UserRole.vendor;
    final otherPartyName = (isVendorViewer ? conversation?.coupleName : conversation?.vendorName) ??
        (isVendorViewer ? 'Couple' : 'Vendor');
    final otherPartyAvatarUrl =
        isVendorViewer ? conversation?.coupleAvatarUrl : conversation?.vendorAvatarUrl;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            WedAvatar(imageUrl: otherPartyAvatarUrl, name: otherPartyName, radius: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    otherPartyName,
                    style: const TextStyle(fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => const WedListSkeleton(rows: 6, hasLeading: false),
              error: (e, _) => Center(
                child: Text('Could not load messages.',
                    style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ),
              data: (messages) => ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (_, i) {
                  final msg = messages[i];
                  final isMe = msg.senderId == currentUserId;
                  return GestureDetector(
                    // Only the sender can edit/delete their own message, and
                    // there is nothing left to do with an already-deleted one.
                    onLongPress: isMe && !msg.isDeleted
                        ? () => _showMessageActions(msg)
                        : null,
                    child: _MessageBubble(message: msg, isMe: isMe),
                  );
                },
              ),
            ),
          ),
          const Divider(height: 1),
          if (_editing != null)
            Container(
              width: double.infinity,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.edit_outlined, size: 16, color: AppColors.forestGreen),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Editing message',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.forestGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: _cancelEdit,
                    child: const Icon(Icons.close, size: 18),
                  ),
                ],
              ),
            ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isTablet = constraints.maxWidth >= 600;
                final maxWidth = isTablet ? 500.0 : double.infinity;
                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          IconButton(
                            tooltip: 'Attach file',
                            icon: Icon(Icons.attach_file_outlined, color: Theme.of(context).colorScheme.onSurfaceVariant),
                            onPressed: () {},
                          ),
                          Expanded(
                            // maxLines stays null so the field grows with the
                            // message and Enter inserts a newline (Flutter
                            // asserts that pairing), but unbounded growth
                            // inside this Row-in-a-Column resolved to an
                            // effectively infinite intrinsic height and blew
                            // the chat layout out by ~99,000px. The cap is a
                            // height limit rather than a line limit: about
                            // five lines, after which the field scrolls.
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 140),
                              child: WedTextField(
                                controller: _msgCtrl,
                                hint: 'Type a message...',
                                borderRadius: 24,
                                maxLines: null,
                                // Required with TextInputAction.newline on a
                                // multi-line field — Flutter asserts on the
                                // combination, and WedTextField defaults to
                                // TextInputType.text. Without it the field
                                // failed to build at all, which is what took
                                // the whole chat layout down with it.
                                keyboardType: TextInputType.multiline,
                                textInputAction: TextInputAction.newline,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Material(
                            color: AppColors.secondary,
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: _send,
                              child: SizedBox(
                                width: 44,
                                height: 44,
                                child: Icon(
                                  _editing != null ? Icons.check : Icons.send,
                                  color: AppColors.textOnSecondary,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: isMe ? AppColors.secondary : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 2)],
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              // A deleted message's real content never even reaches the
              // client (see Message.fromJson / serializeMessage) — this is
              // the tombstone both sides see, not a locally-hidden bubble.
              message.isDeleted ? 'This message was deleted' : message.content,
              style: AppTextStyles.bodyMedium.copyWith(
                color: message.isDeleted
                    ? (isMe
                        ? AppColors.textOnSecondary.withAlpha(180)
                        : Theme.of(context).colorScheme.onSurfaceVariant)
                    // Ink on gold, never white: AppColors.secondary is gold,
                    // and white on it is 2.42:1 — the couple's own messages
                    // were the least readable text in the app.
                    : (isMe
                        ? AppColors.textOnSecondary
                        : Theme.of(context).colorScheme.onSurface),
                fontStyle: message.isDeleted ? FontStyle.italic : FontStyle.normal,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (message.wasEdited && !message.isDeleted) ...[
                  Text(
                    'edited · ',
                    style: AppTextStyles.caption.copyWith(
                      color: isMe
                          ? AppColors.textPrimary.withAlpha(160)
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                Text(
                  _formatTime(message.sentAt),
                  style: AppTextStyles.caption.copyWith(
                    // white70 on gold was worse still, at 1.9:1.
                    color: isMe
                        ? AppColors.textPrimary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
                // Read receipt, WhatsApp-style — single check once sent,
                // double check once the other side has actually opened the
                // thread (see GET /conversations/:id/messages, which is what
                // flips is_read; ChatNotifier polls while this screen is
                // open so this updates without needing to reopen the chat).
                // Only ever shown on the couple/vendor's own messages — there
                // is nothing to report back about a message someone else sent.
                if (isMe && !message.isDeleted) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead ? Icons.done_all : Icons.done,
                    size: 13,
                    color: message.isRead
                        ? AppColors.info
                        : AppColors.textPrimary.withAlpha(160),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
