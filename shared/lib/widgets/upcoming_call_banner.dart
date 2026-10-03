import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/call_request.dart';
import '../utils/app_colors.dart';
import '../utils/app_strings.dart';
import '../utils/app_text_styles.dart';

/// Join window opens 10 minutes before the scheduled time (spec §3D)
/// and stays open for 30 minutes after.
bool isJoinable(CallRequest r, DateTime now) =>
    r.status == CallStatus.approved &&
    now.isAfter(r.scheduledFor.subtract(const Duration(minutes: 10))) &&
    now.isBefore(r.scheduledFor.add(const Duration(minutes: 30)));

/// Upcoming Calls banner: shows approved calls; the Join Call CTA
/// activates inside the join window. Re-evaluates every 30s.
class UpcomingCallBanner extends StatefulWidget {
  final Stream<List<CallRequest>> approvedStream;
  final Color roleColor;
  final void Function(CallRequest request) onJoin;

  const UpcomingCallBanner({
    super.key,
    required this.approvedStream,
    required this.roleColor,
    required this.onJoin,
  });

  @override
  State<UpcomingCallBanner> createState() => _UpcomingCallBannerState();
}

class _UpcomingCallBannerState extends State<UpcomingCallBanner> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(
      const Duration(seconds: 30),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CallRequest>>(
      stream: widget.approvedStream,
      builder: (context, snap) {
        final now = DateTime.now();
        final upcoming =
            (snap.data ?? [])
                .where(
                  (r) =>
                      r.status == CallStatus.approved &&
                      r.scheduledFor.isAfter(
                        now.subtract(const Duration(minutes: 30)),
                      ),
                )
                .toList()
              ..sort((a, b) => a.scheduledFor.compareTo(b.scheduledFor));

        if (upcoming.isEmpty) return const SizedBox.shrink();

        final next = upcoming.first;
        final joinable = isJoinable(next, now);

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.roleColor,
                widget.roleColor.withValues(alpha: 0.85),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(Gap.s16),
          child: Row(
            children: [
              // Icon column
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.videocam_rounded,
                  color: AppColors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: Gap.s12),
              // Info column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.upcomingCalls,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: Gap.s2),
                    Text(
                      DateFormat(
                        'EEE d MMM • h:mm a',
                      ).format(next.scheduledFor),
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Gap.s8),
              // Join CTA
              _JoinButton(
                joinable: joinable,
                scheduledFor: next.scheduledFor,
                onJoin: () => widget.onJoin(next),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _JoinButton extends StatelessWidget {
  final bool joinable;
  final DateTime scheduledFor;
  final VoidCallback onJoin;

  const _JoinButton({
    required this.joinable,
    required this.scheduledFor,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: joinable
              ? AppColors.white
              : AppColors.white.withValues(alpha: 0.25),
          foregroundColor: joinable ? AppColors.guruPrimary : AppColors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(80, 38),
          padding: const EdgeInsets.symmetric(
            horizontal: Gap.s12,
            vertical: Gap.s8,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: AppTextStyles.label,
        ),
        onPressed: joinable ? onJoin : null,
        icon: const Icon(Icons.videocam_rounded, size: 16),
        label: Text(
          joinable
              ? AppStrings.joinCall
              : DateFormat('h:mm a').format(scheduledFor),
        ),
      ),
    );
  }
}
