import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/app_user.dart';
import '../models/session_log.dart';
import '../services/log_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_strings.dart';
import '../utils/app_text_styles.dart';
import '../widgets/empty_state.dart';

enum SessionFilter { all, last7, month }

/// Session logs list (spec §3E): filter chips, latest first,
/// row = date/duration/rating, tap → detail modal with both notes.
class SessionsScreen extends StatefulWidget {
  final AppUser me;
  final LogService logService;
  final Color roleColor;
  final VoidCallback? onScheduleFirst;

  const SessionsScreen({
    super.key,
    required this.me,
    required this.logService,
    required this.roleColor,
    this.onScheduleFirst,
  });

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  SessionFilter _filter = SessionFilter.all;

  List<SessionLog> _applyFilter(List<SessionLog> logs) {
    final now = DateTime.now();
    return switch (_filter) {
      SessionFilter.all => logs,
      SessionFilter.last7 =>
        logs
            .where(
              (l) => l.startedAt.isAfter(now.subtract(const Duration(days: 7))),
            )
            .toList(),
      SessionFilter.month =>
        logs
            .where(
              (l) =>
                  l.startedAt.year == now.year &&
                  l.startedAt.month == now.month,
            )
            .toList(),
    };
  }

  String _duration(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _showDetail(SessionLog log) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => _SessionDetailSheet(
        log: log,
        duration: _duration(log.durationSec),
        roleColor: widget.roleColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final field = widget.me.role == UserRole.member ? 'memberId' : 'trainerId';
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text(AppStrings.sessions)),
      body: StreamBuilder<List<SessionLog>>(
        stream: widget.logService.watch(field, widget.me.id),
        builder: (context, snap) {
          if (snap.hasError) {
            return EmptyState(
              icon: Icons.error_outline_rounded,
              title: AppStrings.genericError,
              ctaLabel: AppStrings.retry,
              onCta: () => setState(() {}),
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final logs = _applyFilter(snap.data!);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filter bar
              _FilterBar(
                selected: _filter,
                onChanged: (f) => setState(() => _filter = f),
                total: snap.data!.length,
                filtered: logs.length,
              ),
              // Content
              Expanded(
                child: logs.isEmpty
                    ? EmptyState(
                        icon: Icons.history_rounded,
                        title: AppStrings.emptySessions,
                        ctaLabel: widget.onScheduleFirst != null
                            ? AppStrings.scheduleFirstCall
                            : null,
                        onCta: widget.onScheduleFirst,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          Gap.s16,
                          Gap.s8,
                          Gap.s16,
                          Gap.s32,
                        ),
                        itemCount: logs.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: Gap.s8),
                        itemBuilder: (context, i) => _SessionCard(
                          log: logs[i],
                          roleColor: widget.roleColor,
                          duration: _duration(logs[i].durationSec),
                          onTap: () => _showDetail(logs[i]),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Filter bar ────────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final SessionFilter selected;
  final void Function(SessionFilter) onChanged;
  final int total;
  final int filtered;

  const _FilterBar({
    required this.selected,
    required this.onChanged,
    required this.total,
    required this.filtered,
  });

  static const _filters = [
    (SessionFilter.all, AppStrings.filterAll),
    (SessionFilter.last7, AppStrings.filterLast7),
    (SessionFilter.month, AppStrings.filterMonth),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceElevated,
      padding: const EdgeInsets.fromLTRB(Gap.s16, Gap.s12, Gap.s16, Gap.s12),
      child: Row(
        children: [
          // Chips scroll horizontally so narrow screens never overflow.
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final (f, label) in _filters)
                    Padding(
                      padding: const EdgeInsets.only(right: Gap.s8),
                      child: ChoiceChip(
                        label: Text(label),
                        selected: selected == f,
                        onSelected: (_) => onChanged(f),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (total > 0)
            Text(
              '$filtered session${filtered == 1 ? '' : 's'}',
              style: AppTextStyles.caption,
            ),
        ],
      ),
    );
  }
}

// ── Session card ──────────────────────────────────────────────────────────────

class _SessionCard extends StatelessWidget {
  final SessionLog log;
  final Color roleColor;
  final String duration;
  final VoidCallback onTap;

  const _SessionCard({
    required this.log,
    required this.roleColor,
    required this.duration,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceElevated,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(Gap.s16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider, width: 1),
          ),
          child: Row(
            children: [
              // Icon column
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.videocam_rounded, color: roleColor, size: 22),
              ),
              const SizedBox(width: Gap.s12),
              // Info column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEE d MMM • h:mm a').format(log.startedAt),
                      style: AppTextStyles.body,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: Gap.s2),
                    Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 12,
                          color: AppColors.slate400,
                        ),
                        const SizedBox(width: Gap.s4),
                        Text(duration, style: AppTextStyles.caption),
                      ],
                    ),
                  ],
                ),
              ),
              // Rating badge
              if (log.rating != null) _RatingBadge(rating: log.rating!),
              const SizedBox(width: Gap.s4),
              const Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: AppColors.slate400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  final int rating;
  const _RatingBadge({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Gap.s8, vertical: Gap.s4),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 13, color: AppColors.warning),
          const SizedBox(width: Gap.s2),
          Text(
            '$rating',
            style: AppTextStyles.label.copyWith(color: AppColors.warning),
          ),
        ],
      ),
    );
  }
}

// ── Session detail bottom sheet ───────────────────────────────────────────────

class _SessionDetailSheet extends StatelessWidget {
  final SessionLog log;
  final String duration;
  final Color roleColor;

  const _SessionDetailSheet({
    required this.log,
    required this.duration,
    required this.roleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.s24, Gap.s8, Gap.s24, Gap.s32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('EEEE, d MMMM yyyy').format(log.startedAt),
            style: AppTextStyles.h2,
          ),
          const SizedBox(height: Gap.s4),
          Text(
            DateFormat('h:mm a').format(log.startedAt),
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: Gap.s16),

          // Stats row
          Row(
            children: [
              _StatChip(
                icon: Icons.timer_outlined,
                label: duration,
                color: roleColor,
              ),
              const SizedBox(width: Gap.s8),
              if (log.rating != null)
                _StatChip(
                  icon: Icons.star_rounded,
                  label: '${log.rating}/5',
                  color: AppColors.warning,
                ),
            ],
          ),

          if (log.memberNotes?.isNotEmpty ?? false) ...[
            const SizedBox(height: Gap.s20),
            Text(AppStrings.memberBadge, style: AppTextStyles.label),
            const SizedBox(height: Gap.s4),
            Text(log.memberNotes!, style: AppTextStyles.body),
          ],
          if (log.trainerNotes?.isNotEmpty ?? false) ...[
            const SizedBox(height: Gap.s16),
            Text(AppStrings.trainerBadge, style: AppTextStyles.label),
            const SizedBox(height: Gap.s4),
            Text(log.trainerNotes!, style: AppTextStyles.body),
          ],
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Gap.s12,
        vertical: Gap.s8,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: Gap.s4),
          Text(label, style: AppTextStyles.label.copyWith(color: color)),
        ],
      ),
    );
  }
}
