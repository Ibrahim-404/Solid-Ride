// Part of solid_principles_demo by Ibrahim Abo El-Haggag

/*
================================================================================
INTERFACE SEGREGATION PRINCIPLE (ISP) — SOLUTION 2
Feature: Driver Device Hardware Telemetry & Sensor Suite (Refactored)
================================================================================

1. WHAT CHANGED STRUCTURALLY:
   The fat `DriverDeviceTelemetry` interface was split into fine-grained, cohesive contracts:
   - `LocationProvider`: Dedicated solely to GPS position streaming.
   - `BatteryMonitor`: Dedicated to device power state.
   - `CrashDetectionSensor`: Dedicated to high-impact accelerometer events.
   - `TaximeterIntegration`: Dedicated to physical Bluetooth taximeter synchronization.
   - `EmergencySosService`: Dedicated to panic/distress signals.

   REFACTORED SEGREGATED FLOW:
   Segregated Interfaces:
      ├── [LocationProvider]     ── used by ──> DriverMapWidget (Clean & focused)
      ├── [BatteryMonitor]       ── used by ──> BatteryStatusBanner
      └── [TaximeterIntegration] ── used by ──> BluetoothMeterSyncService
   (Map widget depends ONLY on LocationProvider. Zero hardware coupling!)

2. WHY THIS FIXES THE EXACT PROBLEM FROM PROBLEM 2:
   - `DriverMapTrackingWidget` depends strictly on `LocationProvider`.
   - The map widget has zero visibility into or coupling with Bluetooth hardware, crash
     detection, or emergency beacons.
   - Writing a Flutter widget test for the map takes 3 lines: provide a fake `LocationProvider`
     emitting stream coordinates.
   - Modifying taximeter protocols or accelerometer algorithms causes zero recompilation
     or regression risk for map navigation.

3. WHY THIS IS PROPORTIONATE (NOT OVER-ENGINEERING):
   Device hardware access in Flutter relies on distinct platform plugins (e.g. `geolocator`,
   `battery_plus`, `sensors_plus`). Splitting hardware abstractions prevents UI widgets from
   turning into sprawling integration hazards.
================================================================================
*/

class GeoCoordinate {
  final double latitude;
  final double longitude;
  const GeoCoordinate(this.latitude, this.longitude);
}

class CrashSensorData {
  final double gForce;
  final double angularVelocity;
  const CrashSensorData(this.gForce, this.angularVelocity);
}

/// Segregated Interface 1: GPS coordinates only
abstract class LocationProvider {
  Stream<GeoCoordinate> get locationStream;
}

/// Segregated Interface 2: Battery health only
abstract class BatteryMonitor {
  Future<int> getBatteryPercentage();
}

/// Segregated Interface 3: Crash detection only
abstract class CrashDetectionSensor {
  Future<void> sendCrashSensorTelemetry(CrashSensorData data);
}

/// Segregated Interface 4: Peripheral taximeter only
abstract class TaximeterIntegration {
  Future<void> syncBluetoothTaximeter(String meterSerial);
}

/// Segregated Interface 5: Emergency beacon only
abstract class EmergencySosService {
  Future<void> triggerEmergencySosBeacon();
}

/// Clean Client: Map widget depends ONLY on LocationProvider!
class CleanDriverMapTrackingWidget {
  final LocationProvider _locationProvider;

  CleanDriverMapTrackingWidget(this._locationProvider);

  void renderDriverMarkerOnMap() {
    print('[CleanMapWidget] Subscribing to focused LocationProvider...');
    _locationProvider.locationStream.listen((coordinate) {
      print('[CleanMapWidget] Updating car pin position to: (${coordinate.latitude}, ${coordinate.longitude})');
    });
    // No access to taximeters, crash sensors, or emergency beacons. Safe by design!
  }
}

/// Implementation: Phone hardware service can implement multiple interfaces
/// without forcing client widgets to depend on the whole bundle.
class PhoneHardwareManager implements LocationProvider, BatteryMonitor {
  @override
  Stream<GeoCoordinate> get locationStream => Stream.fromIterable([
        const GeoCoordinate(30.0444, 31.2357), // Cairo coordinates
        const GeoCoordinate(30.0450, 31.2365),
      ]);

  @override
  Future<int> getBatteryPercentage() async => 88;
}
