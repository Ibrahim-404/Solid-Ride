// Part of solid_principles_demo by Ibrahim Abo El-Haggag

/*
================================================================================
SINGLE RESPONSIBILITY PRINCIPLE (SRP) — SOLUTION 1
Feature: Trip Dispatch & Driver Order Acceptance (Refactored)
================================================================================

1. WHAT CHANGED STRUCTURALLY:
   The monolithic `TripAcceptanceService` was decomposed into distinct, single-purpose
   collaborators following Clean Architecture:
   - `TripRepository`: Responsible ONLY for remote API communication and local persistence.
   - `TripPayoutCalculator`: Responsible ONLY for the domain financial math (surge & commission).
   - `TripAnalyticsTracker`: Responsible ONLY for event telemetry.
   - `TripAlertService`: Responsible ONLY for physical device feedback (chime & vibration).
   - `AcceptTripUseCase`: A lightweight orchestrator that coordinates these steps.

   REFACTORED CLEAN FLOW:
   Driver presses "Accept"
           ↓
   [AcceptTripUseCase] (Orchestrator)
      ├── 1. [TripPayoutCalculator] ──> Calculates net payout
      ├── 2. [TripRepository]       ──> SQLite + Backend API
      ├── 3. [TripAnalyticsTracker] ──> Emits analytics event
      └── 4. [TripAlertService]     ──> Plays sound & haptics
   (Each collaborator has exactly ONE reason to change)

2. WHY THIS FIXES THE EXACT PROBLEM FROM PROBLEM 1:
   - If Finance changes commission formulas, we ONLY touch `TripPayoutCalculator`. Zero risk of
     breaking network requests or local database caching.
   - If Analytics switches to Mixpanel or Datadog, we ONLY touch `TripAnalyticsTracker`.
   - If UX alters audio/haptic behavior, we ONLY touch `TripAlertService`.
   - Unit testing `TripPayoutCalculator` is now a pure Dart test requiring zero mocks or network setups.

3. WHY THIS IS PROPORTIONATE (NOT OVER-ENGINEERING):
   In ride-hailing apps, trip acceptance is the single most critical, high-volume flow. Having
   clear boundaries between hardware alerts, financial calculations, and network calls prevents
   million-dollar calculation bugs and keeps merge conflicts to near zero during team sprints.
================================================================================
*/

/// Domain entity representing a ride-hailing or delivery trip.
class DriverTrip {
  final String tripId;
  final String passengerName;
  final String pickupAddress;
  final String destinationAddress;
  final double baseFare;
  final double surgeMultiplier;

  const DriverTrip({
    required this.tripId,
    required this.passengerName,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.baseFare,
    this.surgeMultiplier = 1.0,
  });
}

/// Data class representing calculated financial breakdown for driver earnings.
class TripPayoutSummary {
  final double grossFare;
  final double platformCommission;
  final double netDriverEarnings;

  const TripPayoutSummary({
    required this.grossFare,
    required this.platformCommission,
    required this.netDriverEarnings,
  });
}

/// Responsibility 1: Pure financial calculations.
class TripPayoutCalculator {
  static const double defaultPlatformCommissionRate = 0.20; // 20% cut

  TripPayoutSummary calculatePayout(
    DriverTrip trip, {
    double commissionRate = defaultPlatformCommissionRate,
  }) {
    final gross = trip.baseFare * trip.surgeMultiplier;
    final commission = gross * commissionRate;
    final net = gross - commission;
    return TripPayoutSummary(
      grossFare: gross,
      platformCommission: commission,
      netDriverEarnings: net,
    );
  }
}

/// Responsibility 2: Data persistence and backend communication.
class TripRepository {
  final Map<String, String> _localDb = {};

  Future<void> confirmTripAcceptance({
    required String tripId,
    required String driverId,
  }) async {
    _localDb[tripId] = 'ACCEPTED_BY_$driverId';
    print('[Repository] Trip $tripId persisted locally.');
    // Simulated network call
    print('[Repository] Remote API confirmed acceptance for trip $tripId by driver $driverId.');
  }
}

/// Responsibility 3: Event tracking and analytics telemetry.
class TripAnalyticsTracker {
  void trackTripAccepted({
    required String driverId,
    required String tripId,
    required double surgeMultiplier,
  }) {
    print('[Analytics] Logged "trip_accepted" (trip: $tripId, driver: $driverId, surge: ${surgeMultiplier}x)');
  }
}

/// Responsibility 4: Device hardware alerts (audio, vibration, screen wake).
class TripAlertService {
  void triggerAcceptanceFeedback() {
    print('[Device Alerts] Triggered success audio chime & haptic feedback.');
  }
}

/// Orchestrator Use Case: coordinates the acceptance workflow with single responsibility per dependency.
class AcceptTripUseCase {
  final TripRepository _repository;
  final TripPayoutCalculator _calculator;
  final TripAnalyticsTracker _analytics;
  final TripAlertService _alertService;

  AcceptTripUseCase({
    required TripRepository repository,
    required TripPayoutCalculator calculator,
    required TripAnalyticsTracker analytics,
    required TripAlertService alertService,
  })  : _repository = repository,
        _calculator = calculator,
        _analytics = analytics,
        _alertService = alertService;

  Future<TripPayoutSummary> execute({
    required DriverTrip trip,
    required String driverId,
  }) async {
    // 1. Calculate payout
    final payout = _calculator.calculatePayout(trip);
    print('[UseCase] Calculated net earnings: \$${payout.netDriverEarnings.toStringAsFixed(2)}');

    // 2. Persist & sync with backend
    await _repository.confirmTripAcceptance(tripId: trip.tripId, driverId: driverId);

    // 3. Track analytics
    _analytics.trackTripAccepted(
      driverId: driverId,
      tripId: trip.tripId,
      surgeMultiplier: trip.surgeMultiplier,
    );

    // 4. Alert driver hardware
    _alertService.triggerAcceptanceFeedback();

    return payout;
  }
}
