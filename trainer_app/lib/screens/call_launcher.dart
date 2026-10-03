import 'package:flutter/material.dart';
import 'package:wtf_shared/wtf_shared.dart';

import '../main.dart';
import '../widgets/trainer_widgets.dart';

/// Opens the call flow for an approved request (trainer side) and shows
/// the quick-notes sheet when the call ends (spec §3D post-call).
Future<void> launchCall(
  BuildContext context,
  AppUser me,
  CallRequest request,
) async {
  final room = await scheduleService.roomFor(request.id);
  if (room == null) {
    await AppToast.error(AppStrings.genericError);
    return;
  }
  final members = await authService.membersOf(me.id);
  final peer = members.firstWhere(
    (m) => m.id == request.memberId,
    orElse: () => members.first,
  );
  if (!context.mounted) return;
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => CallScreen(
        me: me,
        peer: peer,
        room: room,
        roleColor: AppColors.trainerPrimary,
        logService: logService,
        callService: callService,
        onEnded: (callContext, ended) => _showNotesSheet(callContext, ended),
      ),
    ),
  );
}

Future<void> _showNotesSheet(BuildContext context, CallEnded ended) async {
  final notesController = TextEditingController();

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        left: Gap.s24,
        right: Gap.s24,
        bottom: MediaQuery.viewInsetsOf(sheetContext).bottom + Gap.s32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              const IconBadge(
                icon: Icons.edit_note_rounded,
                color: AppColors.trainerPrimary,
              ),
              const SizedBox(width: Gap.s12),
              Text(AppStrings.trainerQuickNotes, style: AppTextStyles.h2),
            ],
          ),
          const SizedBox(height: Gap.s20),

          // Notes field
          TextField(
            controller: notesController,
            maxLength: 140,
            maxLines: 3,
            style: AppTextStyles.body,
            decoration: const InputDecoration(
              hintText: AppStrings.addNote,
              alignLabelWithHint: true,
            ),
          ),

          const SizedBox(height: Gap.s12),

          // Save CTA
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.trainerPrimary,
            ),
            onPressed: () async {
              await logService.update(
                ended.log.copyWith(trainerNotes: notesController.text.trim()),
              );
              if (sheetContext.mounted) {
                Navigator.of(sheetContext).pop();
              }
              await AppToast.show(AppStrings.sessionEnded);
            },
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text(AppStrings.markComplete),
          ),
        ],
      ),
    ),
  );

  if (context.mounted) Navigator.of(context).pop();
}
