import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:wtf_shared/wtf_shared.dart';

import '../blocs/members_cubit.dart';
import '../blocs/requests_cubit.dart';
import '../main.dart';
import '../widgets/trainer_widgets.dart';
import 'call_launcher.dart';
import 'home_screen.dart';

/// Overview tab: greeting, today's focus, key stats, upcoming calls
/// (spec §3D) and a preview of requests awaiting review.
class DashboardScreen extends StatefulWidget {
  final AppUser user;
  final ValueChanged<HomeTab> onOpenTab;

  const DashboardScreen({
    super.key,
    required this.user,
    required this.onOpenTab,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Created once so rebuilds don't re-subscribe.
  late final _approved = scheduleService.watchApproved(
    'trainerId',
    widget.user.id,
  );
  late final _sessions = logService.watch('trainerId', widget.user.id);

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final onOpenTab = widget.onOpenTab;
    final requests = context.watch<RequestsCubit>().state;
    final members = context.watch<MembersCubit>().state;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Gap.s20,
            Gap.s16,
            Gap.s20,
            Gap.s32,
          ),
          children: [
            _Greeting(user: user),
            const SizedBox(height: Gap.s24),
            _FocusCard(
              pendingCount: requests.pending.length,
              onReview: () => onOpenTab(HomeTab.requests),
            ),
            const SizedBox(height: Gap.s16),
            _StatsRow(
              sessions: _sessions,
              memberCount: members.members.length,
              pendingCount: requests.pending.length,
              onOpenTab: onOpenTab,
            ),
            const SizedBox(height: Gap.s24),
            UpcomingCallBanner(
              approvedStream: _approved,
              roleColor: AppColors.trainerPrimary,
              onJoin: (request) => launchCall(context, user, request),
            ),
            const SizedBox(height: Gap.s8),
            SectionHeader(
              title: AppStrings.needsAttention,
              actionLabel: requests.pending.isEmpty ? null : AppStrings.seeAll,
              onAction: () => onOpenTab(HomeTab.requests),
            ),
            if (requests.pending.isEmpty)
              const _CaughtUp()
            else
              for (final r in requests.pending.take(3)) ...[
                _PendingRow(
                  request: r,
                  memberName: members.nameOf(r.memberId),
                  onTap: () => onOpenTab(HomeTab.requests),
                ),
                const SizedBox(height: Gap.s8),
              ],
            const SizedBox(height: Gap.s16),
            const SectionHeader(title: AppStrings.shortcuts),
            _ShortcutRow(
              icon: Icons.chat_bubble_rounded,
              color: AppColors.guruPrimary,
              title: AppStrings.chats,
              subtitle: AppStrings.messagesShortcutBody,
              onTap: () => onOpenTab(HomeTab.chats),
            ),
            const SizedBox(height: Gap.s8),
            _ShortcutRow(
              icon: Icons.history_rounded,
              color: AppColors.success,
              title: AppStrings.sessions,
              subtitle: AppStrings.historyShortcutBody,
              onTap: () => onOpenTab(HomeTab.sessions),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Greeting header ───────────────────────────────────────────────────────────

class _Greeting extends StatelessWidget {
  final AppUser user;
  const _Greeting({required this.user});

  String _salutation(DateTime now) {
    if (now.hour < 12) return AppStrings.goodMorning;
    if (now.hour < 17) return AppStrings.goodAfternoon;
    return AppStrings.goodEvening;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('EEEE, d MMMM').format(now).toUpperCase(),
                style: AppTextStyles.label.copyWith(
                  color: AppColors.slate500,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: Gap.s4),
              Text(
                '${_salutation(now)}, ${user.name.split(' ').first}',
                style: AppTextStyles.h1,
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(Gap.s2),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [AppColors.trainerPrimary, AppColors.trainerAccent],
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(Gap.s2),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: InitialsAvatar(
              name: user.name,
              color: AppColors.trainerPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Focus card ────────────────────────────────────────────────────────────────

class _FocusCard extends StatelessWidget {
  final int pendingCount;
  final VoidCallback onReview;

  const _FocusCard({required this.pendingCount, required this.onReview});

  @override
  Widget build(BuildContext context) {
    final hasPending = pendingCount > 0;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: Radii.xl,
        gradient: const LinearGradient(
          colors: [AppColors.trainerPrimary, AppColors.trainerAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.trainerPrimary.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            bottom: -28,
            child: Icon(
              Icons.fitness_center_rounded,
              size: 140,
              color: AppColors.white.withValues(alpha: 0.12),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Gap.s20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.todaysFocus,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.white.withValues(alpha: 0.85),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: Gap.s8),
                Text(
                  hasPending
                      ? AppStrings.awaitingReview(pendingCount)
                      : AppStrings.allCaughtUp,
                  style: AppTextStyles.h2.copyWith(color: AppColors.white),
                ),
                const SizedBox(height: Gap.s4),
                Text(
                  hasPending
                      ? AppStrings.focusPendingBody
                      : AppStrings.allCaughtUpBody,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.white.withValues(alpha: 0.85),
                  ),
                ),
                if (hasPending) ...[
                  const SizedBox(height: Gap.s16),
                  FilledButton.icon(
                    onPressed: onReview,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.white,
                      foregroundColor: AppColors.trainerPrimary,
                    ),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: const Text(AppStrings.reviewRequests),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stats row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final Stream<List<SessionLog>> sessions;
  final int memberCount;
  final int pendingCount;
  final ValueChanged<HomeTab> onOpenTab;

  const _StatsRow({
    required this.sessions,
    required this.memberCount,
    required this.pendingCount,
    required this.onOpenTab,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: Icons.group_rounded,
            color: AppColors.guruPrimary,
            value: '$memberCount',
            label: AppStrings.members,
            onTap: () => onOpenTab(HomeTab.members),
          ),
        ),
        const SizedBox(width: Gap.s12),
        Expanded(
          child: _StatTile(
            icon: Icons.inbox_rounded,
            color: AppColors.warning,
            value: '$pendingCount',
            label: AppStrings.pending,
            onTap: () => onOpenTab(HomeTab.requests),
          ),
        ),
        const SizedBox(width: Gap.s12),
        Expanded(
          child: StreamBuilder<List<SessionLog>>(
            stream: sessions,
            builder: (context, snap) => _StatTile(
              icon: Icons.play_circle_rounded,
              color: AppColors.success,
              value: snap.hasData ? '${snap.data!.length}' : '–',
              label: AppStrings.sessions,
              onTap: () => onOpenTab(HomeTab.sessions),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  final VoidCallback onTap;

  const _StatTile({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.all(Gap.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBadge(icon: icon, color: color, size: 32),
          const SizedBox(height: Gap.s12),
          Text(value, style: AppTextStyles.h1),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

// ── Pending preview ───────────────────────────────────────────────────────────

class _PendingRow extends StatelessWidget {
  final CallRequest request;
  final String memberName;
  final VoidCallback onTap;

  const _PendingRow({
    required this.request,
    required this.memberName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: Gap.s16,
        vertical: Gap.s12,
      ),
      child: Row(
        children: [
          InitialsAvatar(name: memberName, size: 40),
          const SizedBox(width: Gap.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(memberName, style: AppTextStyles.h3),
                Text(
                  DateFormat('EEE d MMM • h:mm a').format(request.scheduledFor),
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          const StatusPill(label: AppStrings.pending, color: AppColors.warning),
        ],
      ),
    );
  }
}

class _CaughtUp extends StatelessWidget {
  const _CaughtUp();

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Row(
        children: [
          const IconBadge(
            icon: Icons.task_alt_rounded,
            color: AppColors.success,
          ),
          const SizedBox(width: Gap.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.allCaughtUp, style: AppTextStyles.h3),
                Text(AppStrings.allCaughtUpBody, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shortcut row ──────────────────────────────────────────────────────────────

class _ShortcutRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ShortcutRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: Gap.s16,
        vertical: Gap.s12,
      ),
      child: Row(
        children: [
          IconBadge(icon: icon, color: color),
          const SizedBox(width: Gap.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.h3),
                Text(subtitle, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.slate400),
        ],
      ),
    );
  }
}
