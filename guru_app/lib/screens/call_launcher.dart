import 'package:flutter/material.dart';
import 'package:wtf_shared/wtf_shared.dart';

import '../main.dart';

/// Opens the call flow for an approved request (guru side) and shows
/// the rate-session sheet when the call ends (spec §3D post-call).
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
  final trainers = await authService.seededTrainers();
  final peer = trainers.firstWhere(
    (t) => t.id == request.trainerId,
    orElse: () => trainers.first,
  );
  if (!context.mounted) return;
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => CallScreen(
        me: me,
        peer: peer,
        room: room,
        roleColor: AppColors.guruPrimary,
        logService: logService,
        callService: callService,
        onEnded: (callContext, ended) => _showRateSheet(callContext, ended),
      ),
    ),
  );
}

Future<void> _showRateSheet(BuildContext context, CallEnded ended) async {
  var rating = 5;
  final noteController = TextEditingController();

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
      child: StatefulBuilder(
        builder: (context, setSheetState) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.guruPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.star_rounded,
                    color: AppColors.guruPrimary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: Gap.s12),
                Text(AppStrings.rateSession, style: AppTextStyles.h2),
              ],
            ),
            const SizedBox(height: Gap.s20),

            // Star rating row
            Container(
              padding: const EdgeInsets.symmetric(vertical: Gap.s8),
              decoration: BoxDecoration(
                color: AppColors.slate100,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 1; i <= 5; i++)
                    GestureDetector(
                      onTap: () => setSheetState(() => rating = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: Gap.s8,
                          vertical: Gap.s8,
                        ),
                        child: Icon(
                          i <= rating
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          size: 38,
                          color: i <= rating
                              ? AppColors.warning
                              : AppColors.slate300,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: Gap.s16),

            // Note field
            TextField(
              controller: noteController,
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
              onPressed: () async {
                await logService.update(
                  ended.log.copyWith(
                    rating: rating,
                    memberNotes: noteController.text.trim(),
                  ),
                );
                if (sheetContext.mounted) {
                  Navigator.of(sheetContext).pop();
                }
                await AppToast.show(AppStrings.sessionEnded);
              },
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text(AppStrings.save),
            ),
          ],
        ),
      ),
    ),
  );

  // Leave the (now black) call screen after the sheet closes.
  if (context.mounted) Navigator.of(context).pop();
}
