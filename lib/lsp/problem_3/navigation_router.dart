// Part of solid_principles_demo by Ibrahim Abo El-Haggag

/*
================================================================================
LISKOV SUBSTITUTION PRINCIPLE (LSP) — PROBLEM 3
Feature: Turn-by-Turn Navigation Routing Engines
================================================================================

1. WHAT THIS CODE DOES:
   In the driver app, once a trip is accepted, the app calculates the fastest
   turn-by-turn route from the driver's current location to the pickup point.
   The base class `NavigationRouter` defines the contract for calculating routes.

2. WHY IT LOOKS FINE AT FIRST GLANCE:
   Both cars and walking couriers need turn-by-turn navigation. Putting them under
   a common `NavigationRouter` interface seems like natural polymorphism.

3. WHAT SPECIFIC PROBLEM IT CAUSES AS CODE GROWS:
   - A developer creates `PedestrianCourierRouter` for short-distance walking couriers.
   - However, if the destination requires crossing an elevated highway or toll bridge,
     `PedestrianCourierRouter` throws `UnsupportedError('Pedestrians cannot access highways!')`.
   - Furthermore, it returns an empty list for `turnDirections`, violating the base
     class expectation that a generated route always provides turn instructions.
   - When the turn-by-turn navigation widget tries to read `route.turnDirections.first`,
     the app crashes with `StateError: Bad state: No element`.
   - Developers end up writing dirty `is` checks:
     `if (router is PedestrianCourierRouter) { ... }` which breaks polymorphism.

4. WHICH SOLID PRINCIPLE IT VIOLATES & WHY:
   Violates the Liskov Substitution Principle (LSP).
   `PedestrianCourierRouter` cannot be substituted for `NavigationRouter` because it
   strengthens preconditions (rejecting highway coordinates with exceptions) and
   weakens postconditions (returning empty navigation instructions where full guidance
   was promised).
================================================================================
*/

class GeoPoint {
  final double lat;
  final double lng;
  const GeoPoint(this.lat, this.lng);
}

class NavigationRoute {
  final double distanceKm;
  final int estimatedMinutes;
  final List<String> turnDirections;

  const NavigationRoute({
    required this.distanceKm,
    required this.estimatedMinutes,
    required this.turnDirections,
  });
}

abstract class NavigationRouter {
  /// Base contract guarantees: returns a valid NavigationRoute with non-empty turnDirections.
  Future<NavigationRoute> calculateRoute({
    required GeoPoint origin,
    required GeoPoint destination,
  });
}

/// Car router: satisfies the base contract.
class CarNavigationRouter extends NavigationRouter {
  @override
  Future<NavigationRoute> calculateRoute({
    required GeoPoint origin,
    required GeoPoint destination,
  }) async {
    print('[CarRouter] Calculating highway and arterial road route...');
    return const NavigationRoute(
      distanceKm: 8.5,
      estimatedMinutes: 18,
      turnDirections: [
        'Head north on Main St',
        'Take Ring Road Highway exit 4',
        'Turn right on Destination Blvd',
      ],
    );
  }
}

/// VIOLATION: Subclass throws unexpected exceptions and weakens postconditions!
class PedestrianCourierRouter extends NavigationRouter {
  @override
  Future<NavigationRoute> calculateRoute({
    required GeoPoint origin,
    required GeoPoint destination,
  }) async {
    // VIOLATION 1: Throws surprise exception if distance is beyond walking radius!
    const simulatedDistance = 8.5;
    if (simulatedDistance > 5.0) {
      throw UnsupportedError('Distance $simulatedDistance km exceeds pedestrian route limits!');
    }

    // VIOLATION 2: Returns empty turn directions, breaking caller invariant!
    return const NavigationRoute(
      distanceKm: simulatedDistance,
      estimatedMinutes: 60,
      turnDirections: [], // Empty! Will crash turn-by-turn HUD widgets.
    );
  }
}

/// Navigation screen controller that breaks when LSP is violated.
class NavigationHudController {
  final NavigationRouter _router;

  NavigationHudController(this._router);

  Future<void> startNavigation(GeoPoint start, GeoPoint end) async {
    print('[NavigationHUD] Requesting route...');

    // CRASH! Throws UnsupportedError if _router is PedestrianCourierRouter and distance > 5km.
    final route = await _router.calculateRoute(origin: start, destination: end);

    // CRASH! Throws StateError (No element) if turnDirections is empty!
    final nextTurn = route.turnDirections.first;
    print('[NavigationHUD] Next maneuver: $nextTurn (ETA: ${route.estimatedMinutes} mins)');
  }
}
