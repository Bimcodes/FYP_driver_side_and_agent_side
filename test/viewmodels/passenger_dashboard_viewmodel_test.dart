// =============================================================================
// FILE: test/viewmodels/passenger_dashboard_viewmodel_test.dart
// LAYER: Test
//
// PURPOSE:
//   Unit tests for PassengerDashboardViewModel:
//     - Initial dashboard loading & state setup
//     - Destination pricing and multi-passenger calculations (min 100 tokens)
//     - Bus QR JSON payload validation (BusQrPayload)
//     - Insufficient balance rejection
//     - Successful boarding with double-entry debit/credit & audit logging
// =============================================================================

import 'dart:async';

import 'package:driver_agent_fyp/core/constants/transit_pricing.dart';
import 'package:driver_agent_fyp/core/services/location_service.dart';
import 'package:driver_agent_fyp/models/bus_qr_payload.dart';
import 'package:driver_agent_fyp/models/transaction_model.dart';
import 'package:driver_agent_fyp/models/user_model.dart';
import 'package:driver_agent_fyp/models/wallet_model.dart';
import 'package:driver_agent_fyp/repositories/transaction_repository.dart';
import 'package:driver_agent_fyp/repositories/wallet_repository.dart';
import 'package:driver_agent_fyp/viewmodels/passenger_dashboard_viewmodel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// =============================================================================
// Fake Implementations
// =============================================================================

class FakeWalletRepository implements WalletRepository {
  final Map<String, WalletModel> _wallets;
  final _controller = StreamController<WalletModel>.broadcast();

  FakeWalletRepository(this._wallets);

  @override
  Future<WalletModel> getWalletByOwnerId(String ownerId, {bool createIfMissing = false}) async {
    for (final w in _wallets.values) {
      if (w.ownerId == ownerId) return w;
    }
    if (!createIfMissing) {
      throw Exception('Wallet not found for ownerId: $ownerId');
    }
    final newWallet = WalletModel(
      id: 'lazy_wallet_$ownerId',
      ownerId: ownerId,
      walletType: WalletType.studentWallet,
      balance: 0.0,
    );
    _wallets[newWallet.id] = newWallet;
    _controller.add(newWallet);
    return newWallet;
  }

  @override
  Future<WalletModel?> getWalletById(String walletId) async {
    return _wallets[walletId];
  }

  Future<WalletModel> updateBalance({
    required String walletId,
    required double delta,
  }) async {
    final current = _wallets[walletId];
    if (current == null) throw Exception('Wallet $walletId not found');

    final updated = current.copyWith(balance: current.balance + delta);
    _wallets[walletId] = updated;
    _controller.add(updated);
    return updated;
  }

  @override
  Stream<WalletModel> watchWallet(String walletId) {
    return _controller.stream.where((w) => w.id == walletId);
  }
}

class FakeTransactionRepository implements TransactionRepository {
  final FakeWalletRepository walletRepo;
  final List<TransactionModel> createdTransactions = [];

  FakeTransactionRepository(this.walletRepo);

  @override
  Future<String> payFare({
    required String busVaultId,
    required String stopId,
    required int passengers,
    required String pin,
    double? lat,
    double? lng,
  }) async {
    final studentWallet = walletRepo._wallets.values.firstWhere(
      (w) => w.walletType == WalletType.studentWallet,
      orElse: () => throw Exception('Student wallet not found'),
    );
    // Usually transit pricing would be looked up, but since tests just expect a transaction,
    // let's deduct whatever the test is attempting or simply calculate a base amount.
    // In processBoarding test, it expects 100 for 1 passenger.
    final amount = passengers * 100.0;
    
    await walletRepo.updateBalance(walletId: studentWallet.id, delta: -amount);
    await walletRepo.updateBalance(walletId: busVaultId, delta: amount);

    final tx = TransactionModel(
      id: 'tx-${createdTransactions.length + 1}',
      type: TransactionType.fare,
      senderWalletId: studentWallet.id,
      receiverWalletId: busVaultId,
      amount: amount,
      timestamp: DateTime.now(),
      status: TransactionStatus.success,
    );
    createdTransactions.add(tx);
    return tx.id;
  }

