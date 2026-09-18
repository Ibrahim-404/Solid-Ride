// Part of solid_principles_demo by Ibrahim Abo El-Haggag

/*
================================================================================
LISKOV SUBSTITUTION PRINCIPLE (LSP) — SOLUTION 2
Feature: Trip Cancellation & Fee Evaluation Invariants (Refactored)
================================================================================

1. WHAT CHANGED STRUCTURALLY:
   We redesigned the contract so that all potential business outcomes (including
   non-cancellable trips) are modeled as first-class return types (`CancellationResult`)
   rather than throwing surprise runtime exceptions:
   - `CancellationResult`: Holds `isPermitted`, `feeAssessed`, and `reasonMessage`.
   - `CancellationPolicy`: Abstract contract guaranteeing that `evaluateCancellation`
     never throws unexpected errors and always satisfies base invariants (non-negative fee).
   - Subtypes like `GovSubsidizedCancellationPolicy` honor the contract by returning
     a disallowed result rather than crashing the thread.

2. WHY THIS FIXES THE EXACT PROBLEM FROM PROBLEM 2:
   - Any subclass of `CancellationPolicy` can safely replace another without the caller
     needing `try/catch` or defensive type checks.
   - Preconditions are not strengthened; postconditions (valid result, non-negative fee)
     are strictly preserved by all subtypes.
   - The UI bottom sheet handles non-cancellable trips gracefully with friendly messaging.

3. WHY THIS IS PROPORTIONATE (NOT OVER-ENGINEERING):
   Cancellations directly impact platform customer service and financial disputes.
   Replacing unexpected runtime crashes with explicit domain evaluation results
   creates robust, crash-free mobile flows.
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

/// Explicit domain result preserving invariants across all subtypes.
class CancellationResult {
  final bool isPermitted;
  final double feeCharged;
  final String explanation;

  const CancellationResult({
    required this.isPermitted,
    required this.feeCharged,
    required this.explanation,
  });

  factory CancellationResult.allowed({required double fee, required String explanation}) {
    return CancellationResult(
      isPermitted: true,
      feeCharged: fee < 0 ? 0.0 : fee, // Invariant: Fee must never be negative
      explanation: explanation,
    );
  }

  factory CancellationResult.denied({required String reason}) {
    return CancellationResult(
      isPermitted: false,
      feeCharged: 0.0,
      explanation: reason,
    );
  }
}

/// Base contract adhering to LSP: guaranteed safe execution for all subtypes.
abstract class CancellationPolicy {
  String get policyName;
  CancellationResult evaluateCancellation(TripOrder trip, int minutesElapsed);
}

/// Subtype 1: Standard ride cancellation
class StandardCancellationPolicy implements CancellationPolicy {
  @override
  String get policyName => 'Standard Trip Policy';

  @override
  CancellationResult evaluateCancellation(TripOrder trip, int minutesElapsed) {
    if (minutesElapsed <= 2) {
      return CancellationResult.allowed(
        fee: 0.0,
        explanation: 'Cancelled within 2-minute free grace period.',
      );
    }
    const standardFee = 5.00;
    return CancellationResult.allowed(
      fee: standardFee,
      explanation: 'Cancellation fee applied after grace period elapsed.',
    );
  }
}

/// Subtype 2: Government subsidized ride (Substitute without crashing!)
class GovSubsidizedCancellationPolicy implements CancellationPolicy {
  @override
  String get policyName => 'Government Subsidized Policy';

  @override
  CancellationResult evaluateCancellation(TripOrder trip, int minutesElapsed) {
    // Honors contract: returns structured result instead of crashing caller!
    return CancellationResult.denied(
      reason: 'Government subsidized rides cannot be self-cancelled via app. Please contact dispatch support.',
    );
  }
}

/// Subtype 3: Airport Terminal Pickup (Substitute without crashing!)
class AirportPickupCancellationPolicy implements CancellationPolicy {
  @override
  String get policyName => 'Airport Staging Queue Policy';

  @override
  CancellationResult evaluateCancellation(TripOrder trip, int minutesElapsed) {
    // Incur airport queue compensation fee after 3 minutes
    final fee = minutesElapsed > 3 ? 10.0 : 0.0;
    return CancellationResult.allowed(
      fee: fee,
      explanation: fee > 0
          ? 'Airport priority staging compensation fee applied.'
          : 'Cancelled within free airport dispatch window.',
    );
  }
}

/// Cancellation coordinator that safely works with ANY CancellationPolicy subtype!
class SafeCancellationCoordinator {
  final CancellationPolicy _policy;

  SafeCancellationCoordinator(this._policy);

  void processCancellation(TripOrder trip, int minutesElapsed) {
    print('[Coordinator] Evaluating with policy: ${_policy.policyName} for trip ${trip.tripId}');
    final result = _policy.evaluateCancellation(trip, minutesElapsed);

    if (result.isPermitted) {
      print('[Coordinator] Cancellation APPROVED. Fee: \$${result.feeCharged.toStringAsFixed(2)}. Note: ${result.explanation}');
    } else {
      print('[Coordinator] Cancellation REJECTED. Reason: ${result.explanation}');
    }
  }
}
