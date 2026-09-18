// Part of solid_principles_demo by Ibrahim Abo El-Haggag

/*
================================================================================
LISKOV SUBSTITUTION PRINCIPLE (LSP) — PROBLEM 2
Feature: Trip Cancellation & Fee Evaluation Invariants
================================================================================

1. WHAT THIS CODE DOES:
   When a rider or driver taps "Cancel Trip", the system evaluates the applicable
   cancellation penalty fee. Under standard policy, cancellations within 2 minutes of
   dispatch are free, while later cancellations incur a flat fee (e.g. $5.00) to
   compensate the driver's fuel and time.

   EXECUTION FLOW (CONTRACT VIOLATION):
   Rider / Driver cancels trip
           ↓
   [CancellationCoordinator]
           ↓
   policy.calculateCancellationFee()
      ├── StandardPolicy ──> Returns \$5.00
      └── GovPromoPolicy ──> CRASH! Throws StateError
   (Subtype strengthens preconditions & crashes callers unexpectedly!)

2. WHY IT LOOKS FINE AT FIRST GLANCE:
   The base class `CancellationPolicy` provides a clean virtual method:
   `double calculateCancellationFee(TripOrder trip, int minutesElapsed)`.
   Subclassing it for different trip promotional campaigns feels like standard OOP.

3. WHAT SPECIFIC PROBLEM IT CAUSES AS CODE GROWS:
   - A mid-level developer creates `NonCancellableGovPromoPolicy` for government-subsidized
     rides. Instead of returning a fee, this subclass throws an unexpected exception:
     `throw StateError('Promotional subsidized trips cannot be cancelled by policy!')`.
   - Another developer creates `StrictAirportPolicy` which returns negative numbers (`-25.0`)
     or mutates driver penalty points directly inside what is supposed to be a read-only query.
   - The UI cancellation sheet crashes with unhandled exceptions, stranding the driver and
     rider in an un-cancellable state.
   - The caller cannot safely treat all `CancellationPolicy` instances interchangeably.

4. WHICH SOLID PRINCIPLE IT VIOLATES & WHY:
   Violates the Liskov Substitution Principle (LSP): Subtypes must preserve the behavioral
   contracts, invariants, and pre/post-conditions established by the base class.
   `NonCancellableGovPromoPolicy` strengthens preconditions and throws unexpected exceptions
   not declared or anticipated by callers of the base contract.
================================================================================
*/

class TripOrder {
  final String tripId;
  final double baseFare;
  final String driverId;
  final String riderId;

  const TripOrder({
    required this.tripId,
    required this.baseFare,
    required this.driverId,
    required this.riderId,
  });
}

/// Base contract: Expected to return a valid non-negative cancellation fee.
abstract class CancellationPolicy {
  /// Base contract postcondition: returns non-negative fee >= 0.0 and <= trip.baseFare.
  /// Precondition: valid trip and non-negative elapsed minutes.
  double calculateCancellationFee(TripOrder trip, int minutesElapsed);
}

/// Standard ride cancellation: Follows the base contract.
class StandardRideCancellationPolicy extends CancellationPolicy {
  @override
  double calculateCancellationFee(TripOrder trip, int minutesElapsed) {
    if (minutesElapsed <= 2) {
      print('[StandardPolicy] Cancelled within grace period (2 mins). Fee: \$0.00');
      return 0.0;
    }
    const standardFee = 5.00;
    print('[StandardPolicy] Cancellation fee assessed: \$$standardFee');
    return standardFee;
  }
}

/// VIOLATION: Subtype strengthens preconditions and throws unexpected runtime exceptions!
class NonCancellableGovPromoPolicy extends CancellationPolicy {
  @override
  double calculateCancellationFee(TripOrder trip, int minutesElapsed) {
    // VIOLATION OF LSP: The base class guarantees fee calculation, but this subtype
    // crashes the program with an unhandled exception!
    throw StateError('Promotional subsidized trip ${trip.tripId} CANNOT be cancelled! Contact support.');
  }
}

/// Cancellation coordinator that breaks when LSP is violated.
class CancellationCoordinator {
  final CancellationPolicy _policy;

  CancellationCoordinator(this._policy);

  void handleCancellationRequest(TripOrder trip, int minutesElapsed) {
    print('[Coordinator] Evaluating cancellation fee for trip ${trip.tripId}...');
    // CRASH! If _policy is NonCancellableGovPromoPolicy, this throws StateError!
    final fee = _policy.calculateCancellationFee(trip, minutesElapsed);
    print('[Coordinator] Final cancellation fee charged to rider: \$${fee.toStringAsFixed(2)}');
  }
}
