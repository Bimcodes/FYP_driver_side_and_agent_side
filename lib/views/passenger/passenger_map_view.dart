import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/app_colors.dart';
import '../../viewmodels/passenger_map_viewmodel.dart';

class PassengerMapView extends ConsumerWidget {
  const PassengerMapView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeBusesAsync = ref.watch(activeBusesProvider);

    return Scaffold(
      backgroundColor: AppColors.agentLightBackground,
      appBar: AppBar(
        title: const Text('Campus Live Map'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.agentTextDark,
        elevation: 0,
      ),
      body: activeBusesAsync.when(
        data: (buses) {
          return FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(6.5244, 3.3792), // Default center (Lagos)
              initialZoom: 14.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
              ),
              MarkerLayer(
                markers: buses.map((bus) {
                  return Marker(
                    point: LatLng(bus.latitude, bus.longitude),
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.directions_bus,
                      color: AppColors.agentPrimary,
                      size: 40,
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.agentPrimary)),
        error: (err, stack) => Center(child: Text('Error loading map: $err')),
      ),
    );
  }
}
