// Part of solid_principles_demo by Ibrahim Abo El-Haggag

/*
================================================================================
OPEN/CLOSED PRINCIPLE (OCP) — PROBLEM 2
Feature: Vehicle Type Fare & Surge Calculation
================================================================================

1. WHAT THIS CODE DOES:
   In a ride-hailing and courier fleet, fare pricing differs based on the vehicle
   tier: Economy Car, Comfort/Sedan, Motorcycle Delivery, and Cargo Van. This class
   takes trip distance (km), duration (minutes), and surge multiplier, checks the
   vehicle type via conditional branching, and computes the gross trip fare.

2. WHY IT LOOKS FINE AT FIRST GLANCE:
   Having all pricing rules visible in a single method seems convenient for comparing
   fares across different vehicle classes side-by-side.

3. WHAT SPECIFIC PROBLEM IT CAUSES AS CODE GROWS:
   - When operations introduces "Electric Scooter Courier" or "Heavy Furniture Truck",
     a developer must open this existing `FareCalculator` and add another `case`.
   - Modifying this class to adjust motorcycle pricing risks accidentally modifying
     or introducing a syntax/logic bug into the passenger Comfort car pricing.
   - The file constantly churns with Git changes from different fleet managers.
   - Unit tests must repeatedly re-test all vehicle categories whenever any single
     tier is modified or added.

4. WHICH SOLID PRINCIPLE IT VIOLATES & WHY:
   Violates the Open/Closed Principle (OCP): "Open for extension, closed for modification."
   `FareCalculator` must be continuously modified every time a new vehicle category
   or service type is launched on the platform.
================================================================================
*/

enum VehicleCategory {
  economy,
  comfort,
  motorcycleDelivery,
  cargoVan,
}

class TripFareCalculator {
  double calculateFare({
    required VehicleCategory vehicleCategory,
    required double distanceKm,
    required int durationMinutes,
    double surgeMultiplier = 1.0,
  }) {
    print('[FareCalculator] Calculating fare for category: $vehicleCategory');

    // VIOLATION: Hardcoded branching for vehicle pricing rules
    switch (vehicleCategory) {
      case VehicleCategory.economy:
        // Base: $2.50, $0.80/km, $0.20/min, min fare: $5.00
        final raw = 2.50 + (distanceKm * 0.80) + (durationMinutes * 0.20);
        final surged = raw * surgeMultiplier;
        return surged < 5.0 ? 5.0 : surged;

      case VehicleCategory.comfort:
        // Base: $4.00, $1.25/km, $0.35/min, min fare: $8.00
        final raw = 4.00 + (distanceKm * 1.25) + (durationMinutes * 0.35);
        final surged = raw * surgeMultiplier;
        return surged < 8.0 ? 8.0 : surged;

      case VehicleCategory.motorcycleDelivery:
        // Base: $1.50, $0.50/km, $0.10/min, min fare: $3.00
        final raw = 1.50 + (distanceKm * 0.50) + (durationMinutes * 0.10);
        final surged = raw * surgeMultiplier;
        return surged < 3.0 ? 3.0 : surged;

      case VehicleCategory.cargoVan:
        // Base: $10.00, $2.00/km, $0.50/min, min fare: $20.00
        final raw = 10.00 + (distanceKm * 2.00) + (durationMinutes * 0.50);
        final surged = raw * surgeMultiplier;
        return surged < 20.0 ? 20.0 : surged;
    }
  }
}
