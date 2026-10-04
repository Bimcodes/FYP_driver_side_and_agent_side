// =============================================================================
// FILE: core/constants/transit_pricing.dart
// LAYER: Core / Constants
//
// PURPOSE:
//   Predefined campus transit stops and distance-based fare chart.
//   Enforces a minimum boarding fare of 100 tokens as specified.
// =============================================================================

/// Represents an authorized campus transit stop and its base fare.
class TransitStop {
  final String id;
  final String name;
  final int fareTokens;
  final String description;

  const TransitStop({
    required this.id,
    required this.name,
    required this.fareTokens,
    required this.description,
  });
}

/// Campus transit pricing and destination definitions.
class TransitPricing {
  TransitPricing._();

  /// The absolute minimum fare allowed per passenger.
  static const int minFareTokens = 100;

  /// Default campus transit stops and their stage fares.
  static const List<TransitStop> campusStops = [
    TransitStop(
      id: 'STOP-GATE',
      name: 'Campus Main Gate',
      fareTokens: 100,
      description: 'Main Entrance & Security Hub',
    ),
    TransitStop(
      id: 'STOP-ADMIN',
      name: 'Senate & Student Affairs',
      fareTokens: 200,
      description: 'Administrative Complex',
    ),
    TransitStop(
      id: 'STOP-FACULTY',
      name: 'Faculty of Science & Tech',
      fareTokens: 200,
      description: 'Lecture Theatres 1-8 & Labs',
    ),
    TransitStop(
      id: 'STOP-LIB',
      name: 'University Central Library',
      fareTokens: 100,
      description: 'Study Centre & IT Complex',
    ),
    TransitStop(
      id: 'STOP-SPORTS',
      name: 'Sports Complex & Clinic',
      fareTokens: 100,
      description: 'Stadium, Gymnasium, Health Centre',
    ),
    TransitStop(
      id: 'STOP-HOSTEL',
      name: 'Student Hostels (Halls 1-6)',
      fareTokens: 200,
      description: 'Residential Quad & Dining',
    ),
    TransitStop(
      id: 'STOP-PG',
      name: 'Postgraduate Village',
      fareTokens: 200,
      description: 'PG Quarters & Research Wing',
    ),
  ];

  /// Calculates total tokens required for [passengerCount] people to [stop].
  /// Enforces at least [minFareTokens] per passenger.
  static int calculateTotalFare({
    required TransitStop stop,
    required int passengerCount,
  }) {
    final count = passengerCount < 1 ? 1 : passengerCount;
    final perPerson = stop.fareTokens < minFareTokens ? minFareTokens : stop.fareTokens;
    return perPerson * count;
  }
}
