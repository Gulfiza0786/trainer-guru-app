import 'package:flutter/material.dart';
import 'package:wtf_shared/wtf_shared.dart';

import '../main.dart';
import 'call_launcher.dart';
import 'chat_entry.dart';
import 'schedule_screen.dart';

/// Guru home (spec §3A): hero greeting + 3 action cards — Chat with Trainer,
/// Schedule Call, My Sessions — plus the Upcoming Calls join banner (spec §3D).
class HomeScreen extends StatelessWidget {
  final AppUser user;
  const HomeScreen({super.key, required this.user});

  static const _violet = Color(0xFF7C3AED);
  static const _green = Color(0xFF0D9B6C);

  void _push(BuildContext context, Widget screen) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => screen));

  void _openChat(BuildContext context) => _push(
    context,
    ChatEntry(me: user, authService: authService, chatService: chatService),
  );

  void _openSchedule(BuildContext context) => _push(
    context,
    ScheduleScreen(me: user, scheduleService: scheduleService),
  );

  void _openSessions(BuildContext context) => _push(
    context,
    SessionsScreen(
      me: user,
      logService: logService,
      roleColor: AppColors.guruPrimary,
      onScheduleFirst: () => _openSchedule(context),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          _HeroAppBar(user: user),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              Gap.s16,
              Gap.s20,
              Gap.s16,
              Gap.s32,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Upcoming calls banner
                UpcomingCallBanner(
                  approvedStream: scheduleService.watchApproved(
                    'memberId',
                    user.id,
                  ),
                  roleColor: AppColors.guruPrimary,
                  onJoin: (request) => launchCall(context, user, request),
                ),
                const SizedBox(height: Gap.s20),

                const _SectionLabel('QUICK ACTIONS'),

                // Featured: chat with trainer
                _FeaturedChatCard(onTap: () => _openChat(context)),
                const SizedBox(height: Gap.s12),

                // Secondary actions side by side
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _ActionTile(
                          icon: Icons.calendar_month_rounded,
                          title: AppStrings.scheduleCall,
                          subtitle: 'Book a video session',
                          accentColor: _violet,
                          onTap: () => _openSchedule(context),
                        ),
                      ),
                      const SizedBox(width: Gap.s12),
                      Expanded(
                        child: _ActionTile(
                          icon: Icons.play_circle_rounded,
                          title: AppStrings.mySessions,
                          subtitle: 'Review past calls & ratings',
                          accentColor: _green,
                          onTap: () => _openSessions(context),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: Gap.s24),
                const _TipCard(),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hero SliverAppBar ─────────────────────────────────────────────────────────

class _HeroAppBar extends StatelessWidget {
  final AppUser user;
  const _HeroAppBar({required this.user});

  static const _radius = BorderRadius.vertical(bottom: Radius.circular(28));

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 188,
      pinned: true,
      backgroundColor: AppColors.guruPrimary,
      foregroundColor: AppColors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: _radius),
      flexibleSpace: ClipRRect(
        borderRadius: _radius,
        child: FlexibleSpaceBar(
          collapseMode: CollapseMode.pin,
          background: _HeroBanner(user: user),
        ),
      ),
      // Collapsed state title
      title: Text(
        '${AppStrings.memberBadge} · ${user.name}',
        style: AppTextStyles.h3.copyWith(color: AppColors.white),
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  final AppUser user;
  const _HeroBanner({required this.user});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.guruPrimary, AppColors.guruAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Decorative soft circles
          Positioned(
            top: -40,
            right: -30,
            child: _Bubble(size: 160, alpha: 0.10),
          ),
          Positioned(
            bottom: -50,
            right: 70,
            child: _Bubble(size: 110, alpha: 0.07),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Gap.s20,
              Gap.s48 + Gap.s24,
              Gap.s20,
              Gap.s24,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _MemberPill(label: AppStrings.memberBadge),
                      const SizedBox(height: Gap.s8),
                      Text(
                        '${_greeting()},',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.white.withValues(alpha: 0.85),
                        ),
                      ),
                      Text(
                        user.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.display.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Gap.s12),
                _Avatar(name: user.name, size: 56),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final double size;
  final double alpha;
  const _Bubble({required this.size, required this.alpha});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.white.withValues(alpha: alpha),
      ),
    );
  }
}

class _MemberPill extends StatelessWidget {
  final String label;
  const _MemberPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Gap.s8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.18),
        borderRadius: Radii.pill,
        border: Border.all(color: AppColors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.workspace_premium_rounded,
            size: 12,
            color: AppColors.white,
          ),
          const SizedBox(width: Gap.s4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: Gap.s4, bottom: Gap.s12),
      child: Text(
        text,
        style: AppTextStyles.label.copyWith(
          color: AppColors.slate500,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ── Featured chat card ────────────────────────────────────────────────────────

class _FeaturedChatCard extends StatelessWidget {
  final VoidCallback onTap;
  const _FeaturedChatCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: Radii.xl,
        boxShadow: [
          BoxShadow(
            color: AppColors.guruPrimary.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        borderRadius: Radii.xl,
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.guruPrimary, AppColors.guruAccent],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            splashColor: AppColors.white.withValues(alpha: 0.12),
            child: Padding(
              padding: const EdgeInsets.all(Gap.s20),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.2),
                      borderRadius: Radii.lg,
                    ),
                    child: const Icon(
                      Icons.chat_bubble_rounded,
                      color: AppColors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: Gap.s16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.chatWithTrainer,
                          style: AppTextStyles.h3.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                        const SizedBox(height: Gap.s2),
                        Text(
                          'Send messages & share files',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: AppColors.guruPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Action tile ───────────────────────────────────────────────────────────────

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceElevated,
      borderRadius: Radii.xl,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: accentColor.withValues(alpha: 0.08),
        highlightColor: accentColor.withValues(alpha: 0.04),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.divider),
            borderRadius: Radii.xl,
          ),
          padding: const EdgeInsets.all(Gap.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      borderRadius: Radii.md,
                    ),
                    child: Icon(icon, color: accentColor, size: 22),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.north_east_rounded,
                    size: 16,
                    color: AppColors.slate400,
                  ),
                ],
              ),
              const SizedBox(height: Gap.s16),
              Text(title, style: AppTextStyles.h3),
              const SizedBox(height: Gap.s2),
              Text(subtitle, style: AppTextStyles.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tip card ──────────────────────────────────────────────────────────────────

class _TipCard extends StatelessWidget {
  const _TipCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Gap.s16),
      decoration: BoxDecoration(
        color: AppColors.guruPrimary.withValues(alpha: 0.06),
        borderRadius: Radii.lg,
        border: Border.all(
          color: AppColors.guruPrimary.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_rounded,
            size: 20,
            color: AppColors.guruPrimary,
          ),
          const SizedBox(width: Gap.s12),
          Expanded(
            child: Text(
              'Book your next session in advance — your trainer approves '
              'requests and you can join right from here.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.slate700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Avatar ────────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String name;
  final double size;

  const _Avatar({required this.name, this.size = 36});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.white.withValues(alpha: 0.6),
          width: 2,
        ),
      ),
      child: CircleAvatar(
        backgroundColor: AppColors.white.withValues(alpha: 0.2),
        foregroundColor: AppColors.white,
        child: Text(
          name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
          style: AppTextStyles.h2.copyWith(color: AppColors.white),
        ),
      ),
    );
  }
}
