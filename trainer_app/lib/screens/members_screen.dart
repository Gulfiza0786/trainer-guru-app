import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wtf_shared/wtf_shared.dart';

import '../blocs/members_cubit.dart';
import '../widgets/trainer_widgets.dart';

/// Basic CRM list (spec core modules): members assigned to this trainer,
/// with a local search filter. Expects a [MembersCubit] above it.
class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  String _query = '';

  List<AppUser> _filter(List<AppUser> members) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return members;
    return members
        .where(
          (m) =>
              m.name.toLowerCase().contains(q) ||
              m.email.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<MembersCubit>().state;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.members)),
      body: switch (state) {
        MembersState(loading: true) =>
          const Center(child: CircularProgressIndicator()),
        MembersState(failed: true) => EmptyState(
            icon: Icons.error_outline_rounded,
            title: AppStrings.genericError,
            ctaLabel: AppStrings.retry,
            onCta: context.read<MembersCubit>().load,
          ),
        MembersState(members: []) => const EmptyState(
            icon: Icons.group_rounded,
            title: AppStrings.noMembers,
          ),
        _ => _buildList(state.members),
      },
    );
  }

  Widget _buildList(List<AppUser> all) {
    final visible = _filter(all);
    return ListView(
      padding: const EdgeInsets.all(Gap.s16),
      children: [
        TextField(
          onChanged: (v) => setState(() => _query = v),
          style: AppTextStyles.body,
          decoration: const InputDecoration(
            hintText: AppStrings.searchMembers,
            prefixIcon: Icon(Icons.search_rounded),
            contentPadding: EdgeInsets.symmetric(vertical: Gap.s12),
          ),
        ),
        const SizedBox(height: Gap.s20),
        Padding(
          padding: const EdgeInsets.only(left: Gap.s4, bottom: Gap.s8),
          child: Text(
            AppStrings.memberCount(visible.length).toUpperCase(),
            style: AppTextStyles.label.copyWith(
              color: AppColors.slate500,
              letterSpacing: 1,
            ),
          ),
        ),
        if (visible.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: Gap.s24),
            child: Text(
              AppStrings.noMatches,
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          )
        else
          SurfaceCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < visible.length; i++) ...[
                  if (i > 0) const Divider(indent: 72),
                  _MemberRow(member: visible[i]),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _MemberRow extends StatelessWidget {
  final AppUser member;
  const _MemberRow({required this.member});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Gap.s16,
        vertical: Gap.s12,
      ),
      child: Row(
        children: [
          InitialsAvatar(name: member.name),
          const SizedBox(width: Gap.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.name, style: AppTextStyles.h3),
                Text(
                  member.email,
                  style: AppTextStyles.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const StatusPill(
            label: AppStrings.memberBadge,
            color: AppColors.guruPrimary,
          ),
        ],
      ),
    );
  }
}
