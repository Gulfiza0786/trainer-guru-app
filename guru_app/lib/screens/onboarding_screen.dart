import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wtf_shared/wtf_shared.dart';

import '../blocs/auth_cubit.dart';

/// Two intro slides + DK profile form with trainer picker (spec §3A).
class OnboardingScreen extends StatefulWidget {
  final List<AppUser> trainers;
  const OnboardingScreen({super.key, required this.trainers});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  final _nameController = TextEditingController(text: 'DK');
  String? _selectedTrainerId;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    if (widget.trainers.isNotEmpty) {
      _selectedTrainerId = widget.trainers.first.id;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _next() => _pageController.nextPage(
    duration: const Duration(milliseconds: 350),
    curve: Curves.easeInOut,
  );

  // ── Intro slide ─────────────────────────────────────────────────────────────
  Widget _slide({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String body,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: Gap.s32,
          vertical: Gap.s24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Layered rings around the icon tile
            Container(
              width: 220,
              height: 220,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconColor.withValues(alpha: 0.04),
              ),
              child: Container(
                width: 160,
                height: 160,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconColor.withValues(alpha: 0.07),
                ),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: Radii.xxl,
                    border: Border.all(
                      color: iconColor.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(icon, size: 48, color: iconColor),
                ),
              ),
            ),
            const SizedBox(height: Gap.s40),
            Text(
              title,
              style: AppTextStyles.display,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Gap.s12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                body,
                style: AppTextStyles.body.copyWith(color: AppColors.slate500),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Profile form ────────────────────────────────────────────────────────────
  Widget _profileForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(Gap.s24, Gap.s32, Gap.s24, Gap.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(Gap.s20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.guruPrimary, AppColors.guruAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: Radii.xl,
              boxShadow: [
                BoxShadow(
                  color: AppColors.guruPrimary.withValues(alpha: 0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.2),
                    borderRadius: Radii.md,
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: AppColors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(height: Gap.s12),
                Text(
                  AppStrings.createProfile,
                  style: AppTextStyles.h1.copyWith(color: AppColors.white),
                ),
                const SizedBox(height: Gap.s4),
                Text(
                  'Set up your profile to get started',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: Gap.s24),

          // Name field
          Text(
            'Your name',
            style: AppTextStyles.label.copyWith(color: AppColors.slate600),
          ),
          const SizedBox(height: Gap.s8),
          TextField(
            controller: _nameController,
            style: AppTextStyles.body,
            decoration: const InputDecoration(
              labelText: AppStrings.yourName,
              prefixIcon: Icon(Icons.badge_rounded),
            ),
          ),

          const SizedBox(height: Gap.s24),

          // Trainer picker header
          Text(AppStrings.chooseTrainer, style: AppTextStyles.h3),
          const SizedBox(height: Gap.s4),
          Text(
            'Select the trainer you want to work with',
            style: AppTextStyles.bodySmall,
          ),

          const SizedBox(height: Gap.s12),

          // Trainer cards
          Column(
            children: [
              for (final t in widget.trainers)
                _TrainerCard(
                  trainer: t,
                  isSelected: t.id == _selectedTrainerId,
                  onTap: () => setState(() => _selectedTrainerId = t.id),
                ),
            ],
          ),

          const SizedBox(height: Gap.s32),

          // CTA
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _selectedTrainerId == null
                  ? null
                  : () => context.read<AuthCubit>().completeOnboarding(
                      name: _nameController.text.trim(),
                      trainerId: _selectedTrainerId!,
                    ),
              icon: const Icon(Icons.rocket_launch_rounded, size: 18),
              label: const Text(AppStrings.getStarted),
            ),
          ),

          const SizedBox(height: Gap.s16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _slide(
                    icon: Icons.fitness_center_rounded,
                    iconBg: AppColors.guruPrimary.withValues(alpha: 0.1),
                    iconColor: AppColors.guruPrimary,
                    title: AppStrings.onboardTitle1,
                    body: AppStrings.onboardBody1,
                  ),
                  _slide(
                    icon: Icons.video_chat_rounded,
                    iconBg: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                    iconColor: const Color(0xFF7C3AED),
                    title: AppStrings.onboardTitle2,
                    body: AppStrings.onboardBody2,
                  ),
                  _profileForm(),
                ],
              ),
            ),

            // Bottom nav bar (only on intro slides)
            if (_page < 2)
              _OnboardingNav(page: _page, totalSlides: 2, onNext: _next),
          ],
        ),
      ),
    );
  }
}

// ── Progress dot nav bar ──────────────────────────────────────────────────────

class _OnboardingNav extends StatelessWidget {
  final int page;
  final int totalSlides;
  final VoidCallback onNext;

  const _OnboardingNav({
    required this.page,
    required this.totalSlides,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Gap.s24,
        vertical: Gap.s20,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceElevated,
        border: Border(top: BorderSide(color: AppColors.divider, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Pill progress dots
          Row(
            children: [
              for (var i = 0; i < totalSlides; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  margin: const EdgeInsets.only(right: 6),
                  width: i == page ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == page
                        ? AppColors.guruPrimary
                        : AppColors.slate300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
            ],
          ),

          // Next button
          FilledButton(
            onPressed: onNext,
            style: FilledButton.styleFrom(minimumSize: const Size(100, 44)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(AppStrings.next),
                const SizedBox(width: Gap.s8),
                const Icon(Icons.arrow_forward_rounded, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Trainer selection card ────────────────────────────────────────────────────

class _TrainerCard extends StatelessWidget {
  final AppUser trainer;
  final bool isSelected;
  final VoidCallback onTap;

  const _TrainerCard({
    required this.trainer,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: Gap.s8),
        padding: const EdgeInsets.symmetric(
          horizontal: Gap.s16,
          vertical: Gap.s12,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.guruPrimary.withValues(alpha: 0.06)
              : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.guruPrimary : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.trainerPrimary.withValues(alpha: 0.12),
              child: Text(
                trainer.name.substring(0, 1).toUpperCase(),
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.trainerPrimary,
                ),
              ),
            ),
            const SizedBox(width: Gap.s12),
            Expanded(child: Text(trainer.name, style: AppTextStyles.h3)),
            if (isSelected)
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: AppColors.guruPrimary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: AppColors.white,
                  size: 14,
                ),
              )
            else
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.slate300, width: 2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
