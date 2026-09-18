// Part of solid_principles_demo by Ibrahim Abo El-Haggag

/*
================================================================================
OPEN/CLOSED PRINCIPLE (OCP) — SOLUTION 1
Feature: Driver Earnings Payout & Cashout Gateways (Refactored)
================================================================================

1. WHAT CHANGED STRUCTURALLY:
   Instead of a single class with a growing `switch` statement, we defined a polymorphic
   interface `PayoutGateway`. Each cashout provider (Bank, Debit Card, Mobile Wallet,
   and newly added InstaPay) is encapsulated in its own class implementing this interface.
   `PayoutService` now delegates directly to `PayoutGateway`.

2. WHY THIS FIXES THE EXACT PROBLEM FROM PROBLEM 1:
   - Adding a new payout channel (e.g. `InstaPayPayoutGateway`) requires creating exactly
     ONE new class.
   - Zero lines of existing payout code are touched or modified.
   - Bank transfer and debit card flows have ZERO regression risk when InstaPay is introduced.
   - Git merge conflicts between team members working on different payment gateways are eliminated.

3. WHY THIS IS PROPORTIONATE (NOT OVER-ENGINEERING):
   Payment integration is notorious for regional variations and vendor-specific APIs.
   Using polymorphism for payout channels keeps financial integrations modular, isolated,
   and independently unit-testable.
================================================================================
*/

/// Abstract contract open for extension, closed for modification.
abstract class PayoutGateway {
  String get id;
  String get displayName;
  double calculateFee(double amount);
  Future<bool> executeTransfer({
    required String driverId,
    required double amount,
    required String destinationAccount,
  });
}

/// Extension 1: Standard ACH Bank Transfer
class BankTransferPayoutGateway implements PayoutGateway {
  @override
  String get id => 'bank_transfer';

  @override
  String get displayName => 'Bank Account (ACH)';

  @override
  double calculateFee(double amount) => 1.50; // Flat fee

  @override
  Future<bool> executeTransfer({
    required String driverId,
    required double amount,
    required String destinationAccount,
  }) async {
    final fee = calculateFee(amount);
    final net = amount - fee;
    print('[BankTransferGateway] Transferring \$${net.toStringAsFixed(2)} to IBAN $destinationAccount. ETA: 2 days.');
    return true;
  }
}

/// Extension 2: Instant Visa Direct / Mastercard Send
class InstantCardPayoutGateway implements PayoutGateway {
  @override
  String get id => 'instant_card';

  @override
  String get displayName => 'Instant Debit Card';

  @override
  double calculateFee(double amount) => (amount * 0.015).clamp(0.50, 10.0);

  @override
  Future<bool> executeTransfer({
    required String driverId,
    required double amount,
    required String destinationAccount,
  }) async {
    final fee = calculateFee(amount);
    final net = amount - fee;
    print('[InstantCardGateway] Pushing \$${net.toStringAsFixed(2)} to card $destinationAccount. Instant delivery.');
    return true;
  }
}

/// Extension 3: Telecom Mobile Wallets (e.g. STC Pay / Vodafone Cash)
class MobileWalletPayoutGateway implements PayoutGateway {
  @override
  String get id => 'mobile_wallet';

  @override
  String get displayName => 'Mobile Wallet';

  @override
  double calculateFee(double amount) => 0.25;

  @override
  Future<bool> executeTransfer({
    required String driverId,
    required double amount,
    required String destinationAccount,
  }) async {
    final fee = calculateFee(amount);
    final net = amount - fee;
    print('[MobileWalletGateway] Dispatched \$${net.toStringAsFixed(2)} to wallet number $destinationAccount.');
    return true;
  }
}

/// Extension 4: Newly added gateway (InstaPay) added without editing a single line of existing gateways!
class InstaPayPayoutGateway implements PayoutGateway {
  @override
  String get id => 'instapay';

  @override
  String get displayName => 'InstaPay Instant Transfer';

  @override
  double calculateFee(double amount) => 0.0; // Zero fee promotion

  @override
  Future<bool> executeTransfer({
    required String driverId,
    required double amount,
    required String destinationAccount,
  }) async {
    print('[InstaPayGateway] Zero-fee instant transfer of \$${amount.toStringAsFixed(2)} to IPA $destinationAccount.');
    return true;
  }
}

/// The core payout processor service — completely CLOSED for modification.
class PayoutService {
  Future<bool> processPayout({
    required String driverId,
    required double amount,
    required String destinationAccount,
    required PayoutGateway gateway,
  }) async {
    print('[PayoutService] Initiating cashout via: ${gateway.displayName}');
    final fee = gateway.calculateFee(amount);
    if (amount <= fee) {
      print('[PayoutService] Error: Cashout amount \$${amount.toStringAsFixed(2)} is less than fee \$${fee.toStringAsFixed(2)}.');
      return false;
    }

    final success = await gateway.executeTransfer(
      driverId: driverId,
      amount: amount,
      destinationAccount: destinationAccount,
    );

    if (success) {
      print('[PayoutService] Cashout succeeded via ${gateway.displayName}.');
    }
    return success;
  }
}
