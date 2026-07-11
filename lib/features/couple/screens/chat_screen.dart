import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/messaging.dart';
import '../../../models/user.dart';
import '../../../providers/messaging_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/wed_avatar.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String convoId;
  const ChatScreen({super.key, required this.convoId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
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
      backgroundColor: AppColors.background,
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
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('Could not load messages.',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
              ),
              data: (messages) => ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (_, i) {
                  final msg = messages[i];
                  final isMe = msg.senderId == currentUserId;
                  return _MessageBubble(message: msg, isMe: isMe);
                },
              ),
            ),
          ),
          const Divider(height: 1),
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
                            icon: const Icon(Icons.attach_file_outlined, color: AppColors.textSecondary),
                            onPressed: () {},
                          ),
                          Expanded(
                            child: TextField(
                              controller: _msgCtrl,
                              decoration: InputDecoration(
                                hintText: 'Type a message...',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                filled: true,
                                fillColor: AppColors.surface,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: const BorderSide(color: AppColors.divider),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: const BorderSide(color: AppColors.divider),
                                ),
                              ),
                              maxLines: null,
                              textInputAction: TextInputAction.newline,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Material(
                            color: AppColors.secondary,
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: _send,
                              child: const SizedBox(
                                width: 44,
                                height: 44,
                                child: Icon(Icons.send_rounded, color: Colors.white, size: 20),
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
          color: isMe ? AppColors.secondary : AppColors.surface,
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
              message.content,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isMe ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.sentAt),
              style: AppTextStyles.caption.copyWith(
                color: isMe ? Colors.white70 : AppColors.textSecondary,
                fontSize: 10,
              ),
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
