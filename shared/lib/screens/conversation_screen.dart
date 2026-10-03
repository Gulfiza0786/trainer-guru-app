import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../blocs/conversation_bloc.dart';
import '../models/app_user.dart';
import '../models/message.dart';
import '../services/chat_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_strings.dart';
import '../utils/app_text_styles.dart';
import '../utils/app_toast.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/empty_state.dart';
import '../widgets/typing_dots.dart';

/// Firestore keeps docs under 1 MB; base64 inflates ~33%, so cap raw
/// files at 700 KB (spec §15 attachments — images + documents only).
const int kMaxAttachmentBytes = 700 * 1024;

/// One conversation, shared by both apps (spec §3B). The opener passes
/// who they are, who they're chatting with, and their role color.
class ConversationScreen extends StatelessWidget {
  final AppUser me;
  final AppUser peer;
  final Color myBubbleColor;
  final ChatService chatService;

  /// Optional trailing appbar action (e.g. join-call camera icon, Task 10).
  final Widget? toolbarAction;

  const ConversationScreen({
    super.key,
    required this.me,
    required this.peer,
    required this.myBubbleColor,
    required this.chatService,
    this.toolbarAction,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ConversationBloc(
        chat: chatService,
        me: me,
        peer: peer,
        chatId: SeedChatId.of(me, peer),
      )..add(const ConversationOpened()),
      child: _ConversationView(
        me: me,
        peer: peer,
        myBubbleColor: myBubbleColor,
        toolbarAction: toolbarAction,
      ),
    );
  }
}

/// Deterministic chat id regardless of which side opens the screen.
abstract final class SeedChatId {
  static String of(AppUser a, AppUser b) {
    final member = a.role == UserRole.member ? a : b;
    final trainer = a.role == UserRole.trainer ? a : b;
    return '${member.id}_${trainer.id}';
  }
}

class _ConversationView extends StatefulWidget {
  final AppUser me;
  final AppUser peer;
  final Color myBubbleColor;
  final Widget? toolbarAction;

  const _ConversationView({
    required this.me,
    required this.peer,
    required this.myBubbleColor,
    this.toolbarAction,
  });

  @override
  State<_ConversationView> createState() => _ConversationViewState();
}

class _ConversationViewState extends State<_ConversationView> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send(BuildContext context, String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    context.read<ConversationBloc>().add(TextSent(trimmed));
    _inputController.clear();
    // Reversed list: bottom == offset 0.
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendAttachment(
    BuildContext context, {
    required AttachmentType type,
    required String name,
    required List<int> bytes,
  }) async {
    if (bytes.length > kMaxAttachmentBytes) {
      await AppToast.error(AppStrings.attachmentTooLarge);
      return;
    }
    context.read<ConversationBloc>().add(
      AttachmentSent(type: type, name: name, base64: base64Encode(bytes)),
    );
  }

  Future<void> _pickImage(BuildContext context) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!context.mounted) return;
      await _sendAttachment(
        context,
        type: AttachmentType.image,
        name: picked.name,
        bytes: bytes,
      );
    } catch (_) {
      await AppToast.error(AppStrings.attachmentFailed);
    }
  }

  Future<void> _pickDocument(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const [
          'pdf',
          'doc',
          'docx',
          'txt',
          'xls',
          'xlsx',
          'ppt',
          'pptx',
          'csv',
        ],
        withData: true,
      );
      final file = result?.files.firstOrNull;
      if (file == null || file.bytes == null || !context.mounted) return;
      await _sendAttachment(
        context,
        type: AttachmentType.document,
        name: file.name,
        bytes: file.bytes!,
      );
    } catch (_) {
      await AppToast.error(AppStrings.attachmentFailed);
    }
  }

  void _showAttachMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Gap.s8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _AttachOption(
                icon: Icons.image_rounded,
                label: 'Photo / Image',
                color: widget.myBubbleColor,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pickImage(context);
                },
              ),
              _AttachOption(
                icon: Icons.insert_drive_file_rounded,
                label: 'Document',
                color: AppColors.slate600,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pickDocument(context);
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
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            // Peer avatar
            CircleAvatar(
              radius: 18,
              backgroundColor: widget.myBubbleColor,
              foregroundColor: AppColors.white,
              child: Text(
                widget.peer.name.isNotEmpty
                    ? widget.peer.name.substring(0, 1).toUpperCase()
                    : '?',
                style: AppTextStyles.label.copyWith(color: AppColors.white),
              ),
            ),
            const SizedBox(width: Gap.s12),
            Expanded(
              child: BlocBuilder<ConversationBloc, ConversationState>(
                buildWhen: (a, b) => a.peerTyping != b.peerTyping,
                builder: (context, state) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.peer.name,
                      style: AppTextStyles.h3,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (state.peerTyping)
                      Text(
                        AppStrings.typing,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.success,
                        ),
                      )
                    else
                      Text('Trainer', style: AppTextStyles.caption),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [if (widget.toolbarAction != null) widget.toolbarAction!],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: BlocBuilder<ConversationBloc, ConversationState>(
              builder: (context, state) {
                if (state.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.messages.isEmpty && !state.peerTyping) {
                  return EmptyState(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: AppStrings.emptyChat,
                    ctaLabel: AppStrings.sayHi,
                    onCta: () => _send(context, 'Hi ${widget.peer.name} 👋'),
                  );
                }
                return RefreshIndicator(
                  color: widget.myBubbleColor,
                  onRefresh: () async => context.read<ConversationBloc>().add(
                    const LoadOlderRequested(),
                  ),
                  child: ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: Gap.s12,
                      vertical: Gap.s8,
                    ),
                    itemCount:
                        state.messages.length + (state.peerTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (state.peerTyping && index == 0) {
                        return const TypingDots();
                      }
                      final m =
                          state.messages[state.peerTyping ? index - 1 : index];
                      return ChatBubble(
                        message: m,
                        isMine: m.senderId == widget.me.id,
                        roleColor: widget.myBubbleColor,
                      );
                    },
                  ),
                );
              },
            ),
          ),

          // Input bar
          _InputBar(
            controller: _inputController,
            bubbleColor: widget.myBubbleColor,
            onSend: () => _send(context, _inputController.text),
            onAttach: () => _showAttachMenu(context),
            quickReplies: const [
              AppStrings.quickReply1,
              AppStrings.quickReply2,
              AppStrings.quickReply3,
            ],
            onQuickReply: (r) => _send(context, r),
          ),
        ],
      ),
    );
  }
}

