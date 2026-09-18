// Part of solid_principles_demo by Ibrahim Abo El-Haggag

/*
================================================================================
DEPENDENCY INVERSION PRINCIPLE (DIP) — SOLUTION 2
Feature: Offline Trip Queue & Persistence Synchronization (Refactored)
================================================================================

1. WHAT CHANGED STRUCTURALLY:
   We inverted the dependencies using domain-level repository interfaces:
   - `OfflineTripQueue`: Domain contract for local storage (enqueue, fetch, mark synced).
   - `RemoteTripSyncGateway`: Domain contract for transmitting trips to cloud servers.
   - `OfflineTripSyncCoordinator`: High-level sync policy that coordinates batching,
     validation, and reconciliation depending ONLY on these abstractions.
   - Low-level database adapters (`SqfliteTripQueueAdapter`, `HiveTripQueueAdapter`)
     and network gateways implement these contracts.

2. WHY THIS FIXES THE EXACT PROBLEM FROM PROBLEM 2:
   - The sync policy has zero references to SQL statements or HTTP headers.
   - Switching from SQLite to Hive or Isar means adding a new adapter class; the
     sync coordinator remains 100% untouched.
   - Unit testing the entire synchronization flow takes a fast, in-memory fake queue
     running in 5 milliseconds on any CI/CD pipeline.

3. WHY THIS IS PROPORTIONATE (NOT OVER-ENGINEERING):
   Offline-first reliability is the cornerstone of driver applications in emerging
   markets where 3G/4G connectivity is unstable. Decoupling storage and networking
   ensures trips and money are never lost due to storage engine refactoring.
================================================================================
*/

class QueuedTrip {
  final String tripId;
  final double fare;
  final DateTime completedAt;
  const QueuedTrip(this.tripId, this.fare, this.completedAt);
}

/// Domain Abstraction 1: Local persistence contract
abstract class OfflineTripQueue {
  Future<List<QueuedTrip>> fetchPendingTrips({int limit = 20});
  Future<void> markTripsSynced(List<String> tripIds);
}

/// Domain Abstraction 2: Remote dispatch gateway contract
abstract class RemoteTripSyncGateway {
  Future<bool> uploadBatch(List<QueuedTrip> trips);
}

/// High-Level Policy: Manages sync lifecycle, batching, and error policies.
class OfflineTripSyncCoordinator {
  final OfflineTripQueue _queue;
  final RemoteTripSyncGateway _remoteGateway;

  OfflineTripSyncCoordinator({
    required OfflineTripQueue queue,
    required RemoteTripSyncGateway remoteGateway,
  })  : _queue = queue,
        _remoteGateway = remoteGateway;

  Future<int> synchronizeOfflineTrips({int batchLimit = 20}) async {
    print('[SyncCoordinator] Checking for pending offline trips...');
    final pendingTrips = await _queue.fetchPendingTrips(limit: batchLimit);

    if (pendingTrips.isEmpty) {
      print('[SyncCoordinator] Offline queue is clean. Zero trips to sync.');
      return 0;
    }

    print('[SyncCoordinator] Found ${pendingTrips.length} offline trips. Uploading batch...');
    final isSuccess = await _remoteGateway.uploadBatch(pendingTrips);

    if (isSuccess) {
      final tripIds = pendingTrips.map((t) => t.tripId).toList();
      await _queue.markTripsSynced(tripIds);
      print('[SyncCoordinator] Batch upload confirmed. Marked ${tripIds.length} trips as synced.');
      return tripIds.length;
    } else {
      print('[SyncCoordinator] Remote sync failed. Trips kept in queue for next retry.');
      return 0;
    }
  }
}

/// Low-Level Adapter 1: SQLite implementation
class SqfliteTripQueueAdapter implements OfflineTripQueue {
  @override
  Future<List<QueuedTrip>> fetchPendingTrips({int limit = 20}) async {
    print('[SqfliteAdapter] Querying pending trips from table `queued_trips` (limit: $limit)...');
    return [
      QueuedTrip('trip_201', 18.25, DateTime.now().subtract(const Duration(minutes: 15))),
      QueuedTrip('trip_202', 22.00, DateTime.now().subtract(const Duration(minutes: 5))),
    ];
  }

  @override
  Future<void> markTripsSynced(List<String> tripIds) async {
    print('[SqfliteAdapter] Executing UPDATE queued_trips SET is_synced = 1 for IDs: $tripIds');
  }
}

/// Low-Level Adapter 2: Hive NoSQL implementation (Swappable with zero changes to coordinator!)
class HiveTripQueueAdapter implements OfflineTripQueue {
  @override
  Future<List<QueuedTrip>> fetchPendingTrips({int limit = 20}) async {
    print('[HiveAdapter] Reading pending trips from HiveBox<TripModel>...');
    return [];
  }

  @override
  Future<void> markTripsSynced(List<String> tripIds) async {
    print('[HiveAdapter] Updating Hive box keys: $tripIds');
  }
}

/// Low-Level Adapter 3: Remote REST / GraphQL Gateway
class HttpTripSyncGateway implements RemoteTripSyncGateway {
  @override
  Future<bool> uploadBatch(List<QueuedTrip> trips) async {
    print('[HttpGateway] Transmitted JSON payload with ${trips.length} trips to /v1/sync/trips.');
    return true; // HTTP 200 OK
  }
}
