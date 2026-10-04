import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'agent_dashboard_view.dart';
import 'agent_history_view.dart';
import 'agent_scan_qr_view.dart';
import 'profile/agent_profile_view.dart';
import '../../core/theme/app_colors.dart';

import 'shared/session_timeout_manager.dart';

final agentTabIndexProvider = StateProvider<int>((ref) => 0);

class AgentMainView extends ConsumerStatefulWidget {
  const AgentMainView({super.key});

  @override
  ConsumerState<AgentMainView> createState() => _AgentMainViewState();
}

class _AgentMainViewState extends ConsumerState<AgentMainView> {
  final List<Widget> _screens = [
    const AgentDashboardView(),
    const AgentScanQrView(),
    const AgentHistoryView(),
    const AgentProfileView(),
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(agentTabIndexProvider);

    return SessionTimeoutManager(
      timeoutDuration: const Duration(minutes: 5), // 5 minutes standard
      child: Scaffold(
        backgroundColor: AppColors.agentLightBackground,
        body: IndexedStack(
          index: currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
          ),
          child: BottomNavigationBar(
            backgroundColor: AppColors.agentCardWhite,
            selectedItemColor: AppColors.agentBlue,
            unselectedItemColor: AppColors.agentTextLight,
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
            currentIndex: currentIndex,
            onTap: (index) {
              ref.read(agentTabIndexProvider.notifier).state = index;
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Overview',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.qr_code_scanner_outlined),
                activeIcon: Icon(Icons.qr_code_scanner),
                label: 'Scan QR',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.list_alt_outlined),
                activeIcon: Icon(Icons.list_alt),
                label: 'Ledger',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
