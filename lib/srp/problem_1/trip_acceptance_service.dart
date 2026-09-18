// Part of solid_principles_demo by Ibrahim Abo El-Haggag

/*
================================================================================
SINGLE RESPONSIBILITY PRINCIPLE (SRP) — PROBLEM 1
Feature: Trip Dispatch & Driver Order Acceptance (Ride-Hailing / Delivery)
================================================================================

1. WHAT THIS CODE DOES:
   When a ride-hailing driver (e.g. Uber/Careem) taps "Accept Order" on their
   screen, this class processes the acceptance: it updates the trip status in the
   local SQLite database, sends an HTTP request to the dispatch backend, calculates
   the driver's dynamic surge payout and platform commission, emits an analytics event

   EXECUTION FLOW (MONOLITHIC):
   Driver presses "Accept"
           ↓
   [TripAcceptanceService] (One Monolithic Class)
      ├── 1. SQLite: Saves trip state
      ├── 2. HTTP POST: Notifies backend dispatch
      ├── 3. Math: Calculates surge & commission
      ├── 4. Analytics: Logs Firebase event
      └── 5. Hardware: Plays chime & triggers haptic
   (5 reasons to change - fragile, coupled, and error-prone!)

2. WHY IT LOOKS FINE AT FIRST GLANCE:
   It keeps everything related to "accepting a trip" in one convenient place. Any
   developer looking for what happens when a driver taps "Accept" can open this single
   file, read `acceptTrip()`, and see the entire flow from top to bottom.

3. WHAT SPECIFIC PROBLEM IT CAUSES AS CODE GROWS:
   In real production, business logic and infrastructure evolve at different speeds:
   - If Finance changes how surge commission is calculated (e.g. Ramadan surge bonus),
     you must modify this class.
   - If the Product team switches analytics from Firebase to Mixpanel, you must modify
     this class.
   - If the Mobile UX team changes the audio chime mechanism or adds custom vibration patterns,
     you must modify this class.
   - If QA wants to test payout calculation, they cannot do so without triggering database
     inserts and network calls.
   A single high-frequency dispatch feature becomes a fragile, conflict-prone bottleneck
   where multiple developers step on each other's toes.

4. WHICH SOLID PRINCIPLE IT VIOLATES & WHY:
   Violates the Single Responsibility Principle (SRP): "A class should have one, and
   only one, reason to change."
   `TripAcceptanceService` currently has at least FIVE reasons to change:
   (1) Database schema/storage changes,
   (2) Backend API protocol changes,
   (3) Financial payout / commission calculations,
   (4) Analytics and telemetry instrumentation,
   (5) UI/Hardware alerts (audio & haptics).
================================================================================
*/

import 'dart:convert';

/// Represents a ride or delivery trip offered to a driver.
class DriverTrip {
  final String tripId;
  final String passengerName;
  final String pickupAddress;
  final String destinationAddress;
  final double baseFare;
  final double surgeMultiplier;
  final bool isCompleted;

  const DriverTrip({
    required this.tripId,
    required this.passengerName,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.baseFare,
    this.surgeMultiplier = 1.0,
    this.isCompleted = false,
  });
}

/// A monolithic service violating SRP by handling persistence, networking,
/// financial math, analytics, and device sound/vibration alerts all in one.
class TripAcceptanceService {
  // 1. Storage responsibility (simulated local DB cache)
  final Map<String, String> _localDb = {};

  // 2. Network responsibility
  Future<void> acceptTrip(DriverTrip trip, String driverId) async {
    // A. Update local storage state
    _localDb[trip.tripId] = 'ACCEPTED_BY_$driverId';
    print('[DB] Saved trip ${trip.tripId} as ACCEPTED in local cache.');

    // B. Send network request to dispatch backend
    final payload = jsonEncode({
      'trip_id': trip.tripId,
      'driver_id': driverId,
      'status': 'CONFIRMED',
      'timestamp': DateTime.now().toIso8601String(),
    });
    // In real app: await http.post(Uri.parse('https://api.ride.com/v1/dispatch/accept'), body: payload);
    print('[Network] POST /v1/dispatch/accept with payload: $payload');

    // C. Business Rule: Payout & Commission Calculation
    final grossFare = trip.baseFare * trip.surgeMultiplier;
    const platformCommissionRate = 0.20; // 20% platform cut
    final driverEarnings = grossFare * (1.0 - platformCommissionRate);
    print('[Finance] Calculated Driver Net Payout: \$${driverEarnings.toStringAsFixed(2)} '
        '(Gross: \$${grossFare.toStringAsFixed(2)}, Commission: 20%)');

    // D. Telemetry & Analytics
    // In real app: FirebaseAnalytics.instance.logEvent(...)
    print('[Analytics] Logged event "driver_trip_accepted" for driver: $driverId, surge: ${trip.surgeMultiplier}x');

    // E. Hardware & Device Alerts (Audio Chime / Haptic)
    // In real app: HapticFeedback.heavyImpact(); AudioPlayer().play('sounds/trip_accepted.mp3');
    print('[Device] Playing trip_accepted.mp3 audio chime and heavy haptic feedback.');
  }
}