// ── Input bar ─────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final Color bubbleColor;
  final VoidCallback onSend;
  final VoidCallback onAttach;
  final List<String> quickReplies;
  final void Function(String) onQuickReply;

  const _InputBar({
    required this.controller,
    required this.bubbleColor,
    required this.onSend,
    required this.onAttach,
    required this.quickReplies,
    required this.onQuickReply,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceElevated,
          border: Border(top: BorderSide(color: AppColors.divider, width: 1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Quick-reply chips
            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: Gap.s12,
                  vertical: Gap.s8,
                ),
                itemCount: quickReplies.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.only(right: Gap.s8),
                  child: ActionChip(
                    label: Text(quickReplies[i]),
                    onPressed: () => onQuickReply(quickReplies[i]),
                    backgroundColor: bubbleColor.withValues(alpha: 0.08),
                    labelStyle: AppTextStyles.bodySmall.copyWith(
                      color: bubbleColor,
                    ),
                    side: BorderSide(color: bubbleColor.withValues(alpha: 0.2)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: Gap.s8),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ),
            // Text field row
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Gap.s8,
                Gap.s4,
                Gap.s8,
                Gap.s8,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Attach button
                  _CircleIconBtn(
                    icon: Icons.attach_file_rounded,
                    color: AppColors.slate500,
                    onTap: onAttach,
                  ),
                  const SizedBox(width: Gap.s4),
                  // Text input
                  Expanded(
                    child: TextField(
                      controller: controller,
                      maxLines: 4,
                      minLines: 1,
                      textCapitalization: TextCapitalization.sentences,
                      style: AppTextStyles.body,
                      decoration: InputDecoration(
                        hintText: AppStrings.typeMessage,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: Gap.s16,
                          vertical: Gap.s12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(
                            color: AppColors.slate200,
                            width: 1.5,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(
                            color: AppColors.slate200,
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: bubbleColor, width: 2),
                        ),
                      ),
                      onSubmitted: (_) => onSend(),
                    ),
                  ),
                  const SizedBox(width: Gap.s4),
                  // Send button
                  _CircleIconBtn(
                    icon: Icons.send_rounded,
                    color: bubbleColor,
                    filled: true,
                    onTap: onSend,
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

class _CircleIconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool filled;
  final VoidCallback onTap;

  const _CircleIconBtn({
    required this.icon,
    required this.color,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? color : Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 20, color: filled ? AppColors.white : color),
        ),
      ),
    );
  }
}

// ── Attach menu option row ────────────────────────────────────────────────────

class _AttachOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AttachOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(label, style: AppTextStyles.body),
      onTap: onTap,
    );
  }
}
