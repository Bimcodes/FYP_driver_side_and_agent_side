import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/telemetry_model.dart';
import '../../repositories/telemetry_repository.dart';

final activeBusesProvider = AutoDisposeAsyncNotifierProvider<ActiveBusesNotifier, List<TelemetryModel>>(
  ActiveBusesNotifier.new,
);

class ActiveBusesNotifier extends AutoDisposeAsyncNotifier<List<TelemetryModel>> {
  Timer? _timer;

  @override
  Future<List<TelemetryModel>> build() async {
    ref.onDispose(() => _timer?.cancel());
    
    // Poll every 10 seconds
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      ref.invalidateSelf();
    });

    return _fetchBuses();
  }

  Future<List<TelemetryModel>> _fetchBuses() async {
    final repo = ref.read(telemetryRepositoryProvider);
    final allTelemetry = await repo.getActiveBuses();

    // Group by driver_id and get the latest
    final Map<String, TelemetryModel> latest = {};
    for (final t in allTelemetry) {
      if (!latest.containsKey(t.driverId)) {
        latest[t.driverId] = t;
      } else {
        if (t.timestamp.isAfter(latest[t.driverId]!.timestamp)) {
          latest[t.driverId] = t;
        }
      }
    }

    return latest.values.toList();
  }
}