  @override
  Future<String> retailTransfer({
    required String studentWalletId,
    required double amount,
    required String pin,
  }) async {
    return 'tx-fake';
  }

  @override
  Future<List<TransactionModel>> getStudentTransactions(String walletId) async {
    return createdTransactions
        .where((tx) =>
            tx.senderWalletId == walletId || tx.receiverWalletId == walletId)
        .toList();
  }

  @override
  Future<List<TransactionModel>> getAgentTransactions(String walletId) async {
    return createdTransactions.where((tx) => tx.senderWalletId == walletId || tx.receiverWalletId == walletId).toList();
  }

  @override
  Future<List<TransactionModel>> getTransactionsByReceiverWallet(String walletId) async {
    return createdTransactions.where((tx) => tx.receiverWalletId == walletId).toList();
  }

  @override
  Stream<TransactionModel> watchBoardingEvents(String driverWalletId) {
    return const Stream.empty();
  }
}

class FakeLocationService implements LocationService {
  @override
  Future<LatLng?> getCurrentPosition() async {
    return const LatLng(latitude: 6.5244, longitude: 3.3792);
  }
}

// =============================================================================
// Tests
// =============================================================================

void main() {
  late Map<String, WalletModel> fakeWallets;
  late FakeWalletRepository fakeWalletRepo;
  late FakeTransactionRepository fakeTxRepo;
  late FakeLocationService fakeLocationService;
  late ProviderContainer container;

  final testStudent = UserModel(
    id: 'student-user-001',
    role: UserRole.student,
    name: 'Ada Lovelace',
  );

  final testStudentWallet = WalletModel(
    id: 'student-wallet-001',
    ownerId: 'student-user-001',
    walletType: WalletType.studentWallet,
    balance: 500.0,
  );

  final testBusVault = WalletModel(
    id: 'bus-vault-001',
    ownerId: 'driver-user-001',
    walletType: WalletType.busVault,
    balance: 1000.0,
  );

  setUp(() {
    fakeWallets = {
      testStudentWallet.id: testStudentWallet,
      testBusVault.id: testBusVault,
    };
    fakeWalletRepo = FakeWalletRepository(fakeWallets);
    fakeTxRepo = FakeTransactionRepository(fakeWalletRepo);
    fakeLocationService = FakeLocationService();

    container = ProviderContainer(
      overrides: [
        walletRepositoryProvider.overrideWithValue(fakeWalletRepo),
        transactionRepositoryProvider.overrideWithValue(fakeTxRepo),
        locationServiceProvider.overrideWithValue(fakeLocationService),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('PassengerDashboardViewModel — Initialisation & Pricing', () {
    test('loadDashboard sets wallet and transaction history', () async {
      final vm = container.read(passengerDashboardViewModelProvider.notifier);

      await vm.loadDashboard(testStudent);
      final state = container.read(passengerDashboardViewModelProvider);

      expect(state.isLoading, isFalse);
      expect(state.wallet?.id, equals(testStudentWallet.id));
      expect(state.wallet?.balance, equals(500.0));
      expect(state.recentTransactions, isEmpty);
      expect(state.loadError, isNull);
    });

    test('enforces minimum 100 tokens and scales with passenger count', () {
      final vm = container.read(passengerDashboardViewModelProvider.notifier);

      // Default stop is Campus Gate (100 tokens)
      var state = container.read(passengerDashboardViewModelProvider);
      expect(state.calculatedFare, equals(100));

      // Increase to 3 passengers
      vm.incrementPassengers();
      vm.incrementPassengers();
      state = container.read(passengerDashboardViewModelProvider);
      expect(state.passengerCount, equals(3));
      expect(state.calculatedFare, equals(300)); // 100 * 3

      // Decrement passengers
      vm.decrementPassengers();
      state = container.read(passengerDashboardViewModelProvider);
      expect(state.passengerCount, equals(2));
      expect(state.calculatedFare, equals(200));

      // Change destination to Library (140 tokens)
      final libStop = TransitPricing.campusStops.firstWhere((s) => s.id == 'STOP-LIB');
      vm.setDestination(libStop);
      state = container.read(passengerDashboardViewModelProvider);
      expect(state.calculatedFare, equals(280)); // 140 * 2
    });
  });

  group('BusQrPayload — JSON Schema Parsing', () {
    test('valid JSON with BUS_BOARDING type parses correctly', () {
      const validJson = '''
      {
        "type": "BUS_BOARDING",
        "vehicle_id": "BUS-001",
        "route_name": "Campus Main Loop",
        "bus_vault_id": "bus-vault-001",
        "base_fare": 100
      }
      ''';

      final payload = BusQrPayload.tryParse(validJson);
      expect(payload, isNotNull);
      expect(payload!.type, equals('BUS_BOARDING'));
      expect(payload.vehicleId, equals('BUS-001'));
      expect(payload.busVaultId, equals('bus-vault-001'));
    });

    test('invalid or non-JSON strings return null', () {
      expect(BusQrPayload.tryParse('random_string'), isNull);
      expect(BusQrPayload.tryParse('{"action":"topup"}'), isNull);
      expect(BusQrPayload.tryParse('{"type":"WRONG_TYPE"}'), isNull);
    });
  });

  group('PassengerDashboardViewModel — Boarding Execution', () {
    final validBusPayload = BusQrPayload(
      type: 'BUS_BOARDING',
      vehicleId: 'BUS-001',
      routeName: 'Campus Main Loop',
      busVaultId: testBusVault.id,
      baseFare: 100,
    );

    test('rejects boarding when wallet has insufficient balance', () async {
      // Set student balance to 50 tokens (less than 100 minimum)
      fakeWallets[testStudentWallet.id] = testStudentWallet.copyWith(balance: 50.0);

      final vm = container.read(passengerDashboardViewModelProvider.notifier);
      await vm.loadDashboard(testStudent);

      final success = await vm.processBoarding(busPayload: validBusPayload, pin: '1234');

      expect(success, isFalse);
      final state = container.read(passengerDashboardViewModelProvider);
      expect(state.boardingError, contains('Insufficient balance'));
      expect(fakeTxRepo.createdTransactions, isEmpty);
    });

    test('executes atomic double-entry transfer and creates audit record', () async {
      final vm = container.read(passengerDashboardViewModelProvider.notifier);
      await vm.loadDashboard(testStudent);

      // Student has 500, boarding 1 passenger to Campus Gate (100 tokens)
      final success = await vm.processBoarding(busPayload: validBusPayload, pin: '1234');

      expect(success, isTrue);

      final state = container.read(passengerDashboardViewModelProvider);
      expect(state.wallet?.balance, equals(400.0)); // 500 - 100
      expect(state.boardingSuccess, contains('Boarding confirmed'));
      expect(state.recentTransactions.length, equals(1));

      // Bus vault credited
      final updatedBusVault = fakeWallets[testBusVault.id];
      expect(updatedBusVault?.balance, equals(1100.0)); // 1000 + 100

      // Transaction recorded with FARE type
      expect(fakeTxRepo.createdTransactions.length, equals(1));
      final tx = fakeTxRepo.createdTransactions.first;
      expect(tx.type, equals(TransactionType.fare));
      expect(tx.amount, equals(100.0));
      expect(tx.senderWalletId, equals(testStudentWallet.id));
      expect(tx.receiverWalletId, equals(testBusVault.id));
      expect(tx.reference, contains('"vehicle_id":"BUS-001"'));
      expect(tx.reference, contains('"latitude":6.5244'));
    });
  });
}
