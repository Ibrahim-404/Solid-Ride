// Part of solid_principles_demo by Ibrahim Abo El-Haggag

/*
================================================================================
DEPENDENCY INVERSION PRINCIPLE (DIP) — PROBLEM 1
Feature: Live Trip Tracking & Geolocation Publisher
================================================================================

1. WHAT THIS CODE DOES:
   While a driver is on an active delivery or taxi ride, the driver app continuously
   captures GPS coordinates from the phone's physical hardware and publishes them
   in real-time to a cloud database so passengers and dispatchers can see the car
   moving live on their map.

   EXECUTION FLOW (DIRECT SDK COUPLING):
   [DriverLiveTrackingUseCase] (High-Level Business Logic)
         │ (Directly instantiates concrete low-level SDKs)
         ├── new GeolocatorDevicePlugin()
         └── new FirebaseRealtimeDatabase()
   (Cannot unit test without hardware & cloud server; locked to Firebase!)

2. WHY IT LOOKS FINE AT FIRST GLANCE:
   The high-level use case `DriverLiveTrackingUseCase` instantiates `GeolocatorDevicePlugin`
   and `FirebaseRealtimeDatabase` directly inside its constructor. It is quick to write,
   requires no dependency injection setup, and immediately works on a test phone.

3. WHAT SPECIFIC PROBLEM IT CAUSES AS CODE GROWS:
   - The high-level business usecase is tightly coupled to concrete third-party SDKs
     (`Geolocator` and `Firebase`).
   - You CANNOT write unit tests for the tracking logic. Running the test fails because
     it tries to access real native Android/iOS GPS channels and connect to Firebase servers.
   - If the engineering team decides to migrate from Firebase to a high-throughput MQTT
     broker or WebSockets, the core business use case must be completely rewritten.
   - It violates testability, portability, and clean boundaries.

4. WHICH SOLID PRINCIPLE IT VIOLATES & WHY:
   Violates the Dependency Inversion Principle (DIP):
   (1) "High-level modules should not depend on low-level modules. Both should depend
       on abstractions."
   (2) "Abstractions should not depend on details. Details should depend on abstractions."
   Here, `DriverLiveTrackingUseCase` (high-level policy) directly imports and depends on
   concrete low-level device/cloud details.
================================================================================
*/

class GeoPoint {
  final double latitude;
  final double longitude;
  final double speedKmh;
  const GeoPoint(this.latitude, this.longitude, this.speedKmh);
}

/// Concrete Low-Level Detail 1: Hardware GPS Plugin
class GeolocatorDevicePlugin {
  Stream<GeoPoint> getPositionStream() {
    print('[GeolocatorPlugin] Accessing native CoreLocation / Android LocationManager...');
    return Stream.periodic(
      const Duration(seconds: 2),
      (count) => GeoPoint(30.0444 + (count * 0.0001), 31.2357 + (count * 0.0001), 45.0),
    ).take(3);
  }
}

/// Concrete Low-Level Detail 2: Third-party Cloud SDK
class FirebaseRealtimeDatabase {
  Future<void> pushLocationUpdate(String driverId, GeoPoint point) async {
    print('[FirebaseSDK] Writing to /drivers/$driverId/live_location: (${point.latitude}, ${point.longitude})');
  }
}

/// VIOLATION: High-level business logic tightly coupled to low-level concrete plugins!
class DriverLiveTrackingUseCase {
  final String driverId;
  // Hardcoded concrete low-level dependencies!
  final GeolocatorDevicePlugin _gpsPlugin;
  final FirebaseRealtimeDatabase _firebaseDb;

  DriverLiveTrackingUseCase(this.driverId)
      : _gpsPlugin = GeolocatorDevicePlugin(),
        _firebaseDb = FirebaseRealtimeDatabase();

  void startTrackingSession() {
    print('[TrackingUseCase] Starting live tracking session for driver: $driverId');
    _gpsPlugin.getPositionStream().listen((location) async {
      // Business logic: filter erratic readings
      if (location.speedKmh > 150.0) {
        print('[TrackingUseCase] Discarding unrealistic speed reading: ${location.speedKmh} km/h');
        return;
      }

      await _firebaseDb.pushLocationUpdate(driverId, location);
    });
  }
}
