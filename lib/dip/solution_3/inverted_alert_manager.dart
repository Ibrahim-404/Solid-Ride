// Part of solid_principles_demo by Ibrahim Abo El-Haggag

/*
================================================================================
DEPENDENCY INVERSION PRINCIPLE (DIP) — SOLUTION 3
Feature: Driver Dispatch Push & High-Priority Audio Alerts (Refactored)
================================================================================

1. WHAT CHANGED STRUCTURALLY:
   We inverted dependencies by introducing two domain gateway abstractions:
   - `PushNotificationGateway`: Abstract contract for dispatching push messages.
   - `UrgentSoundAlertGateway`: Abstract contract for triggering device sirens/sounds.
   - `DispatchAlertCoordinator`: High-level business coordinator that depends ONLY
     on these interfaces (injected via constructor).
   - Concrete implementations (`FirebasePushGateway`, `HuaweiPushGateway`,
     `NativeDeviceAudioGateway`) implement these contracts.

   REFACTORED INVERTED GATEWAY FLOW:
   [DispatchAlertCoordinator] (High-Level Escalation Policy)
         │ (Depends strictly on domain abstractions)
         ▼
   [PushNotificationGateway]        [UrgentSoundAlertGateway]
         ▲                                    ▲
         │ (implemented by)                   │ (implemented by)
   [FirebasePush] / [HuaweiPush]    [NativeDeviceAudioGateway]
   (Multi-store support: Google Play vs Huawei works seamlessly!)

2. WHY THIS FIXES THE EXACT PROBLEM FROM PROBLEM 3:
   - Running in regions without Google Play Services (e.g. Huawei AppGallery) is solved
     by passing `HuaweiPushGateway`. The coordinator doesn't change a single line.
   - Switching to OneSignal, Pusher, or Twilio requires writing one new adapter class.
   - The coordinator can be thoroughly unit-tested in pure Dart in less than 10 milliseconds.

3. WHY THIS IS PROPORTIONATE (NOT OVER-ENGINEERING):
   Push notifications and audible alerts are the driver's lifeline to revenue. Decoupling
   them from platform-specific vendor SDKs makes multi-store distribution (Google Play,
   Apple App Store, Huawei AppGallery) seamless and crash-proof.
================================================================================
*/

/// Domain Abstraction 1: Push messaging contract
abstract class PushNotificationGateway {
  Future<void> sendUrgentPush({
    required String deviceToken,
    required String title,
    required String message,
    required Map<String, String> payload,
  });
}

/// Domain Abstraction 2: Device sound / chime alert contract
abstract class UrgentSoundAlertGateway {
  Future<void> playSurgeAlarm();
  Future<void> playStandardChime();
}

/// High-Level Coordinator: Depends ONLY on domain abstractions!
class DispatchAlertCoordinator {
  final PushNotificationGateway _pushGateway;
  final UrgentSoundAlertGateway _soundGateway;

  DispatchAlertCoordinator({
    required PushNotificationGateway pushGateway,
    required UrgentSoundAlertGateway soundGateway,
  })  : _pushGateway = pushGateway,
        _soundGateway = soundGateway;

  Future<void> notifyDriverOfUrgentOrder({
    required String driverId,
    required String deviceToken,
    required String orderId,
    required double surgeMultiplier,
  }) async {
    print('[AlertCoordinator] Preparing dispatch alert for driver: $driverId (Surge: ${surgeMultiplier}x)');

    // 1. Send push alert via abstraction
    await _pushGateway.sendUrgentPush(
      deviceToken: deviceToken,
      title: 'New High Surge Order (${surgeMultiplier}x)!',
      message: 'Tap within 15 seconds to claim this trip.',
      payload: {'order_id': orderId, 'surge': surgeMultiplier.toString()},
    );

    // 2. Play audible feedback based on business rule
    if (surgeMultiplier >= 1.5) {
      await _soundGateway.playSurgeAlarm();
    } else {
      await _soundGateway.playStandardChime();
    }
  }
}

/// Low-Level Adapter 1: Google FCM implementation
class FirebasePushGateway implements PushNotificationGateway {
  @override
  Future<void> sendUrgentPush({
    required String deviceToken,
    required String title,
    required String message,
    required Map<String, String> payload,
  }) async {
    print('[FirebaseFCM] Sent high-priority push to token: $deviceToken');
  }
}

/// Low-Level Adapter 2: Huawei Push Kit (Seamlessly swappable for non-Google devices!)
class HuaweiPushKitGateway implements PushNotificationGateway {
  @override
  Future<void> sendUrgentPush({
    required String deviceToken,
    required String title,
    required String message,
    required Map<String, String> payload,
  }) async {
    print('[HuaweiPushKit] Sent high-priority push via HMS Push Kit to: $deviceToken');
  }
}

/// Low-Level Adapter 3: Native device audio player implementation
class NativeDeviceAudioGateway implements UrgentSoundAlertGateway {
  @override
  Future<void> playSurgeAlarm() async {
    print('[NativeAudio] Playing urgent loud siren sound effect.');
  }

  @override
  Future<void> playStandardChime() async {
    print('[NativeAudio] Playing pleasant standard notification chime.');
  }
}
