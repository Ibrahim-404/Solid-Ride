// Part of solid_principles_demo by Ibrahim Abo El-Haggag

/*
================================================================================
DEPENDENCY INVERSION PRINCIPLE (DIP) — PROBLEM 3
Feature: Driver Dispatch Push & High-Priority Audio Alerts
================================================================================

1. WHAT THIS CODE DOES:
   When an urgent high-value surge order is matched to a driver, the app alerts
   the driver via high-priority push notification and plays an attention-grabbing
   audio siren or chime so they do not miss the acceptance countdown window (15s).

2. WHY IT LOOKS FINE AT FIRST GLANCE:
   The coordinator class `DispatchAlertCoordinator` instantiates `FirebaseCloudMessagingPlugin`
   and `FlutterLocalNotificationsPlugin` directly. It's concise and follows standard
   introductory Flutter tutorials.

3. WHAT SPECIFIC PROBLEM IT CAUSES AS CODE GROWS:
   - When deploying to devices without Google Play Services (such as Huawei devices via
     AppGallery, or dedicated delivery handheld POS devices), Google FCM crashes.
   - You cannot unit-test the dispatch alert logic without native Android/iOS channels.
   - If the company switches from Firebase Cloud Messaging to OneSignal or Pusher,
     the high-level dispatch coordinator must be rewritten.
   - The coordinator mixes business escalation policies (e.g. surge importance threshold)
     with vendor-specific notification payload schemas.

4. WHICH SOLID PRINCIPLE IT VIOLATES & WHY:
   Violates the Dependency Inversion Principle (DIP).
   `DispatchAlertCoordinator` (high-level policy) directly depends on concrete, low-level
   platform plugins (`FirebaseCloudMessagingPlugin` and `FlutterLocalNotificationsPlugin`).
================================================================================
*/

/// Concrete Low-Level Detail 1: Google FCM Plugin
class FirebaseCloudMessagingPlugin {
  Future<void> sendHighPriorityPush({
    required String fcmToken,
    required String title,
    required String body,
    required Map<String, String> dataPayload,
  }) async {
    print('[FCM Plugin] Sending high-priority FCM notification to token $fcmToken: $title');
  }
}

/// Concrete Low-Level Detail 2: Native Audio/Notification Sound Plugin
class FlutterLocalNotificationsPlugin {
  Future<void> playCustomNotificationSound(String soundAsset) async {
    print('[LocalNotifications] Playing native audio asset: $soundAsset');
  }
}

/// VIOLATION: High-level dispatch coordinator coupled to concrete vendor SDKs!
class DispatchAlertCoordinator {
  // Hardcoded concrete vendor dependencies!
  final FirebaseCloudMessagingPlugin _fcm = FirebaseCloudMessagingPlugin();
  final FlutterLocalNotificationsPlugin _localAlerts = FlutterLocalNotificationsPlugin();

  Future<void> notifyDriverOfUrgentOrder({
    required String driverId,
    required String fcmToken,
    required String orderId,
    required double surgeMultiplier,
  }) async {
    print('[AlertCoordinator] Preparing alert for driver $driverId on order $orderId...');

    // Business rule: Only play loud sirens for high surge (> 1.5x)
    final isHighSurge = surgeMultiplier >= 1.5;

    // Direct coupling to Firebase FCM
    await _fcm.sendHighPriorityPush(
      fcmToken: fcmToken,
      title: 'New High Surge Order (${surgeMultiplier}x)!',
      body: 'Tap within 15 seconds to claim this trip.',
      dataPayload: {'order_id': orderId, 'type': 'URGENT_SURGE'},
    );

    // Direct coupling to native audio plugin
    if (isHighSurge) {
      await _localAlerts.playCustomNotificationSound('sounds/urgent_surge_alarm.wav');
    } else {
      await _localAlerts.playCustomNotificationSound('sounds/standard_chime.wav');
    }
  }
}
