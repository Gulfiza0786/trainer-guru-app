import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wtf_shared/wtf_shared.dart';

import '../blocs/members_cubit.dart';
import '../blocs/requests_cubit.dart';
import '../main.dart';
import 'chat_list_screen.dart';
import 'dashboard_screen.dart';
import 'members_screen.dart';
import 'requests_screen.dart';

/// Top-level destinations of the trainer console.
enum HomeTab { overview, requests, chats, members, sessions }

/// Trainer home (spec §3A): bottom-nav shell around Overview, Requests,
/// Chats, Members and Sessions. Members and requests are loaded once here
/// and shared by every tab.
class HomeScreen extends StatelessWidget {
  final AppUser user;
  const HomeScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => MembersCubit(auth: authService, me: user),
        ),
        BlocProvider(
          create: (_) => RequestsCubit(schedule: scheduleService, me: user),
        ),
      ],
      child: _HomeShell(user: user),
    );
  }
}

class _HomeShell extends StatefulWidget {
  final AppUser user;
  const _HomeShell({required this.user});

  @override
  State<_HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<_HomeShell> {
  HomeTab _tab = HomeTab.overview;

  void _select(HomeTab tab) => setState(() => _tab = tab);

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final pending = context.select<RequestsCubit, int>(
      (c) => c.state.pending.length,
    );

    return Scaffold(
      body: IndexedStack(
        index: _tab.index,
        children: [
          DashboardScreen(user: user, onOpenTab: _select),
          RequestsScreen(me: user),
          ChatListScreen(
            me: user,
            chatService: chatService,
            authService: authService,
          ),
          const MembersScreen(),
          SessionsScreen(
            me: user,
            logService: logService,
            roleColor: AppColors.trainerPrimary,
          ),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: NavigationBar(
          selectedIndex: _tab.index,
          onDestinationSelected: (i) => _select(HomeTab.values[i]),
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.space_dashboard_outlined),
              selectedIcon: Icon(Icons.space_dashboard_rounded),
              label: AppStrings.overview,
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: pending > 0,
                label: Text('$pending'),
                backgroundColor: AppColors.trainerPrimary,
                child: const Icon(Icons.inbox_outlined),
              ),
              selectedIcon: Badge(
                isLabelVisible: pending > 0,
                label: Text('$pending'),
                backgroundColor: AppColors.trainerPrimary,
                child: const Icon(Icons.inbox_rounded),
              ),
              label: AppStrings.requests,
            ),
            const NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline_rounded),
              selectedIcon: Icon(Icons.chat_bubble_rounded),
              label: AppStrings.chats,
            ),
            const NavigationDestination(
              icon: Icon(Icons.group_outlined),
              selectedIcon: Icon(Icons.group_rounded),
              label: AppStrings.members,
            ),
            const NavigationDestination(
              icon: Icon(Icons.history_rounded),
              selectedIcon: Icon(Icons.history_rounded),
              label: AppStrings.sessions,
            ),
          ],
        ),
      ),
    );
  }
}
