// Part of solid_principles_demo by Ibrahim Abo El-Haggag

/*
================================================================================
OPEN/CLOSED PRINCIPLE (OCP) — PROBLEM 1
Feature: Driver Earnings Payout & Cashout Gateways
================================================================================

1. WHAT THIS CODE DOES:
   In a ride-hailing/delivery app, drivers can cash out their accumulated balance
   to their preferred payment channel: Bank Transfer (ACH), Instant Debit Card, or
   Mobile Wallet (STC Pay / Vodafone Cash). The `PayoutProcessor` checks the selected
   method via a `switch` statement, computes the method's fee, and sends the transfer.

   EXECUTION FLOW (RIGID SWITCH):
   Driver requests cashout
           ↓
   [PayoutProcessor]
           ↓
      switch (method) {
         case Bank:   ──> [Hardcoded Bank Logic]
         case Card:   ──> [Hardcoded Card Logic]
         case Wallet: ──> [Hardcoded Wallet Logic]
      }
   (Adding InstaPay = Modifying & risking all existing payout methods!)

2. WHY IT LOOKS FINE AT FIRST GLANCE:
   The code is clean, easy to read sequentially, and uses a standard Dart `enum`.
   For 2 or 3 payment options, a switch statement feels simple and direct.

3. WHAT SPECIFIC PROBLEM IT CAUSES AS CODE GROWS:
   - When the company expands to Egypt and needs to add "InstaPay", or to Kenya for
     "M-Pesa", or introduces "Crypto USDC Payouts", a developer MUST open and modify
     this existing `PayoutProcessor` class.
   - Editing the existing switch statement introduces regression risk: a typo or logic
     error in the new case can inadvertently alter fee calculations or break bank transfers.
   - In a busy team, multiple engineers adding regional payout methods will trigger Git
     merge conflicts on this same file.
   - You must re-test every existing payout method every time a single new one is added.

4. WHICH SOLID PRINCIPLE IT VIOLATES & WHY:
   Violates the Open/Closed Principle (OCP): "Software entities should be open for
   extension, but closed for modification."
   `PayoutProcessor` is NOT closed for modification. Every new payout channel forces us
   to modify existing, tested code rather than extending it by adding a new class.
================================================================================
*/

enum PayoutMethodType {
  bankTransfer,
  instantDebitCard,
  mobileWallet, // e.g. STC Pay / Vodafone Cash
}

class PayoutRequest {
  final String driverId;
  final double amount;
  final PayoutMethodType methodType;
  final String destinationAccount;

  const PayoutRequest({
    required this.driverId,
    required this.amount,
    required this.methodType,
    required this.destinationAccount,
  });
}

class PayoutProcessor {
  Future<bool> processPayout(PayoutRequest request) async {
    print('[PayoutProcessor] Processing payout of \$${request.amount} for driver ${request.driverId}');

    // VIOLATION: Giant switch statement that must be modified for every new payment method.
    switch (request.methodType) {
      case PayoutMethodType.bankTransfer:
        // Bank transfer: Flat fee $1.50, takes 2-3 business days
        const fee = 1.50;
        final netAmount = request.amount - fee;
        print('[BankTransfer] Routing \$${netAmount.toStringAsFixed(2)} (Fee: \$$fee) to IBAN ${request.destinationAccount}');
        print('[BankTransfer] ACH transfer initiated. ETA: 2 business days.');
        return true;

      case PayoutMethodType.instantDebitCard:
        // Instant Card: 1.5% fee (minimum $0.50), instant arrival
        final fee = (request.amount * 0.015).clamp(0.50, 10.0);
        final netAmount = request.amount - fee;
        print('[DebitCard] Pushing \$${netAmount.toStringAsFixed(2)} (Fee: \$$fee) to Card ending in ${request.destinationAccount}');
        print('[DebitCard] Visa Direct / Mastercard Send transfer complete.');
        return true;

      case PayoutMethodType.mobileWallet:
        // Mobile Wallet (STC Pay / Vodafone Cash): Flat $0.25 fee
        const fee = 0.25;
        final netAmount = request.amount - fee;
        print('[MobileWallet] Sending \$${netAmount.toStringAsFixed(2)} (Fee: \$$fee) to Phone Wallet ${request.destinationAccount}');
        print('[MobileWallet] Wallet API transfer complete.');
        return true;
    }
  }
}
