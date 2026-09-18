// Part of solid_principles_demo by Ibrahim Abo El-Haggag

/*
================================================================================
INTERFACE SEGREGATION PRINCIPLE (ISP) — PROBLEM 2
Feature: Driver Device Hardware Telemetry & Sensor Suite
================================================================================

1. WHAT THIS CODE DOES:
   The driver app interacts with various phone hardware sensors and external
   peripherals: GPS location streaming, battery level monitoring, accelerometer
   impact/crash detection, Bluetooth taximeter synchronization, and hardware
   emergency SOS beacon triggering.

   EXECUTION FLOW (HARDWARE COUPLING):
   [DriverDeviceTelemetry] (GPS + Battery + Crash Sensors + Bluetooth Taximeter)
         ▲
         └── DriverMapWidget (Only needs GPS location to move pin!)
               (Coupled to taximeters & crash sensors; hard to mock and test!)

2. WHY IT LOOKS FINE AT FIRST GLANCE:
   "It's all device hardware and telemetry." Packaging all phone sensor features
   into a single interface `DriverDeviceTelemetry` seems clean and centralized.

3. WHAT SPECIFIC PROBLEM IT CAUSES AS CODE GROWS:
   - The map navigation widget (`DriverMapTrackingWidget`) only needs GPS coordinates
     to render the moving car icon on the map.
   - Because it takes `DriverDeviceTelemetry`, it is unnecessarily coupled to
     Bluetooth taximeters, crash sensors, and SOS emergency hardware.
   - Writing a Flutter widget test for the map requires mocking the entire hardware
     sensor suite, including Bluetooth connectivity and crash algorithms.
   - If the engineering team updates the Bluetooth taximeter protocol or adds a new
     gyroscopic sensor method, the map widget must be recompiled and re-tested.

4. WHICH SOLID PRINCIPLE IT VIOLATES & WHY:
   Violates the Interface Segregation Principle (ISP).
   `DriverMapTrackingWidget` is forced to depend on an interface containing methods
   for crash sensors, taximeters, and SOS beacons that it never uses.
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

/// Monolithic "Fat" Interface violating ISP.
abstract class DriverDeviceTelemetry {
  Stream<GeoCoordinate> get locationStream;
  Future<int> getBatteryPercentage();
  Future<void> sendCrashSensorTelemetry(CrashSensorData data);
  Future<void> syncBluetoothTaximeter(String meterSerial);
  Future<void> triggerEmergencySosBeacon();
}

/// VIOLATION: A Map UI widget depending on a huge hardware interface it mostly ignores.
class DriverMapTrackingWidget {
  final DriverDeviceTelemetry _telemetry;

  DriverMapTrackingWidget(this._telemetry);

  void renderDriverMarkerOnMap() {
    print('[MapWidget] Subscribing to location stream...');
    // The map ONLY cares about location!
    _telemetry.locationStream.listen((coordinate) {
      print('[MapWidget] Updated car pin on map to: (${coordinate.latitude}, ${coordinate.longitude})');
    });

    // But the widget has access to dangerous, unrelated hardware methods:
    // _telemetry.triggerEmergencySosBeacon();  <-- Accidental risk!
    // _telemetry.syncBluetoothTaximeter('TX-99');
  }
}
