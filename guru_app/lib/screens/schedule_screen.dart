import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:wtf_shared/wtf_shared.dart';

import '../blocs/schedule_cubit.dart';

/// Spec §3C: calendar strip (next 3 days) + 30-min slot chips + note
/// (≤140) + Request Call CTA, with My Requests list below.
class ScheduleScreen extends StatelessWidget {
  final AppUser me;
  final ScheduleService scheduleService;

  const ScheduleScreen({
    super.key,
    required this.me,
    required this.scheduleService,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ScheduleCubit(schedule: scheduleService, me: me),
      child: const _ScheduleView(),
    );
  }
}

class _ScheduleView extends StatefulWidget {
  const _ScheduleView();

  @override
  State<_ScheduleView> createState() => _ScheduleViewState();
}

class _ScheduleViewState extends State<_ScheduleView> {
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  List<DateTime> _slotsFor(DateTime day) => [
    for (var h = 6; h <= 21; h++)
      for (final m in const [0, 30])
        DateTime(day.year, day.month, day.day, h, m),
  ];

  Future<void> _submit(BuildContext context) async {
    final error = await context.read<ScheduleCubit>().submit();
    if (error != null) {
      await AppToast.error(error);
    } else {
      _noteController.clear();
      await AppToast.show(AppStrings.requestSent);
    }
  }

  Color _statusColor(CallStatus s) => switch (s) {
    CallStatus.pending => AppColors.warning,
    CallStatus.approved => AppColors.success,
    CallStatus.declined || CallStatus.cancelled => AppColors.error,
  };

  IconData _statusIcon(CallStatus s) => switch (s) {
    CallStatus.pending => Icons.hourglass_top_rounded,
    CallStatus.approved => Icons.check_circle_rounded,
    CallStatus.declined || CallStatus.cancelled => Icons.cancel_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = [for (var i = 0; i < 3; i++) now.add(Duration(days: i))];

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text(AppStrings.scheduleCall)),
      body: BlocBuilder<ScheduleCubit, ScheduleState>(
        builder: (context, state) {
          final cubit = context.read<ScheduleCubit>();
          final slots = _slotsFor(state.day);

          return ListView(
            padding: const EdgeInsets.all(Gap.s16),
            children: [
              // ── Day strip ───────────────────────────────────────────────
              _SectionCard(
                icon: Icons.calendar_today_rounded,
                title: 'Select a day',
                child: Row(
                  children: [
                    for (var i = 0; i < days.length; i++) ...[
                      if (i > 0) const SizedBox(width: Gap.s8),
                      Expanded(
                        child: _DayChip(
                          day: days[i],
                          caption: switch (i) {
                            0 => 'Today',
                            1 => 'Tomorrow',
                            _ => DateFormat('EEE').format(days[i]),
                          },
                          isSelected: DateUtils.isSameDay(state.day, days[i]),
                          onTap: () => cubit.pickDay(days[i]),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: Gap.s16),

              // ── Time slots, grouped by part of day ──────────────────────
              _SectionCard(
                icon: Icons.access_time_rounded,
                title: AppStrings.pickSlot,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Quick-test shortcut: picks a slot 1 minute from now.
                    OutlinedButton.icon(
                      onPressed: () {
                        final t = DateTime.now().add(
                          const Duration(minutes: 1),
                        );
                        cubit.pickSlot(
                          DateTime(t.year, t.month, t.day, t.hour, t.minute),
                        );
                      },
                      icon: const Icon(Icons.bolt_rounded, size: 18),
                      label: const Text('Test slot: in 1 min'),
                    ),
                    const SizedBox(height: Gap.s16),
                    for (final group in _SlotGroup.values)
                      _SlotGroupView(
                        group: group,
                        slots: slots.where(group.contains).toList(),
                        selected: state.slot,
                        now: now,
                        onPick: cubit.pickSlot,
                      ),
                  ],
                ),
              ),

              const SizedBox(height: Gap.s16),

              // ── Note ────────────────────────────────────────────────────
              _SectionCard(
                icon: Icons.notes_rounded,
                title: 'Add a note (optional)',
                child: TextField(
                  controller: _noteController,
                  maxLength: 140,
                  maxLines: 3,
                  style: AppTextStyles.body,
                  decoration: const InputDecoration(
                    hintText: AppStrings.noteHint,
                    alignLabelWithHint: true,
                  ),
                  onChanged: cubit.setNote,
                ),
              ),

              const SizedBox(height: Gap.s16),

              // ── Selection summary + CTA ─────────────────────────────────
              _SelectionSummary(slot: state.slot),
              const SizedBox(height: Gap.s12),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: state.submitting ? null : () => _submit(context),
                  icon: state.submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded, size: 18),
                  label: Text(
                    state.submitting ? 'Sending…' : AppStrings.requestCall,
                  ),
                ),
              ),

              const SizedBox(height: Gap.s32),

              // ── My requests ─────────────────────────────────────────────
              _SectionHeader(
                icon: Icons.list_alt_rounded,
                title: AppStrings.myRequests,
                trailing: _RequestCount(count: state.myRequests.length),
              ),
              const SizedBox(height: Gap.s12),

              if (state.myRequests.isEmpty)
                const EmptyState(
                  icon: Icons.pending_actions_rounded,
                  title: AppStrings.emptySessions,
                )
              else
                for (final r in state.myRequests) ...[
                  _RequestCard(
                    request: r,
                    statusColor: _statusColor(r.status),
                    statusIcon: _statusIcon(r.status),
                  ),
                  const SizedBox(height: Gap.s8),
                ],

              const SizedBox(height: Gap.s16),
            ],
          );
        },
      ),
    );
  }
}

