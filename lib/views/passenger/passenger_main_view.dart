import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import 'passenger_profile_view.dart';
import 'passenger_dashboard_view.dart';
import 'passenger_history_view.dart';
import 'passenger_scanner_view.dart';

final passengerTabIndexProvider = StateProvider<int>((ref) => 0);

class PassengerMainView extends ConsumerStatefulWidget {
  const PassengerMainView({super.key});

  @override
  ConsumerState<PassengerMainView> createState() => _PassengerMainViewState();
}

class _PassengerMainViewState extends ConsumerState<PassengerMainView> {
  final List<Widget> _screens = [
    const PassengerDashboardView(),
    const PassengerScannerView(),
    const PassengerHistoryView(),
    const PassengerProfileView(),
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(passengerTabIndexProvider);

    return Scaffold(
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
          selectedItemColor: AppColors.authPrimary,
          unselectedItemColor: AppColors.agentTextLight,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          currentIndex: currentIndex,
          onTap: (index) {
            ref.read(passengerTabIndexProvider.notifier).state = index;
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
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
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
    );
  }
}
