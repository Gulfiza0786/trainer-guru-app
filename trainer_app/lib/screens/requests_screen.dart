import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:wtf_shared/wtf_shared.dart';

import '../blocs/members_cubit.dart';
import '../blocs/requests_cubit.dart';
import '../widgets/trainer_widgets.dart';

/// Spec §3C trainer flow: pending requests with DK's note,
/// Approve/Decline inline; decline opens a reason modal.
/// Expects a [RequestsCubit] and [MembersCubit] above it in the tree.
class RequestsScreen extends StatelessWidget {
  final AppUser me;

  const RequestsScreen({super.key, required this.me});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RequestsCubit>().state;
    final members = context.watch<MembersCubit>().state;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.requests),
        actions: [
          if (state.pending.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: Gap.s16),
              child: StatusPill(
                label: AppStrings.pendingCount(state.pending.length),
                color: AppColors.warning,
              ),
            ),
        ],
      ),
      body: switch (state) {
        RequestsState(loading: true) =>
          const Center(child: CircularProgressIndicator()),
        RequestsState(pending: []) => const EmptyState(
            icon: Icons.inbox_rounded,
            title: AppStrings.noPendingRequests,
            subtitle: AppStrings.allCaughtUpBody,
          ),
        _ => ListView.separated(
            padding: const EdgeInsets.all(Gap.s16),
            itemCount: state.pending.length,
            separatorBuilder: (_, _) => const SizedBox(height: Gap.s12),
            itemBuilder: (context, i) {
              final request = state.pending[i];
              return _RequestCard(
                request: request,
                memberName: members.nameOf(request.memberId),
                acting: state.actingOnId == request.id,
              );
            },
          ),
      },
    );
  }
}

class _RequestCard extends StatelessWidget {
  final CallRequest request;
  final String memberName;
  final bool acting;

  const _RequestCard({
    required this.request,
    required this.memberName,
    required this.acting,
  });

  Future<void> _approve(BuildContext context) async {
    final error = await context.read<RequestsCubit>().approve(request);
    if (error != null) {
      await AppToast.error(error);
    } else {
      final date = DateFormat('d MMM').format(request.scheduledFor);
      final time = DateFormat('h:mm a').format(request.scheduledFor);
      await AppToast.show(AppStrings.approved(date, time));
    }
  }

  Future<void> _decline(BuildContext context) async {
    final cubit = context.read<RequestsCubit>();
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: const RoundedRectangleBorder(borderRadius: Radii.xl),
        title: const Text(AppStrings.declineReasonTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 140,
          style: AppTextStyles.body,
          decoration: const InputDecoration(
            hintText: AppStrings.declineReasonHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text(AppStrings.decline),
          ),
        ],
      ),
    );
    if (reason == null || reason.isEmpty) return;
    final error = await cubit.decline(request, reason);
    if (error != null) await AppToast.error(error);
  }

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _DateBlock(date: request.scheduledFor),
              const SizedBox(width: Gap.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(memberName, style: AppTextStyles.h3),
                    const SizedBox(height: Gap.s2),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: AppColors.slate500,
                        ),
                        const SizedBox(width: Gap.s4),
                        Text(
                          DateFormat('EEEE • h:mm a')
                              .format(request.scheduledFor),
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const StatusPill(
                label: AppStrings.pending,
                color: AppColors.warning,
              ),
            ],
          ),

          if (request.note.isNotEmpty) ...[
            const SizedBox(height: Gap.s12),
            Container(
              padding: const EdgeInsets.all(Gap.s12),
              decoration: const BoxDecoration(
                color: AppColors.slate50,
                borderRadius: Radii.md,
                border: Border(
                  left: BorderSide(color: AppColors.slate300, width: 3),
                ),
              ),
              child: Text(request.note, style: AppTextStyles.bodySmall),
            ),
          ],

          const SizedBox(height: Gap.s16),

          if (acting)
            const Center(
              child: SizedBox(
                height: 44,
                child: Padding(
                  padding: EdgeInsets.all(Gap.s8),
                  child: CircularProgressIndicator(),
                ),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _decline(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.slate700,
                      side: const BorderSide(color: AppColors.slate200),
                      minimumSize: const Size.fromHeight(44),
                    ),
                    child: const Text(AppStrings.decline),
                  ),
                ),
                const SizedBox(width: Gap.s12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approve(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      minimumSize: const Size.fromHeight(44),
                    ),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text(AppStrings.approve),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Calendar-style month/day tile.
class _DateBlock extends StatelessWidget {
  final DateTime date;
  const _DateBlock({required this.date});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      padding: const EdgeInsets.symmetric(vertical: Gap.s8),
      decoration: BoxDecoration(
        color: AppColors.trainerPrimary.withValues(alpha: 0.08),
        borderRadius: Radii.md,
      ),
      child: Column(
        children: [
          Text(
            DateFormat('MMM').format(date).toUpperCase(),
            style: AppTextStyles.label.copyWith(
              color: AppColors.trainerPrimary,
              fontSize: 10,
              letterSpacing: 1,
            ),
          ),
          Text(
            DateFormat('d').format(date),
            style: AppTextStyles.h2.copyWith(
              color: AppColors.trainerPrimary,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