// ── Section card / header ─────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Gap.s16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: Radii.xl,
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHeader(icon: icon, title: title),
          const SizedBox(height: Gap.s16),
          child,
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;

  const _SectionHeader({
    required this.icon,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.guruPrimary.withValues(alpha: 0.1),
            borderRadius: Radii.sm,
          ),
          child: Icon(icon, size: 16, color: AppColors.guruPrimary),
        ),
        const SizedBox(width: Gap.s12),
        Expanded(child: Text(title, style: AppTextStyles.h3)),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _RequestCount extends StatelessWidget {
  final int count;
  const _RequestCount({required this.count});

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Gap.s8, vertical: Gap.s2),
      decoration: BoxDecoration(
        color: AppColors.guruPrimary.withValues(alpha: 0.1),
        borderRadius: Radii.pill,
      ),
      child: Text(
        '$count',
        style: AppTextStyles.label.copyWith(color: AppColors.guruPrimary),
      ),
    );
  }
}

// ── Day chip ──────────────────────────────────────────────────────────────────

class _DayChip extends StatelessWidget {
  final DateTime day;
  final String caption;
  final bool isSelected;
  final VoidCallback onTap;

  const _DayChip({
    required this.day,
    required this.caption,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = isSelected ? AppColors.white : AppColors.slate800;
    final muted = isSelected
        ? AppColors.white.withValues(alpha: 0.85)
        : AppColors.slate500;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: Gap.s12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [AppColors.guruPrimary, AppColors.guruAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : AppColors.slate50,
          borderRadius: Radii.lg,
          border: Border.all(
            color: isSelected ? AppColors.guruPrimary : AppColors.divider,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.guruPrimary.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(caption, style: AppTextStyles.caption.copyWith(color: muted)),
            const SizedBox(height: Gap.s2),
            Text(
              DateFormat('d').format(day),
              style: AppTextStyles.h1.copyWith(color: fg),
            ),
            Text(
              DateFormat('MMM').format(day),
              style: AppTextStyles.label.copyWith(color: muted),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Slot groups ───────────────────────────────────────────────────────────────

enum _SlotGroup {
  morning('Morning', Icons.wb_twilight_rounded, 6, 12),
  afternoon('Afternoon', Icons.wb_sunny_rounded, 12, 17),
  evening('Evening', Icons.nights_stay_rounded, 17, 24);

  final String label;
  final IconData icon;
  final int fromHour;
  final int toHour;
  const _SlotGroup(this.label, this.icon, this.fromHour, this.toHour);

  bool contains(DateTime t) => t.hour >= fromHour && t.hour < toHour;
}

class _SlotGroupView extends StatelessWidget {
  final _SlotGroup group;
  final List<DateTime> slots;
  final DateTime? selected;
  final DateTime now;
  final ValueChanged<DateTime> onPick;

  const _SlotGroupView({
    required this.group,
    required this.slots,
    required this.selected,
    required this.now,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final available = slots.where((s) => s.isAfter(now)).length;

    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(group.icon, size: 14, color: AppColors.slate500),
              const SizedBox(width: Gap.s4),
              Text(
                group.label,
                style: AppTextStyles.label.copyWith(color: AppColors.slate600),
              ),
              const Spacer(),
              Text(
                available == 0 ? 'None left' : '$available open',
                style: AppTextStyles.caption,
              ),
            ],
          ),
          const SizedBox(height: Gap.s8),
          LayoutBuilder(
            builder: (context, c) {
              const cols = 4;
              final w = (c.maxWidth - Gap.s8 * (cols - 1)) / cols;
              return Wrap(
                spacing: Gap.s8,
                runSpacing: Gap.s8,
                children: [
                  for (final slot in slots)
                    SizedBox(
                      width: w,
                      child: _SlotChip(
                        slot: slot,
                        isSelected: selected == slot,
                        isPast: !slot.isAfter(now),
                        onTap: () => onPick(slot),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Slot chip ─────────────────────────────────────────────────────────────────

class _SlotChip extends StatelessWidget {
  final DateTime slot;
  final bool isSelected;
  final bool isPast;
  final VoidCallback onTap;

  const _SlotChip({
    required this.slot,
    required this.isSelected,
    required this.isPast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color border;
    final Color fg;
    if (isSelected) {
      bg = AppColors.guruPrimary;
      border = AppColors.guruPrimary;
      fg = AppColors.white;
    } else if (isPast) {
      bg = AppColors.slate100;
      border = AppColors.slate100;
      fg = AppColors.slate400;
    } else {
      bg = AppColors.surfaceElevated;
      border = AppColors.divider;
      fg = AppColors.slate700;
    }

    return Material(
      color: bg,
      borderRadius: Radii.md,
      child: InkWell(
        onTap: isPast ? null : onTap,
        borderRadius: Radii.md,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: Radii.md,
            border: Border.all(color: border),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              DateFormat('h:mm a').format(slot),
              style: AppTextStyles.bodySmall.copyWith(
                color: fg,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                decoration: isPast ? TextDecoration.lineThrough : null,
                decorationColor: AppColors.slate400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Selection summary ─────────────────────────────────────────────────────────

class _SelectionSummary extends StatelessWidget {
  final DateTime? slot;
  const _SelectionSummary({required this.slot});

  @override
  Widget build(BuildContext context) {
    final picked = slot != null;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(
        horizontal: Gap.s16,
        vertical: Gap.s12,
      ),
      decoration: BoxDecoration(
        color: picked
            ? AppColors.guruPrimary.withValues(alpha: 0.08)
            : AppColors.slate100,
        borderRadius: Radii.lg,
      ),
      child: Row(
        children: [
          Icon(
            picked ? Icons.event_available_rounded : Icons.event_rounded,
            size: 20,
            color: picked ? AppColors.guruPrimary : AppColors.slate400,
          ),
          const SizedBox(width: Gap.s12),
          Expanded(
            child: Text(
              picked
                  ? DateFormat('EEEE, d MMM • h:mm a').format(slot!)
                  : 'No time slot selected yet',
              style: AppTextStyles.bodySmall.copyWith(
                color: picked ? AppColors.slate800 : AppColors.slate500,
                fontWeight: picked ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          if (picked)
            Text(
              '30 min',
              style: AppTextStyles.label.copyWith(color: AppColors.guruPrimary),
            ),
        ],
      ),
    );
  }
}

// ── Request card ──────────────────────────────────────────────────────────────

class _RequestCard extends StatelessWidget {
  final CallRequest request;
  final Color statusColor;
  final IconData statusIcon;

  const _RequestCard({
    required this.request,
    required this.statusColor,
    required this.statusIcon,
  });

  @override
  Widget build(BuildContext context) {
    final sub = request.status == CallStatus.pending
        ? AppStrings.pendingApprovalBy('Aarav')
        : request.status == CallStatus.declined
        ? AppStrings.declined(request.declineReason ?? '—')
        : request.note;
    final status = request.status.name;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: Radii.lg,
        border: Border.all(color: AppColors.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status accent strip
            Container(width: 4, color: statusColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(Gap.s12),
                child: Row(
                  children: [
                    // Date block
                    Container(
                      width: 48,
                      padding: const EdgeInsets.symmetric(vertical: Gap.s4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: Radii.md,
                      ),
                      child: Column(
                        children: [
                          Text(
                            DateFormat('d').format(request.scheduledFor),
                            style: AppTextStyles.h2.copyWith(
                              color: statusColor,
                            ),
                          ),
                          Text(
                            DateFormat('MMM').format(request.scheduledFor),
                            style: AppTextStyles.caption.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: Gap.s12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat(
                              'EEEE • h:mm a',
                            ).format(request.scheduledFor),
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (sub.isNotEmpty) ...[
                            const SizedBox(height: Gap.s2),
                            Text(
                              sub,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: Gap.s8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Gap.s8,
                        vertical: Gap.s4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: Radii.pill,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 12, color: statusColor),
                          const SizedBox(width: Gap.s4),
                          Text(
                            status[0].toUpperCase() + status.substring(1),
                            style: AppTextStyles.label.copyWith(
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
