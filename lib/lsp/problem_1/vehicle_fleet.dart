// Part of solid_principles_demo by Ibrahim Abo El-Haggag

/*
================================================================================
LISKOV SUBSTITUTION PRINCIPLE (LSP) — PROBLEM 1
Feature: Multi-Modal Driver Fleet & Passenger Accommodations
================================================================================

1. WHAT THIS CODE DOES:
   In a multi-service platform offering both passenger rides (taxi/rideshare)
   and courier delivery (food/packages), the system models all vehicles using
   a base class `Vehicle`. Before dispatching a passenger trip, the system locks
   the vehicle doors and pre-activates air conditioning for passenger comfort.

   EXECUTION FLOW (BROKEN SUBSTITUTION):
   Passenger Dispatch Coordinator
           ↓
   Loops through: List<Vehicle>
      ├── Car  ──> vehicle.turnOnAirConditioning() ──> OK
      └── Bike ──> vehicle.turnOnAirConditioning() ──> CRASH!
   (Throws UnsupportedError: Subtype fails to honor base contract!)

2. WHY IT LOOKS FINE AT FIRST GLANCE:
   "A bicycle is a vehicle, and a car is a vehicle." In natural language, making
   `BicycleDelivery` and `MotorcycleCourier` inherit from `Vehicle` feels intuitive
   and saves code by reusing the common `vehicleId`, `driverId`, and `currentLocation`.

3. WHAT SPECIFIC PROBLEM IT CAUSES AS CODE GROWS:
   - When a passenger ride request comes in, the dispatch coordinator iterates over
     available `List<Vehicle>` and calls `vehicle.turnOnAirConditioning()`.
   - When it reaches a `BicycleDelivery`, the program blows up with:
     `UnsupportedError: Bicycles do not have air conditioning!`
   - The application crashes in production for real riders and drivers.
   - Developers are tempted to patch this by writing dirty type checks everywhere:
     `if (vehicle is! BicycleDelivery && vehicle is! MotorcycleCourier) { ... }`
     which breaks whenever a new two-wheeler (like an electric scooter) is added.

4. WHICH SOLID PRINCIPLE IT VIOLATES & WHY:
   Violates the Liskov Substitution Principle (LSP): "Subtypes must be substitutable
   for their base types without altering the correctness of the program."
   `BicycleDelivery` CANNOT be substituted in place of `Vehicle`. It breaks the base
   class contract by throwing unexpected exceptions and failing to fulfill the promised
   behavior of `turnOnAirConditioning()` and `lockPassengerDoors()`.
================================================================================
*/

class GeoLocation {
  final double latitude;
  final double longitude;

  const GeoLocation(this.latitude, this.longitude);
}

/// The flawed base class that assumes all vehicles have passenger amenities.
abstract class Vehicle {
  final String vehicleId;
  final String driverId;
  final GeoLocation location;

  Vehicle({
    required this.vehicleId,
    required this.driverId,
    required this.location,
  });

  int get passengerCapacity;
  void turnOnAirConditioning();
  void lockPassengerDoors();
}

/// A standard 4-door passenger car. Implements the base class correctly.
class SedanRideCar extends Vehicle {
  bool isAcOn = false;
  bool areDoorsLocked = false;

  SedanRideCar({
    required super.vehicleId,
    required super.driverId,
    required super.location,
  });

  @override
  int get passengerCapacity => 4;

  @override
  void turnOnAirConditioning() {
    isAcOn = true;
    print('[Sedan $vehicleId] Air conditioning turned on to 21°C.');
  }

  @override
  void lockPassengerDoors() {
    areDoorsLocked = true;
    print('[Sedan $vehicleId] All passenger doors locked.');
  }
}

/// VIOLATION: A bicycle courier forced to inherit passenger car capabilities!
class BicycleDeliveryCourier extends Vehicle {
  BicycleDeliveryCourier({
    required super.vehicleId,
    required super.driverId,
    required super.location,
  });

  @override
  int get passengerCapacity => 0;

  @override
  void turnOnAirConditioning() {
    // VIOLATION OF LSP: Throws unexpected runtime exception on a base contract method!
    throw UnsupportedError('Bicycles do not have air conditioning or closed cabins!');
  }

  @override
  void lockPassengerDoors() {
    // VIOLATION OF LSP: Throws unexpected runtime exception!
    throw UnsupportedError('Bicycles do not have passenger doors to lock!');
  }
}

/// Fleet coordinator that crashes when LSP is violated.
class FleetDispatchCoordinator {
  void prepareVehiclesForPassengerTrip(List<Vehicle> availableFleet) {
    for (final vehicle in availableFleet) {
      print('[Coordinator] Preparing vehicle ${vehicle.vehicleId} for passenger pick-up...');
      // CRASH! If vehicle is BicycleDeliveryCourier, this line throws an unhandled UnsupportedError!
      vehicle.lockPassengerDoors();
      vehicle.turnOnAirConditioning();
    }
  }
}
