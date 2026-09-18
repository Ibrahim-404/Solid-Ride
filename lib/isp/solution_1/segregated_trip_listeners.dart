// Part of solid_principles_demo by Ibrahim Abo El-Haggag

/*
================================================================================
INTERFACE SEGREGATION PRINCIPLE (ISP) — SOLUTION 1
Feature: Driver Active Trip Event Listeners & Callbacks (Refactored)
================================================================================

1. WHAT CHANGED STRUCTURALLY:
   We segregated the monolithic listener into small, cohesive, role-specific interfaces:
   - `TripOfferListener`: Focused purely on dispatch order offers.
   - `PassengerRideListener`: Focused on passenger interactions (boarding, luggage).
   - `FoodDeliveryListener`: Focused on restaurant food package pickup and signature.
   - `RegulatedItemDeliveryListener`: Focused on age verification for controlled deliveries.
   - `TollExpenseListener`: Focused on toll booth payments.

   REFACTORED SEGREGATED FLOW:
   Role-Specific Segregated Interfaces:
      ├── [PassengerRideListener]  ── implemented by ──> TaxiRideScreen
      ├── [FoodDeliveryListener]   ── implemented by ──> FoodDeliveryWidget
      └── [TollExpenseListener]    ── implemented by ──> TollPaymentCard
   (Food delivery widget implements ONLY what it needs. Zero dummy stubs!)

2. WHY THIS FIXES THE EXACT PROBLEM FROM PROBLEM 1:
   - `FoodDeliveryTrackingWidget` implements ONLY `FoodDeliveryListener`.
   - Zero empty `{}` stubs. Zero `throw UnimplementedError()` hacks.
   - Adding a new method to `PassengerRideListener` (e.g. `onChildSeatVerified()`) causes
     ZERO compilation errors in food delivery or courier classes.
   - Code is clean, intention-revealing, and 100% self-documenting.

3. WHY THIS IS PROPORTIONATE (NOT OVER-ENGINEERING):
   Super-apps (like Careem, Grab, Uber) combine taxi rides, food orders, and parcel
   deliveries in one mobile app. Segregating domain events by vertical prevents changes
   in the taxi business line from breaking food delivery screens.
================================================================================
*/

/// Segregated interface 1: Dispatch offer events
abstract class TripOfferListener {
  void onTripOffered(String tripId);
}

/// Segregated interface 2: Passenger ride events
abstract class PassengerRideListener {
  void onPassengerBoarded(String passengerName);
  void onPassengerLuggageLoaded(int bagCount);
}

/// Segregated interface 3: Food and parcel courier events
abstract class FoodDeliveryListener {
  void onFoodPackagePickedUp(String orderId, String restaurantName);
  void onCustomerSignatureCollected(String signatureSvg);
}

/// Segregated interface 4: Age-restricted or pharmacy verification
abstract class RegulatedItemDeliveryListener {
  void onAgeVerificationCompleted(String customerId, int verifiedAge);
}

/// Segregated interface 5: Highway toll and road fee events
abstract class TollExpenseListener {
  void onTollFeePaid(double tollAmount);
}

/// Clean Client 1: Food delivery widget implements ONLY what it needs!
class CleanFoodDeliveryTrackingWidget implements FoodDeliveryListener {
  final String orderId;

  CleanFoodDeliveryTrackingWidget(this.orderId);

  @override
  void onFoodPackagePickedUp(String orderId, String restaurantName) {
    print('[CleanFoodWidget] Order $orderId picked up from $restaurantName. Updated UI to IN_TRANSIT.');
  }

  @override
  void onCustomerSignatureCollected(String signatureSvg) {
    print('[CleanFoodWidget] Customer signature captured. Enabling order completion.');
  }
}

/// Clean Client 2: Passenger Taxi ride screen implements passenger & toll listeners.
class CleanPassengerRideScreen implements PassengerRideListener, TollExpenseListener {
  final String tripId;

  CleanPassengerRideScreen(this.tripId);

  @override
  void onPassengerBoarded(String passengerName) {
    print('[PassengerScreen] Rider $passengerName boarded. Starting trip meter.');
  }

  @override
  void onPassengerLuggageLoaded(int bagCount) {
    print('[PassengerScreen] $bagCount bags stowed in trunk.');
  }

  @override
  void onTollFeePaid(double tollAmount) {
    print('[PassengerScreen] Highway toll of \$${tollAmount.toStringAsFixed(2)} added to rider receipt.');
  }
}
