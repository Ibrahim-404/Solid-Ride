// Part of solid_principles_demo by Ibrahim Abo El-Haggag

/*
================================================================================
DEPENDENCY INVERSION PRINCIPLE (DIP) — SOLUTION 1
Feature: Live Trip Tracking & Geolocation Publisher (Refactored)
================================================================================

1. WHAT CHANGED STRUCTURALLY:
   We inverted the direction of dependencies by introducing two domain abstractions:
   - `LocationStreamSource`: Abstract contract for receiving device coordinate streams.
   - `LiveLocationPublisher`: Abstract contract for broadcasting coordinates to the cloud.
   - `DriverLiveTrackingUseCase`: High-level business logic that depends ONLY on these
     abstractions (injected via constructor).
   - Concrete plugins (`DeviceGpsLocationSource`, `FirebaseLocationPublisher`, `MqttLocationPublisher`)
     now depend on and implement these abstractions.

2. WHY THIS FIXES THE EXACT PROBLEM FROM PROBLEM 1:
   - Unit testing `DriverLiveTrackingUseCase` is 100% independent of hardware and networks:
     simply inject a `MockLocationStreamSource` emitting test coordinates.
   - Switching from Firebase to MQTT or Supabase requires writing one new adapter class;
     zero changes to `DriverLiveTrackingUseCase`.
   - The high-level module defines the contract that low-level infrastructure must fulfill.

3. WHY THIS IS PROPORTIONATE (NOT OVER-ENGINEERING):
   Driver location tracking is the single most network- and battery-intensive feature
   in a transport app. Decoupling the business logic from native sensors and cloud protocols
   is crucial for testability, battery optimization, and regional cloud adaptability.
================================================================================
*/

class GeoPoint {
  final double latitude;
  final double longitude;
  final double speedKmh;
  const GeoPoint(this.latitude, this.longitude, this.speedKmh);
}

/// Domain Abstraction 1: Source of driver location updates
abstract class LocationStreamSource {
  Stream<GeoPoint> streamLocations();
}

/// Domain Abstraction 2: Sink for broadcasting live driver locations
abstract class LiveLocationPublisher {
  Future<void> publishLocation({
    required String driverId,
    required GeoPoint location,
  });
}

/// High-Level Module: Depends STRICTLY on abstractions. Zero concrete imports!
class DriverLiveTrackingUseCase {
  final String driverId;
  final LocationStreamSource _locationSource;
  final LiveLocationPublisher _locationPublisher;

  DriverLiveTrackingUseCase({
    required this.driverId,
    required LocationStreamSource locationSource,
    required LiveLocationPublisher locationPublisher,
  })  : _locationSource = locationSource,
        _locationPublisher = locationPublisher;

  void startTrackingSession() {
    print('[TrackingUseCase] Started live tracking session for driver: $driverId');
    _locationSource.streamLocations().listen((location) async {
      // Pure business rule: filter telemetry glitches
      if (location.speedKmh > 150.0) {
        print('[TrackingUseCase] Glitch detected: Discarding unrealistic speed ${location.speedKmh} km/h.');
        return;
      }

      await _locationPublisher.publishLocation(
        driverId: driverId,
        location: location,
      );
    });
  }
}

/// Low-Level Detail Adapter 1: Real native GPS hardware
class DeviceGpsLocationSource implements LocationStreamSource {
  @override
  Stream<GeoPoint> streamLocations() {
    print('[DeviceGps] Connecting to phone hardware sensors...');
    return Stream.periodic(
      const Duration(seconds: 1),
      (i) => GeoPoint(30.0444 + (i * 0.0002), 31.2357 + (i * 0.0002), 38.0),
    ).take(2);
  }
}

/// Low-Level Detail Adapter 2: Firebase Realtime Database
class FirebaseLocationPublisher implements LiveLocationPublisher {
  @override
  Future<void> publishLocation({
    required String driverId,
    required GeoPoint location,
  }) async {
    print('[FirebasePublisher] Uploaded coordinate to /drivers/$driverId: (${location.latitude}, ${location.longitude})');
  }
}

/// Low-Level Detail Adapter 3: High-throughput MQTT Broker (Easily swappable!)
class MqttLocationPublisher implements LiveLocationPublisher {
  @override
  Future<void> publishLocation({
    required String driverId,
    required GeoPoint location,
  }) async {
    print('[MqttPublisher] Published payload to topic "telemetry/$driverId/gps": (${location.latitude}, ${location.longitude})');
  }
}
