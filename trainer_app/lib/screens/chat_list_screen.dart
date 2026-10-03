import 'package:flutter/material.dart';
import 'package:wtf_shared/wtf_shared.dart';

import '../main.dart';
import '../widgets/trainer_widgets.dart';
import 'call_launcher.dart';

/// Trainer chat list (spec §3B): conversations with unread badge, last
/// message preview and "5m ago" timestamp.
class ChatListScreen extends StatefulWidget {
  final AppUser me;
  final ChatService chatService;
  final AuthService authService;

  const ChatListScreen({
    super.key,
    required this.me,
    required this.chatService,
    required this.authService,
  });

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  late final Future<AppUser?> _dk = _loadDk();

  Future<AppUser?> _loadDk() async {
    final members = await widget.authService.membersOf(widget.me.id);
    return members.isEmpty ? null : members.first;
  }

  String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final me = widget.me;
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.chats)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openDkChat,
        icon: const Icon(Icons.edit_rounded, size: 20),
        label: const Text(AppStrings.newChat),
      ),
      body: FutureBuilder<AppUser?>(
        future: _dk,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final dk = snap.data;
          if (dk == null) {
            return const EmptyState(
              icon: Icons.chat_bubble_outline_rounded,
              title: AppStrings.emptyChat,
            );
          }
          final chatId = SeedIds.chatId(dk.id, me.id);
          return StreamBuilder<ChatSummary>(
            stream: widget.chatService.watchChat(chatId, me.id),
            builder: (context, chatSnap) {
              final summary = chatSnap.data ?? const ChatSummary();
              final last = summary.lastMessage;
              final typing = summary.typingUserId == dk.id;
              return ListView(
                padding: const EdgeInsets.all(Gap.s16),
                children: [
                  SurfaceCard(
                    padding: EdgeInsets.zero,
                    child: _ChatRow(
                      member: dk,
                      unread: summary.unreadCount,
                      typing: typing,
                      lastText: typing
                          ? AppStrings.typing
                          : (last?.preview ?? AppStrings.emptyChat),
                      timeLabel: last != null ? _ago(last.createdAt) : null,
                      onTap: _openDkChat,
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openDkChat() async {
    final peer = await _dk;
    if (peer == null || !mounted) return;
    final me = widget.me;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (screenContext) => ConversationScreen(
          me: me,
          peer: peer,
          myBubbleColor: AppColors.trainerPrimary,
          chatService: widget.chatService,
          toolbarAction: ChatCallAction(
            approvedStream: scheduleService.watchApproved('trainerId', me.id),
            onJoin: (request) => launchCall(screenContext, me, request),
          ),
        ),
      ),
    );
  }
}

// ── Chat row ──────────────────────────────────────────────────────────────────

class _ChatRow extends StatelessWidget {
  final AppUser member;
  final int unread;
  final bool typing;
  final String lastText;
  final String? timeLabel;
  final VoidCallback onTap;

  const _ChatRow({
    required this.member,
    required this.unread,
    required this.typing,
    required this.lastText,
    required this.onTap,
    this.timeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final hasUnread = unread > 0;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(Gap.s16),
        child: Row(
          children: [
            InitialsAvatar(name: member.name, size: 48),
            const SizedBox(width: Gap.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(member.name, style: AppTextStyles.h3),
                      ),
                      if (timeLabel != null)
                        Text(
                          timeLabel!,
                          style: AppTextStyles.caption.copyWith(
                            color: hasUnread
                                ? AppColors.trainerPrimary
                                : AppColors.slate500,
                            fontWeight: hasUnread
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: Gap.s2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: typing
                                ? AppColors.trainerPrimary
                                : hasUnread
                                    ? AppColors.slate800
                                    : AppColors.slate500,
                            fontWeight: hasUnread
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (hasUnread) ...[
                        const SizedBox(width: Gap.s8),
                        Badge(
                          label: Text('$unread'),
                          backgroundColor: AppColors.trainerPrimary,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
