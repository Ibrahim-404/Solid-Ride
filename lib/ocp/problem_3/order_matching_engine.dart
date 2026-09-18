// Part of solid_principles_demo by Ibrahim Abo El-Haggag

/*
================================================================================
OPEN/CLOSED PRINCIPLE (OCP) — PROBLEM 3
Feature: Order / Trip Dispatch Matching Eligibility Rules
================================================================================

1. WHAT THIS CODE DOES:
   When an incoming ride or delivery order arrives, the dispatch system verifies
   whether a nearby driver is eligible to receive the offer. The method checks
   several criteria: whether the driver can handle Cash-on-Delivery (COD), whether
   their driver rating is high enough, whether their vehicle can handle the order's
   package weight, and whether they have high-value parcel insurance.

   EXECUTION FLOW (CHAINED IF-ELSE):
   Incoming order offer
           ↓
   [OrderMatchingEngine]
      ├── if (!driver.hasCash && order.isCash) return false;
      ├── if (driver.rating < order.minRating) return false;
      ├── if (order.weight > driver.maxWeight) return false;
      └── if (order.isHighValue && !driver.insured) return false;
   (Adding Low Emission Zone rule = Bloating engine method!)

2. WHY IT LOOKS FINE AT FIRST GLANCE:
   It's a straightforward series of `if` statements. Any developer can read the
   eligibility criteria in order from top to bottom.

3. WHAT SPECIFIC PROBLEM IT CAUSES AS CODE GROWS:
   - When Operations introduces "VIP Courier Only" orders, or City Authorities mandate
     "Electric Vehicle Low-Emission Zone" checks, or Marketing introduces "Pet-friendly
     ride" options, this existing method must be opened and edited.
   - Chained conditional statements grow into unmaintainable, 200-line "god methods".
   - Testing an individual rule in isolation is impossible without setting up fake driver
     profiles that pass or fail all surrounding `if` conditions.
   - Different dispatch teams (e.g. food delivery vs courier vs luxury rides) keep editing
     the same dispatch file.

4. WHICH SOLID PRINCIPLE IT VIOLATES & WHY:
   Violates the Open/Closed Principle (OCP).
   `OrderMatchingEngine` is NOT closed for modification. Every new operational constraint
   or municipal regulation forces edits directly into the engine's core evaluation logic.
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

class OrderMatchingEngine {
  bool isDriverEligible(DriverProfile driver, DeliveryOrder order) {
    print('[MatchingEngine] Checking eligibility for driver ${driver.driverId} on order ${order.orderId}');

    // VIOLATION: Hardcoded chained conditions. Adding new rules requires editing this method.
    // 1. Cash on delivery check
    if (order.isCashOnDelivery && !driver.hasCashCollectionEnabled) {
      print('[MatchingEngine] REJECTED: Driver does not support Cash-on-Delivery.');
      return false;
    }

    // 2. Rating threshold check
    if (driver.rating < order.minRatingRequired) {
      print('[MatchingEngine] REJECTED: Driver rating (${driver.rating}) below requirement (${order.minRatingRequired}).');
      return false;
    }

    // 3. Weight capacity check
    if (order.packageWeightKg > driver.maxPayloadCapacityKg) {
      print('[MatchingEngine] REJECTED: Package weight (${order.packageWeightKg}kg) exceeds vehicle capacity (${driver.maxPayloadCapacityKg}kg).');
      return false;
    }

    // 4. High-value parcel insurance check
    if (order.isHighValue && !driver.isInsuredForHighValue) {
      print('[MatchingEngine] REJECTED: Driver lacks high-value cargo insurance.');
      return false;
    }

    print('[MatchingEngine] APPROVED: Driver is eligible for dispatch.');
    return true;
  }
}
