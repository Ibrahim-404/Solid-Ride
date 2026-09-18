// Part of solid_principles_demo by Ibrahim Abo El-Haggag

/*
================================================================================
OPEN/CLOSED PRINCIPLE (OCP) — SOLUTION 3
Feature: Order / Trip Dispatch Matching Eligibility Rules (Refactored via Rules)
================================================================================

1. WHAT CHANGED STRUCTURALLY:
   Instead of a single class packed with hardcoded `if` statements, we introduced
   the Specification / Rule Pattern:
   - `OrderMatchingRule`: An abstract contract for any eligibility condition.
   - Individual rule implementations: `CashOnDeliveryRule`, `RatingThresholdRule`,
     `WeightCapacityRule`, `HighValueInsuranceRule`, and a newly added `LowEmissionZoneRule`.
   - `OrderMatchingPipeline`: A generic engine that loops through registered rules.

2. WHY THIS FIXES THE EXACT PROBLEM FROM PROBLEM 3:
   - Adding a new business rule (e.g. `LowEmissionZoneRule`) requires creating ONLY a new
     class implementing `OrderMatchingRule`.
   - The evaluation engine is 100% closed for modification.
   - Each business rule can be unit-tested in complete isolation with simple inputs.
   - Different dispatch hubs can compose customized rule sets dynamically (e.g. food delivery
     hub vs luxury passenger hub) without altering any core dispatch code.

3. WHY THIS IS PROPORTIONATE (NOT OVER-ENGINEERING):
   Dispatch eligibility rules in ride-hailing/delivery change constantly due to local municipal
   regulations, seasonal campaigns, and safety policies. A rule-based pipeline makes adding or
   reordering constraints frictionless and immune to regressions.
================================================================================
*/

class DriverProfile {
  final String driverId;
  final double rating;
  final bool hasCashCollectionEnabled;
  final double maxPayloadCapacityKg;
  final bool isInsuredForHighValue;
  final bool isElectricVehicle;

  const DriverProfile({
    required this.driverId,
    required this.rating,
    required this.hasCashCollectionEnabled,
    required this.maxPayloadCapacityKg,
    required this.isInsuredForHighValue,
    this.isElectricVehicle = false,
  });
}

class DeliveryOrder {
  final String orderId;
  final bool isCashOnDelivery;
  final double minRatingRequired;
  final double packageWeightKg;
  final bool isHighValue;
  final bool requiresLowEmissionVehicle;

  const DeliveryOrder({
    required this.orderId,
    required this.isCashOnDelivery,
    required this.minRatingRequired,
    required this.packageWeightKg,
    required this.isHighValue,
    this.requiresLowEmissionVehicle = false,
  });
}

/// Abstract rule contract open for extension, closed for modification.
abstract class OrderMatchingRule {
  String get ruleName;
  bool isSatisfiedBy(DriverProfile driver, DeliveryOrder order);
  String failureReason(DriverProfile driver, DeliveryOrder order);
}

/// Rule 1: Cash on Delivery verification
class CashOnDeliveryRule implements OrderMatchingRule {
  @override
  String get ruleName => 'Cash on Delivery Support';

  @override
  bool isSatisfiedBy(DriverProfile driver, DeliveryOrder order) {
    if (!order.isCashOnDelivery) return true;
    return driver.hasCashCollectionEnabled;
  }

  @override
  String failureReason(DriverProfile driver, DeliveryOrder order) =>
      'Driver does not have cash collection enabled.';
}

/// Rule 2: Minimum driver rating threshold
class RatingThresholdRule implements OrderMatchingRule {
  @override
  String get ruleName => 'Driver Rating Requirement';

  @override
  bool isSatisfiedBy(DriverProfile driver, DeliveryOrder order) =>
      driver.rating >= order.minRatingRequired;

  @override
  String failureReason(DriverProfile driver, DeliveryOrder order) =>
      'Driver rating (${driver.rating}) is below order minimum (${order.minRatingRequired}).';
}

/// Rule 3: Vehicle cargo weight capacity
class WeightCapacityRule implements OrderMatchingRule {
  @override
  String get ruleName => 'Cargo Weight Capacity';

  @override
  bool isSatisfiedBy(DriverProfile driver, DeliveryOrder order) =>
      driver.maxPayloadCapacityKg >= order.packageWeightKg;

  @override
  String failureReason(DriverProfile driver, DeliveryOrder order) =>
      'Package weight (${order.packageWeightKg}kg) exceeds vehicle capacity (${driver.maxPayloadCapacityKg}kg).';
}

/// Rule 4: High-value parcel insurance check
class HighValueInsuranceRule implements OrderMatchingRule {
  @override
  String get ruleName => 'High-Value Parcel Insurance';

  @override
  bool isSatisfiedBy(DriverProfile driver, DeliveryOrder order) {
    if (!order.isHighValue) return true;
    return driver.isInsuredForHighValue;
  }

  @override
  String failureReason(DriverProfile driver, DeliveryOrder order) =>
      'Order requires high-value insurance, which driver lacks.';
}

/// Rule 5: Extension added WITHOUT modifying the matching engine!
class LowEmissionZoneRule implements OrderMatchingRule {
  @override
  String get ruleName => 'Low Emission Zone Compliance';

  @override
  bool isSatisfiedBy(DriverProfile driver, DeliveryOrder order) {
    if (!order.requiresLowEmissionVehicle) return true;
    return driver.isElectricVehicle;
  }

  @override
  String failureReason(DriverProfile driver, DeliveryOrder order) =>
      'Destination is in a green zone and requires an Electric Vehicle.';
}

/// Matching Pipeline engine — completely CLOSED for modification.
class OrderMatchingPipeline {
  final List<OrderMatchingRule> _rules;

  const OrderMatchingPipeline(this._rules);

  bool evaluateDriver({
    required DriverProfile driver,
    required DeliveryOrder order,
  }) {
    print('[Pipeline] Evaluating ${driver.driverId} against ${_rules.length} dispatch rules for order ${order.orderId}...');

    for (final rule in _rules) {
      if (!rule.isSatisfiedBy(driver, order)) {
        print('[Pipeline] REJECTED by [${rule.ruleName}]: ${rule.failureReason(driver, order)}');
        return false;
      }
    }

    print('[Pipeline] APPROVED: Driver ${driver.driverId} satisfied all dispatch constraints.');
    return true;
  }
}
