// Part of solid_principles_demo by Ibrahim Abo El-Haggag

/*
================================================================================
DEPENDENCY INVERSION PRINCIPLE (DIP) — PROBLEM 2
Feature: Offline Trip Queue & Persistence Synchronization
================================================================================

1. WHAT THIS CODE DOES:
   Drivers frequently drive into underground parking garages, airport tunnels, or
   rural dead zones where cellular connectivity drops. The driver app queues completed
   trips locally, and when connectivity is restored, synchronizes pending trips with
   the dispatch cloud servers.

   EXECUTION FLOW (DIRECT STORAGE COUPLING):
   [OfflineTripSyncCoordinator] (High-Level Sync Policy)
         │ (Directly coupled to concrete storage & network)
         ├── SqfliteLocalDatabase.instance (Raw SQL queries)
         └── DioHttpClient() (Raw HTTP calls)
   (Migrating SQLite to Hive requires rewriting the entire sync policy!)

2. WHY IT LOOKS FINE AT FIRST GLANCE:
   The class `OfflineTripSyncCoordinator` directly accesses `SqfliteLocalDatabase.instance`
   and creates a `DioHttpClient()` to upload the trips. It looks pragmatic and avoids
   "boilerplate" abstract classes.

3. WHAT SPECIFIC PROBLEM IT CAUSES AS CODE GROWS:
   - The high-level sync policy (retry logic, batch limits, error classification) is
     intertwined with raw SQL strings and low-level HTTP headers.
   - You cannot unit-test the sync algorithm on a host machine without configuring
     native SQLite shared libraries or mocking native platform channels.
   - If the engineering team upgrades the local database from SQLite to Hive, Isar,
     or ObjectBox, the entire synchronization coordinator must be rewritten.
   - Violates the principle of building business logic that is independent of data storage.

4. WHICH SOLID PRINCIPLE IT VIOLATES & WHY:
   Violates the Dependency Inversion Principle (DIP).
   `OfflineTripSyncCoordinator` (high-level sync coordinator) directly depends on
   concrete low-level details (`SqfliteLocalDatabase` and `DioHttpClient`).
================================================================================
*/

class QueuedTrip {
  final String tripId;
  final double fare;
  final DateTime completedAt;
  const QueuedTrip(this.tripId, this.fare, this.completedAt);
}

/// Concrete Low-Level Detail 1: Native SQLite Database
class SqfliteLocalDatabase {
  static final SqfliteLocalDatabase instance = SqfliteLocalDatabase._();
  SqfliteLocalDatabase._();

  List<Map<String, dynamic>> rawQuery(String sql) {
    print('[SQLite] Executing query: $sql');
    return [
      {'trip_id': 'trip_101', 'fare': 24.50, 'timestamp': '2026-09-18T10:00:00'},
      {'trip_id': 'trip_102', 'fare': 15.00, 'timestamp': '2026-09-18T10:30:00'},
    ];
  }

  void executeUpdate(String sql, List<dynamic> args) {
    print('[SQLite] Executing update: $sql with args $args');
  }
}

/// Concrete Low-Level Detail 2: Native HTTP Client
class DioHttpClient {
  Future<int> post(String url, {required Map<String, dynamic> data}) async {
    print('[DioClient] POST $url with ${data['trips'].length} items');
    return 200; // HTTP OK
  }
}

/// VIOLATION: High-level sync policy tightly bound to SQLite and Dio!
class OfflineTripSyncCoordinator {
  // Hardcoded dependencies on concrete database and HTTP libraries!
  final SqfliteLocalDatabase _db = SqfliteLocalDatabase.instance;
  final DioHttpClient _httpClient = DioHttpClient();

  Future<void> syncPendingTrips() async {
    print('[SyncCoordinator] Initiating offline trip sync...');

    // 1. Coupled to raw SQLite SQL syntax
    final rows = _db.rawQuery('SELECT * FROM queued_trips WHERE is_synced = 0 LIMIT 20');
    final trips = rows.map((r) => QueuedTrip(r['trip_id'], r['fare'], DateTime.parse(r['timestamp']))).toList();

    if (trips.isEmpty) {
      print('[SyncCoordinator] No pending trips to sync.');
      return;
    }

    // 2. Coupled to Dio HTTP client
    final statusCode = await _httpClient.post(
      'https://api.ride.com/v1/sync/trips',
      data: {'trips': trips.map((t) => {'id': t.tripId, 'fare': t.fare}).toList()},
    );

    if (statusCode == 200) {
      // 3. Coupled to raw SQL update
      final ids = trips.map((t) => t.tripId).toList();
      _db.executeUpdate('UPDATE queued_trips SET is_synced = 1 WHERE trip_id IN (?)', [ids]);
      print('[SyncCoordinator] Successfully synced ${trips.length} trips.');
    }
  }
}
