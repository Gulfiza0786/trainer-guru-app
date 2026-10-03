import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../utils/wtf_logger.dart';

/// In-app debug banner (spec §8): floating "⋮" button that opens a
/// bottom sheet with env (masked), build info and the last 20 logs.
///
/// Wrap any screen subtree: `DevPanel(appName: 'Guru', child: ...)`.
class DevPanel extends StatelessWidget {
  final String appName;
  final Map<String, String> env;
  final Widget child;

  const DevPanel({
    super.key,
    required this.appName,
    required this.env,
    required this.child,
  });

  void _open(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        maxChildSize: 0.9,
        builder: (_, controller) => _DevSheetContent(
          appName: appName,
          env: env,
          scrollController: controller,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          right: Gap.s12,
          bottom: 100,
          child: SafeArea(child: _DevFab(onTap: () => _open(context))),
        ),
      ],
    );
  }
}

// ── FAB ───────────────────────────────────────────────────────────────────────

class _DevFab extends StatelessWidget {
  final VoidCallback onTap;
  const _DevFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.slate700,
      borderRadius: BorderRadius.circular(14),
      elevation: 4,
      shadowColor: AppColors.slate900.withValues(alpha: 0.3),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bug_report_rounded, color: AppColors.white, size: 16),
              SizedBox(width: Gap.s4),
              Text(
                'DEV',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sheet content ─────────────────────────────────────────────────────────────

class _DevSheetContent extends StatelessWidget {
  final String appName;
  final Map<String, String> env;
  final ScrollController scrollController;

  const _DevSheetContent({
    required this.appName,
    required this.env,
    required this.scrollController,
  });

  static String _maskValue(String v) => v.length <= 4
      ? '••••'
      : '${v.substring(0, 2)}••••${v.substring(v.length - 2)}';

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(Gap.s20, Gap.s8, Gap.s20, Gap.s32),
      children: [
        // Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Gap.s8,
                vertical: Gap.s4,
              ),
              decoration: BoxDecoration(
                color: AppColors.slate700,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'DEV',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(width: Gap.s8),
            Text('$appName Panel', style: AppTextStyles.h2),
          ],
        ),
        const SizedBox(height: Gap.s4),
        Text(
          'debug • Flutter 3.41 • ${DateTime.now().toIso8601String().substring(0, 10)}',
          style: AppTextStyles.caption,
        ),
        const SizedBox(height: Gap.s20),

        // Env section
        _SheetSection(
          title: 'Environment (masked)',
          icon: Icons.vpn_key_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final e in env.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: Gap.s4),
                  child: Row(
                    children: [
                      Text(
                        '${e.key}  ',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.slate500,
                        ),
                      ),
                      Text(
                        _maskValue(e.value),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.slate700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: Gap.s16),

        // Logs section
        _SheetSection(
          title: 'Last ${WtfLog.recent.length} logs',
          icon: Icons.terminal_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final entry in WtfLog.recent)
                Padding(
                  padding: const EdgeInsets.only(bottom: Gap.s4),
                  child: Text(
                    entry.toString(),
                    style: AppTextStyles.caption.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SheetSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SheetSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppColors.guruPrimary),
            const SizedBox(width: Gap.s8),
            Text(title, style: AppTextStyles.h3),
          ],
        ),
        const SizedBox(height: Gap.s12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(Gap.s12),
          decoration: BoxDecoration(
            color: AppColors.slate100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.divider),
          ),
          child: child,
        ),
      ],
    );
  }
}
