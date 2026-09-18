// Part of solid_principles_demo by Ibrahim Abo El-Haggag

/*
================================================================================
OPEN/CLOSED PRINCIPLE (OCP) — SOLUTION 2
Feature: Vehicle Type Fare & Surge Calculation (Refactored via Strategy)
================================================================================

1. WHAT CHANGED STRUCTURALLY:
   We replaced the conditional branching with the Strategy Pattern:
   - `VehicleFareStrategy`: An interface defining the pricing calculation contract.
   - Separate strategy classes (`EconomyFareStrategy`, `ComfortFareStrategy`,
     `MotorcycleFareStrategy`, `CargoVanFareStrategy`) encapsulating each vehicle's
     specific pricing formulas and minimum fare constraints.
   - `FareCalculationService`: Closed for modification, it simply executes whichever
     strategy is provided.

2. WHY THIS FIXES THE EXACT PROBLEM FROM PROBLEM 2:
   - Adding a new vehicle tier (such as `ElectricScooterFareStrategy`) is done purely by
     creating a new class implementing `VehicleFareStrategy`.
   - Existing vehicle calculation classes are never touched, ensuring 0% regression risk.
   - Fleet managers can adjust comfort or motorcycle rates in their respective classes
     without risk of cross-tier syntax or logic errors.

3. WHY THIS IS PROPORTIONATE (NOT OVER-ENGINEERING):
   Pricing in on-demand delivery apps varies drastically by vehicle form factor, country,
   and seasonal campaigns. Isolating fare formulas into self-contained strategies is a standard,
   lightweight architectural pattern that prevents monolithic pricing bugs.
================================================================================
*/

/// Strategy contract for computing trip fare according to vehicle rules.
abstract class VehicleFareStrategy {
  String get categoryName;
  double get baseFare;
  double get perKmRate;
  double get perMinuteRate;
  double get minimumFare;

  double computeFare({
    required double distanceKm,
    required int durationMinutes,
    double surgeMultiplier = 1.0,
  }) {
    final rawFare = baseFare + (distanceKm * perKmRate) + (durationMinutes * perMinuteRate);
    final surgedFare = rawFare * surgeMultiplier;
    return surgedFare < minimumFare ? minimumFare : surgedFare;
  }
}

/// Strategy 1: Economy Ride
class EconomyFareStrategy extends VehicleFareStrategy {
  @override
  String get categoryName => 'Economy Car';

  @override
  double get baseFare => 2.50;

  @override
  double get perKmRate => 0.80;

  @override
  double get perMinuteRate => 0.20;

  @override
  double get minimumFare => 5.00;
}

/// Strategy 2: Premium Comfort Ride
class ComfortFareStrategy extends VehicleFareStrategy {
  @override
  String get categoryName => 'Comfort Sedan';

  @override
  double get baseFare => 4.00;

  @override
  double get perKmRate => 1.25;

  @override
  double get perMinuteRate => 0.35;

  @override
  double get minimumFare => 8.00;
}

/// Strategy 3: Motorcycle Courier (Fast Food / Small Documents)
class MotorcycleFareStrategy extends VehicleFareStrategy {
  @override
  String get categoryName => 'Motorcycle Courier';

  @override
  double get baseFare => 1.50;

  @override
  double get perKmRate => 0.50;

  @override
  double get perMinuteRate => 0.10;

  @override
  double get minimumFare => 3.00;
}

/// Strategy 4: Cargo Van (Large Furniture / Heavy Parcels)
class CargoVanFareStrategy extends VehicleFareStrategy {
  @override
  String get categoryName => 'Cargo Van Delivery';

  @override
  double get baseFare => 10.00;

  @override
  double get perKmRate => 2.00;

  @override
  double get perMinuteRate => 0.50;

  @override
  double get minimumFare => 20.00;
}

/// Extension: Newly added Electric Scooter strategy added WITHOUT editing any existing strategies!
class ElectricScooterFareStrategy extends VehicleFareStrategy {
  @override
  String get categoryName => 'Green Electric Scooter';

  @override
  double get baseFare => 1.00;

  @override
  double get perKmRate => 0.30;

  @override
  double get perMinuteRate => 0.15;

  @override
  double get minimumFare => 2.50;
}

/// The Fare Service — completely CLOSED for modification.
class FareCalculationService {
  double calculate({
    required VehicleFareStrategy strategy,
    required double distanceKm,
    required int durationMinutes,
    double surgeMultiplier = 1.0,
  }) {
    print('[FareService] Calculating fare using strategy: ${strategy.categoryName}');
    final fare = strategy.computeFare(
      distanceKm: distanceKm,
      durationMinutes: durationMinutes,
      surgeMultiplier: surgeMultiplier,
    );
    print('[FareService] Final Fare: \$${fare.toStringAsFixed(2)} '
        '($distanceKm km, $durationMinutes mins, surge: ${surgeMultiplier}x)');
    return fare;
  }
}
