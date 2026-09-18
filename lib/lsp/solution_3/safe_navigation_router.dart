// Part of solid_principles_demo by Ibrahim Abo El-Haggag

/*
================================================================================
LISKOV SUBSTITUTION PRINCIPLE (LSP) — SOLUTION 3
Feature: Turn-by-Turn Navigation Routing Engines (Refactored)
================================================================================

1. WHAT CHANGED STRUCTURALLY:
   We redesigned the routing contract so that failure modes and routing constraints
   are represented explicitly via a result object (`RouteResult`):
   - `RouteResult`: Encapsulates success (with valid `NavigationRoute` guaranteed to
     have non-empty maneuvers) or graceful failure with a user-friendly explanation.
   - `NavigationRouter`: Guaranteed contract that never throws unhandled routing exceptions.
   - `PedestrianCourierRouter`: Respects the postcondition. When walking routes are
     infeasible, it returns a failed `RouteResult` instead of crashing with `UnsupportedError`.
   - When successful, it provides valid walking maneuvers rather than empty lists.

   REFACTORED UNIFORM ROUTING FLOW:
   Turn-by-turn Navigation HUD
           ↓
   router.calculateRoute()
      ├── CarRouter        ──> RouteResult.success(routeWithSteps)
      ├── MotorbikeRouter  ──> RouteResult.success(routeWithShortcuts)
      └── PedestrianRouter ──> RouteResult.failure("Exceeds walking distance")
   (HUD handles all router implementations without type checks or crashes!)

2. WHY THIS FIXES THE EXACT PROBLEM FROM PROBLEM 3:
   - Any router implementation (`CarNavigationRouter`, `MotorcycleRouter`, `PedestrianRouter`)
     is 100% substitutable for `NavigationRouter`.
   - The navigation HUD controller never crashes, doesn't need `try/catch` guards, and never
     needs defensive `is` type checks.
   - The UI displays friendly guidance whenever a walking route cannot be safely mapped.

3. WHY THIS IS PROPORTIONATE (NOT OVER-ENGINEERING):
   Navigation in a driver app is the active operational heartbeat. A runtime crash while
   a driver is driving on an expressway is dangerous. Guaranteeing contract adherence across
   all routing modes is essential for passenger and driver safety.
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

/// Explicit result wrapper preserving LSP invariants.
class RouteResult {
  final bool isSuccess;
  final NavigationRoute? route;
  final String? errorMessage;

  const RouteResult._({
    required this.isSuccess,
    this.route,
    this.errorMessage,
  });

  factory RouteResult.success(NavigationRoute route) {
    return RouteResult._(isSuccess: true, route: route);
  }

  factory RouteResult.failure(String message) {
    return RouteResult._(isSuccess: false, errorMessage: message);
  }
}

/// Abstract router contract that all subtypes strictly honor.
abstract class NavigationRouter {
  String get routerModeName;
  Future<RouteResult> calculateRoute({
    required GeoPoint origin,
    required GeoPoint destination,
  });
}

/// Subtype 1: Car Router (Highways, Arterials)
class CarNavigationRouter implements NavigationRouter {
  @override
  String get routerModeName => 'Automobile Mode';

  @override
  Future<RouteResult> calculateRoute({
    required GeoPoint origin,
    required GeoPoint destination,
  }) async {
    print('[CarRouter] Routing via expressways and arterial boulevards...');
    return RouteResult.success(
      const NavigationRoute(
        distanceKm: 8.5,
        estimatedMinutes: 18,
        turnDirections: [
          'Head north on Main St (500m)',
          'Merge onto Ring Expressway (6 km)',
          'Take exit 12 toward Downtown (2 km)',
        ],
      ),
    );
  }
}

/// Subtype 2: Motorcycle / Scooter Router (Alleys, Filter Lane)
class MotorcycleNavigationRouter implements NavigationRouter {
  @override
  String get routerModeName => 'Motorcycle Courier Mode';

  @override
  Future<RouteResult> calculateRoute({
    required GeoPoint origin,
    required GeoPoint destination,
  }) async {
    print('[MotorcycleRouter] Routing via narrow alleys and local short-cuts...');
    return RouteResult.success(
      const NavigationRoute(
        distanceKm: 6.2,
        estimatedMinutes: 12,
        turnDirections: [
          'Head north on Main St alley (200m)',
          'Cut through Old Market bypass (3 km)',
          'Arrive at customer doorstep',
        ],
      ),
    );
  }
}

/// Subtype 3: Walking Courier Router (Pedestrian Walkways, Sidewalks)
/// Fully substitutable for NavigationRouter without throwing exceptions!
class PedestrianCourierRouter implements NavigationRouter {
  @override
  String get routerModeName => 'Walking Courier Mode';

  @override
  Future<RouteResult> calculateRoute({
    required GeoPoint origin,
    required GeoPoint destination,
  }) async {
    const simulatedDistance = 8.5; // Example long distance

    if (simulatedDistance > 5.0) {
      // Honors contract: returns failure result instead of throwing unhandled exception!
      return RouteResult.failure(
        'Trip distance (${simulatedDistance}km) exceeds max walking delivery radius (5.0km).',
      );
    }

    return RouteResult.success(
      const NavigationRoute(
        distanceKm: simulatedDistance,
        estimatedMinutes: 45,
        turnDirections: [
          'Walk north along pedestrian walkway',
          'Cross footbridge at Sector 2',
          'Arrive at customer drop-off',
        ],
      ),
    );
  }
}

/// Navigation screen controller: Works reliably with ANY NavigationRouter subtype!
class SafeNavigationHudController {
  final NavigationRouter _router;

  SafeNavigationHudController(this._router);

  Future<void> launchRoute(GeoPoint start, GeoPoint end) async {
    print('[NavigationHUD] Computing route using: ${_router.routerModeName}');
    final result = await _router.calculateRoute(origin: start, destination: end);

    if (result.isSuccess && result.route != null) {
      final route = result.route!;
      print('[NavigationHUD] Route found (${route.distanceKm}km, ${route.estimatedMinutes} mins).');
      print('[NavigationHUD] Next maneuver: "${route.turnDirections.first}". Navigating...');
    } else {
      print('[NavigationHUD] Could not route: ${result.errorMessage}');
    }
  }
}
