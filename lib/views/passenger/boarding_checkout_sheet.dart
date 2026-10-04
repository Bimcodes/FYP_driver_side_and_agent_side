import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/transit_pricing.dart';
import '../../core/theme/app_colors.dart';
import '../../models/bus_qr_payload.dart';
import '../../viewmodels/passenger_dashboard_viewmodel.dart';

import '../agent/shared/pin_input_widget.dart';

class BoardingCheckoutSheet extends ConsumerStatefulWidget {
  final BusQrPayload busPayload;
  final VoidCallback onBoardingComplete;

  const BoardingCheckoutSheet({
    super.key,
    required this.busPayload,
    required this.onBoardingComplete,
  });

  @override
  ConsumerState<BoardingCheckoutSheet> createState() => _BoardingCheckoutSheetState();
}

class _BoardingCheckoutSheetState extends ConsumerState<BoardingCheckoutSheet> {
  Future<String?> _askForPin(BuildContext context) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter your transaction PIN'),
        content: PinInputWidget(
          onChanged: (_) {},
          onCompleted: (pin) => Navigator.pop(ctx, pin),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ],
      ),
    );
  }
  void _showIrreversibleConfirmationDialog({
    required BuildContext sheetContext,
    required int totalFare,
    required int count,
    required String stopName,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Warning Icon
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEF3C7), // Light amber circle
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 32),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'Irreversible Payment',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.agentTextDark, fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                'You are about to boarding confirmation swipe on ${widget.busPayload.routeName}.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.agentTextLight, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 20),

              // Red Warning Container
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFECDD3)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.warning_amber_rounded, color: Color(0xFFE11D48), size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Warning: This transaction is immediate and cannot be reversed',
                        style: TextStyle(color: Color(0xFFE11D48), fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Transaction Summary
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Destination', style: TextStyle(color: AppColors.agentTextLight, fontSize: 13)),
                  Text(stopName, style: const TextStyle(color: AppColors.agentTextDark, fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Passenger Count', style: TextStyle(color: AppColors.agentTextLight, fontSize: 13)),
                  Text('$count Passenger${count > 1 ? "s" : ""}', style: const TextStyle(color: AppColors.agentTextDark, fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(color: Color(0xFFE2E8F0), height: 1),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Amount Due', style: TextStyle(color: AppColors.agentTextLight, fontSize: 14)),
                  Text('₦$totalFare', style: const TextStyle(color: Color(0xFFE11D48), fontSize: 20, fontWeight: FontWeight.w900)),
                ],
              ),
              const SizedBox(height: 28),

              // Red Confirm & Pay Button
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(dialogCtx).pop(); // Dismiss confirmation dialog
                  final pin = await _askForPin(context);
                  if (pin == null) return; // user cancelled
                  
                  final success = await ref
                      .read(passengerDashboardViewModelProvider.notifier)
                      .processBoarding(busPayload: widget.busPayload, pin: pin);

                  if (success && mounted) {
                    widget.onBoardingComplete();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('Confirm & Pay', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),

              // Cancel Button
              OutlinedButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Cancel', style: TextStyle(color: AppColors.agentTextDark, fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(passengerDashboardViewModelProvider);
    final vm = ref.read(passengerDashboardViewModelProvider.notifier);

    final walletBalance = state.wallet?.balance ?? 0.0;
    final totalFare = state.calculatedFare;
    final hasEnoughBalance = walletBalance >= totalFare;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white, // Light bottom sheet from Image 2
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Bus Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.busPayload.vehicleId.toUpperCase(),
                    style: const TextStyle(color: AppColors.agentTextDark, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.busPayload.routeName,
                    style: const TextStyle(color: AppColors.agentTextLight, fontSize: 13),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.check_circle, color: AppColors.agentGreenText, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'VERIFIED BUS',
                      style: TextStyle(color: AppColors.agentGreenText, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(color: Color(0xFFE2E8F0), height: 1),
          const SizedBox(height: 20),

          // Destination Selection
          const Text(
            'Select Destination',
            style: TextStyle(color: AppColors.agentTextDark, fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.agentCardWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<TransitStop>(
                value: state.selectedStop,
                isExpanded: true,
                dropdownColor: Colors.white,
                icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.agentTextDark),
                items: TransitPricing.campusStops.map((stop) {
                  return DropdownMenuItem<TransitStop>(
                    value: stop,
                    child: Text(
                      '${stop.name} — ₦${stop.fareTokens}',
                      style: const TextStyle(color: AppColors.agentTextDark, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  );
                }).toList(),
                onChanged: (stop) {
                  if (stop != null) vm.setDestination(stop);
                },
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Passenger Counter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Passenger Count', style: TextStyle(color: AppColors.agentTextDark, fontSize: 14, fontWeight: FontWeight.w700)),
                  SizedBox(height: 2),
                  Text('Max 10 passengers per swipe', style: TextStyle(color: AppColors.agentTextLight, fontSize: 12)),
                ],
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: state.passengerCount > 1 ? vm.decrementPassengers : null,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.remove, color: AppColors.agentTextDark, size: 18),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '${state.passengerCount}',
                      style: const TextStyle(color: AppColors.agentTextDark, fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ),
                  GestureDetector(
                    onTap: state.passengerCount < 10 ? vm.incrementPassengers : null,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add, color: AppColors.agentGreenText, size: 18),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Fare Summary Box
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Fare', style: TextStyle(color: AppColors.agentTextLight, fontSize: 13, fontWeight: FontWeight.w500)),
                    Text(
                      '₦$totalFare',
                      style: const TextStyle(color: AppColors.agentTextDark, fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Current Balance', style: TextStyle(color: AppColors.agentTextLight, fontSize: 13, fontWeight: FontWeight.w500)),
                    Text(
                      '₦${walletBalance.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: hasEnoughBalance ? AppColors.agentGreenText : const Color(0xFFEF4444),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (!hasEnoughBalance) ...[
            Row(
              children: const [
                Icon(Icons.info_outline, color: Color(0xFFEF4444), size: 16),
                SizedBox(width: 8),
                Text(
                  'Insufficient tokens. Please top up your wallet.',
                  style: TextStyle(color: Color(0xFFEF4444), fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ] else ...[
            const SizedBox(height: 8),
          ],

          // Confirm & Pay Button
          ElevatedButton(
            onPressed: hasEnoughBalance && !state.isBoarding
                ? () => _showIrreversibleConfirmationDialog(
                      sheetContext: context,
                      totalFare: totalFare,
                      count: state.passengerCount,
                      stopName: state.selectedStop.name,
                    )
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: hasEnoughBalance ? AppColors.authPrimary : const Color(0xFFCBD5E1),
              disabledBackgroundColor: const Color(0xFFCBD5E1),
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: state.isBoarding
                ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Confirm & Pay', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
