import 'package:flutter/material.dart';
import 'package:wtf_shared/wtf_shared.dart';

/// Bordered white surface used for every card in the trainer app.
class SurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color borderColor;

  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Gap.s16),
    this.onTap,
    this.borderColor = AppColors.divider,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: Radii.lg,
        side: BorderSide(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Circle with the first letter of [name], tinted with [color].
class InitialsAvatar extends StatelessWidget {
  final String name;
  final Color color;
  final double size;

  const InitialsAvatar({
    super.key,
    required this.name,
    this.color = AppColors.guruPrimary,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Text(
        initial,
        style: AppTextStyles.h3.copyWith(color: color, fontSize: size * 0.4),
      ),
    );
  }
}

/// Small rounded status label, e.g. "Pending" or "Member".
class StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const StatusPill({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Gap.s8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: Radii.pill,
      ),
      child: Text(label, style: AppTextStyles.label.copyWith(color: color)),
    );
  }
}

/// Square tinted icon badge used in list rows and shortcuts.
class IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const IconBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: Radii.md,
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}

/// Section title with an optional trailing text action.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.s8),
      child: Row(
        children: [
          Expanded(child: Text(title, style: AppTextStyles.h3)),
          if (actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}
