import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../models/message.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

/// Chat bubble (spec §3B): own messages right-aligned in the sender's role
/// color, peer messages left in a subtle slate surface; ✓ sent / ✓✓ read
/// ticks on own messages; system messages render as a centered pill.
class ChatBubble extends StatelessWidget {
  final Message message;
  final bool isMine;
  final Color roleColor;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMine,
    required this.roleColor,
  });

  // ── Attachment rendering ──────────────────────────────────────────────────

  Widget _attachment(BuildContext context) {
    final data = message.attachmentData;
    if (data == null) return _docChip(context, openable: false);
    if (message.attachmentType == AttachmentType.image) {
      return Padding(
        padding: const EdgeInsets.only(bottom: Gap.s4),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.memory(
            base64Decode(data),
            width: 200,
            fit: BoxFit.cover,
          ),
        ),
      );
    }
    return _docChip(context, openable: true);
  }

  Widget _docChip(BuildContext context, {required bool openable}) {
    final onLight = !isMine;
    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.s4),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: openable ? () => _openDocument(context) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: Gap.s8),
          decoration: BoxDecoration(
            color: onLight
                ? AppColors.slate200
                : AppColors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.insert_drive_file_rounded,
                size: 22,
                color: onLight ? AppColors.slate600 : AppColors.white,
              ),
              const SizedBox(width: Gap.s8),
              Flexible(
                child: Text(
                  message.attachmentName ?? 'Document',
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: onLight ? AppColors.slate800 : AppColors.white,
                  ),
                ),
              ),
              if (openable) ...[
                const SizedBox(width: Gap.s4),
                Icon(
                  Icons.download_rounded,
                  size: 14,
                  color: onLight ? AppColors.slate500 : AppColors.white,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openDocument(BuildContext context) async {
    final data = message.attachmentData;
    if (data == null) return;
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${message.attachmentName ?? message.id}');
    await file.writeAsBytes(base64Decode(data));
    await OpenFilex.open(file.path);
  }

  // ── System message ────────────────────────────────────────────────────────

  Widget _systemPill() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: Gap.s8),
        padding: const EdgeInsets.symmetric(
          horizontal: Gap.s16,
          vertical: Gap.s4,
        ),
        decoration: BoxDecoration(
          color: AppColors.slate100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.slate200),
        ),
        child: Text(message.text, style: AppTextStyles.caption),
      ),
    );
  }

  // ── Main build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (message.isSystem) return _systemPill();

    final time = DateFormat('h:mm a').format(message.createdAt);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 10, end: 0),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      builder: (context, dy, child) =>
          Transform.translate(offset: Offset(0, dy), child: child),
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.74,
          ),
          child: Container(
            margin: EdgeInsets.only(
              top: Gap.s4,
              bottom: Gap.s4,
              left: isMine ? Gap.s24 : 0,
              right: isMine ? 0 : Gap.s24,
            ),
            // 14dp horizontal, 10dp vertical padding
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isMine ? roleColor : AppColors.slate100,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isMine ? 18 : 4),
                bottomRight: Radius.circular(isMine ? 4 : 18),
              ),
              boxShadow: [
                BoxShadow(
                  color: (isMine ? roleColor : AppColors.slate900).withValues(
                    alpha: 0.08,
                  ),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (message.hasAttachment) _attachment(context),
                if (message.text.isNotEmpty)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      message.text,
                      style: AppTextStyles.body.copyWith(
                        color: isMine ? AppColors.white : AppColors.slate900,
                      ),
                    ),
                  ),
                const SizedBox(height: Gap.s4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      time,
                      style: AppTextStyles.caption.copyWith(
                        color: isMine
                            ? AppColors.white.withValues(alpha: 0.75)
                            : AppColors.slate400,
                      ),
                    ),
                    if (isMine) ...[
                      const SizedBox(width: Gap.s4),
                      Icon(
                        message.status == MessageStatus.read
                            ? Icons.done_all_rounded
                            : Icons.done_rounded,
                        size: 13,
                        color: AppColors.white.withValues(alpha: 0.85),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
