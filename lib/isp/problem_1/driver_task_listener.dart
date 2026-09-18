// Part of solid_principles_demo by Ibrahim Abo El-Haggag

/*
================================================================================
INTERFACE SEGREGATION PRINCIPLE (ISP) — PROBLEM 1
Feature: Driver Active Trip Event Listeners & Callbacks
================================================================================

1. WHAT THIS CODE DOES:
   In a multi-service gig driver app (passenger rides, food delivery, courier),
   the app notifies UI components and background handlers about trip events:
   passenger boarding, luggage loading, food pickup, age verification checks,
   toll fee payments, and customer signatures.

2. WHY IT LOOKS FINE AT FIRST GLANCE:
   It groups all driver trip event callbacks into one comprehensive interface:
   `DriverTripEventListener`. Having a single listener seems organized and convenient
   because "they are all driver events".

3. WHAT SPECIFIC PROBLEM IT CAUSES AS CODE GROWS:
   - A food delivery courier screen (`FoodDeliveryTrackingWidget`) only cares about
     food pickup and customer signature. Yet it is forced to implement 5 other irrelevant
     methods (`onPassengerBoarded`, `onLuggageLoaded`, `onTollPaid`, etc.) with empty bodies
     `{}` or `throw UnimplementedError()`.
   - If passenger operations adds `onChildSeatInspected()` or `onPetRestraintChecked()`,
     every food delivery widget and courier listener across the entire app BREAKS
     and fails to compile until empty stubs are added.
   - Code is cluttered with useless boilerplate stubs that mislead developers reading the file.

4. WHICH SOLID PRINCIPLE IT VIOLATES & WHY:
   Violates the Interface Segregation Principle (ISP): "Clients should not be forced
   to depend on methods they do not use."
   `DriverTripEventListener` is a "fat" interface forcing food couriers and package
   handlers to implement passenger taxi methods they have no reason to care about.
================================================================================
*/

/// Monolithic "Fat" Interface violating ISP.
abstract class DriverTripEventListener {
  void onTripOffered(String tripId);
  void onPassengerBoarded(String passengerName);
  void onPassengerLuggageLoaded(int bagCount);
  void onFoodPackagePickedUp(String orderId, String restaurantName);
  void onAgeVerificationCompleted(String customerId, int verifiedAge);
  void onTollFeePaid(double tollAmount);
  void onCustomerSignatureCollected(String signatureSvg);
}

/// VIOLATION: A food courier UI component forced to implement passenger methods!
class FoodDeliveryTrackingWidget implements DriverTripEventListener {
  final String orderId;

  FoodDeliveryTrackingWidget(this.orderId);

  @override
  void onFoodPackagePickedUp(String orderId, String restaurantName) {
    print('[FoodWidget] Order $orderId picked up from $restaurantName. Updating UI order badge to IN_TRANSIT.');
  }

  @override
  void onCustomerSignatureCollected(String signatureSvg) {
    print('[FoodWidget] Customer signature captured. Unlocking "Complete Delivery" button.');
  }

  // --- USELESS STUBS FORCED BY FAT INTERFACE ---
  @override
  void onTripOffered(String tripId) {} // Irrelevant here

  @override
  void onPassengerBoarded(String passengerName) {
    // Dangerous: food couriers don't carry human passengers!
    throw UnimplementedError('Food couriers do not pick up passengers!');
  }

  @override
  void onPassengerLuggageLoaded(int bagCount) {
    throw UnimplementedError('Food couriers do not load passenger luggage!');
  }

  @override
  void onAgeVerificationCompleted(String customerId, int verifiedAge) {}

  @override
  void onTollFeePaid(double tollAmount) {}
}
