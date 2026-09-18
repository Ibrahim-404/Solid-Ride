// Part of solid_principles_demo by Ibrahim Abo El-Haggag

/*
================================================================================
LISKOV SUBSTITUTION PRINCIPLE (LSP) — SOLUTION 1
Feature: Multi-Modal Driver Fleet & Passenger Accommodations (Refactored)
================================================================================

1. WHAT CHANGED STRUCTURALLY:
   We restructured the inheritance hierarchy to reflect actual behavioral contracts:
   - `Vehicle`: Base class holding ONLY universal vehicle attributes (identity,
     coordinates, moving capability).
   - `PassengerVehicle`: Sub-hierarchy introducing passenger accommodations (cabin
     doors, climate control, passenger seating capacity).
   - `CargoCourierVehicle`: Sub-hierarchy introducing delivery-specific attributes
     (cargo box volume, insulated food bag).
   - Dispatch coordinators that prepare passenger rides now explicitly depend on
     `PassengerVehicle`.

2. WHY THIS FIXES THE EXACT PROBLEM FROM PROBLEM 1:
   - Any subclass of `PassengerVehicle` (Sedan, Luxury SUV, Minivan) can be substituted
     freely without throwing `UnsupportedError`.
   - `BicycleCourier` and `MotorcycleCourier` inherit from `CargoCourierVehicle` (or `Vehicle`)
     and are never passed to passenger-prep coordinators.
   - Eliminates all dirty type checks (`if (vehicle is Sedan)`). Polymorphism works
     safely and predictably as designed.

3. WHY THIS IS PROPORTIONATE (NOT OVER-ENGINEERING):
   Modern transport apps support cars, tuk-tuks, scooters, and bikes. Enforcing accurate
   behavioral contracts prevents runtime crashes on live driver shifts and eliminates
   defensive type-checking bugs across the codebase.
================================================================================
*/

class GeoLocation {
  final double latitude;
  final double longitude;

  const GeoLocation(this.latitude, this.longitude);
}

/// Base contract: Attributes true for ALL vehicles in the fleet.
abstract class Vehicle {
  final String vehicleId;
  final String driverId;
  final GeoLocation location;

  Vehicle({
    required this.vehicleId,
    required this.driverId,
    required this.location,
  });

  String get vehicleTypeDescription;
}

/// Subtype for vehicles designed to carry human passengers.
abstract class PassengerVehicle extends Vehicle {
  PassengerVehicle({
    required super.vehicleId,
    required super.driverId,
    required super.location,
  });

  int get passengerCapacity;
  void turnOnClimateControl();
  void lockDoors();
}

/// Subtype for vehicles designed for parcel / food courier delivery.
abstract class CargoCourierVehicle extends Vehicle {
  CargoCourierVehicle({
    required super.vehicleId,
    required super.driverId,
    required super.location,
  });

  double get cargoVolumeLiters;
  bool get hasThermalBag;
}

/// Concrete Passenger Vehicle 1: Standard Sedan (Substitute for PassengerVehicle)
class SedanRideCar extends PassengerVehicle {
  bool isAcActive = false;
  bool areDoorsLocked = false;

  SedanRideCar({
    required super.vehicleId,
    required super.driverId,
    required super.location,
  });

  @override
  String get vehicleTypeDescription => 'Standard Sedan Car';

  @override
  int get passengerCapacity => 4;

  @override
  void turnOnClimateControl() {
    isAcActive = true;
    print('[Sedan $vehicleId] Climate control activated to 21°C.');
  }

  @override
  void lockDoors() {
    areDoorsLocked = true;
    print('[Sedan $vehicleId] Doors locked securely.');
  }
}

/// Concrete Passenger Vehicle 2: Luxury SUV (Substitute for PassengerVehicle)
class LuxurySuvCar extends PassengerVehicle {
  LuxurySuvCar({
    required super.vehicleId,
    required super.driverId,
    required super.location,
  });

  @override
  String get vehicleTypeDescription => 'Premium Luxury SUV';

  @override
  int get passengerCapacity => 6;

  @override
  void turnOnClimateControl() {
    print('[Luxury SUV $vehicleId] Dual-zone premium climate control activated to 20°C.');
  }

  @override
  void lockDoors() {
    print('[Luxury SUV $vehicleId] Child-lock & soft-close automatic doors engaged.');
  }
}

/// Concrete Courier: Bicycle Courier (Substitute for CargoCourierVehicle)
class BicycleCourier extends CargoCourierVehicle {
  BicycleCourier({
    required super.vehicleId,
    required super.driverId,
    required super.location,
  });

  @override
  String get vehicleTypeDescription => 'Bicycle Courier';

  @override
  double get cargoVolumeLiters => 35.0; // Food backpack capacity

  @override
  bool get hasThermalBag => true;
}

/// Fleet coordinator: depends strictly on PassengerVehicle.
/// LSP Guaranteed: Any PassengerVehicle can be substituted with ZERO runtime exceptions!
class PassengerDispatchCoordinator {
  void prepareFleetForPassengerRide(List<PassengerVehicle> passengerFleet) {
    for (final car in passengerFleet) {
      print('[Coordinator] Preparing ${car.vehicleTypeDescription} (${car.vehicleId}) for passenger...');
      car.lockDoors();
      car.turnOnClimateControl();
      print('[Coordinator] Seats available: ${car.passengerCapacity}. Ready for dispatch!\n');
    }
  }
}
