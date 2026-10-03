import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wtf_shared/wtf_shared.dart';

import '../blocs/auth_cubit.dart';

/// Mock login (spec §3A) — email prefilled, any password works.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: 'aarav@wtf.fit');
  final _passwordController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceElevated,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _BrandHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Gap.s24,
                Gap.s32,
                Gap.s24,
                Gap.s48,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(AppStrings.loginHeading, style: AppTextStyles.h1),
                  const SizedBox(height: Gap.s4),
                  Text(
                    AppStrings.loginSubheading,
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(height: Gap.s32),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    style: AppTextStyles.body,
                    decoration: const InputDecoration(
                      labelText: AppStrings.email,
                      prefixIcon: Icon(Icons.alternate_email_rounded),
                    ),
                  ),
                  const SizedBox(height: Gap.s16),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscure,
                    style: AppTextStyles.body,
                    onSubmitted: (_) => context.read<AuthCubit>().login(),
                    decoration: InputDecoration(
                      labelText: AppStrings.password,
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: Gap.s32),
                  ElevatedButton(
                    onPressed: () => context.read<AuthCubit>().login(),
                    child: const Text(AppStrings.login),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Coral gradient header with the brand mark and tagline.
class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.trainerPrimary, AppColors.trainerAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -40,
            top: -20,
            child: Icon(
              Icons.fitness_center_rounded,
              size: 200,
              color: AppColors.white.withValues(alpha: 0.1),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                Gap.s24,
                Gap.s40,
                Gap.s24,
                Gap.s40,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.2),
                      borderRadius: Radii.lg,
                      border: Border.all(
                        color: AppColors.white.withValues(alpha: 0.35),
                      ),
                    ),
                    child: const Icon(
                      Icons.fitness_center_rounded,
                      color: AppColors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: Gap.s24),
                  Text(
                    AppStrings.trainerConsole.toUpperCase(),
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.white.withValues(alpha: 0.85),
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: Gap.s8),
                  Text(
                    AppStrings.loginTagline,
                    style: AppTextStyles.h1.copyWith(color: AppColors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
