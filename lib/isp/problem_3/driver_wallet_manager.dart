// Part of solid_principles_demo by Ibrahim Abo El-Haggag

/*
================================================================================
INTERFACE SEGREGATION PRINCIPLE (ISP) — PROBLEM 3
Feature: Driver Wallet & Financial Management Operations
================================================================================

1. WHAT THIS CODE DOES:
   The driver app includes an in-app wallet where drivers view earnings, review
   transaction history, cash out funds to their bank, link new payment methods,
   and dispute ride deductions (e.g. refunding an unjustified passenger cancellation).

2. WHY IT LOOKS FINE AT FIRST GLANCE:
   "It's all driver wallet functionality." A single `DriverWalletManager` interface
   containing all wallet queries and mutations seems logical to group together.

3. WHAT SPECIFIC PROBLEM IT CAUSES AS CODE GROWS:
   - A simple read-only dashboard header widget (`DriverHeaderBalanceWidget`) that
     only renders the driver's current balance is passed the entire `DriverWalletManager`.
   - Principle of Least Privilege is violated: a presentation widget has access to
     high-security financial mutations (`executeInstantCashout()`, `linkBankAccount()`).
   - A rogue or buggy UI callback in the header can trigger cashouts or mutate bank links.
   - Unit testing the header requires mocking banking connections and dispute workflows
     even though the widget only displays a dollar amount.

4. WHICH SOLID PRINCIPLE IT VIOLATES & WHY:
   Violates the Interface Segregation Principle (ISP): "Clients should not be forced
   to depend on interfaces they do not use."
   The read-only header widget is forced to depend on mutating financial commands
   that it has no business knowing about or invoking.
================================================================================
*/

class WalletTransaction {
  final String id;
  final double amount;
  final String description;
  const WalletTransaction(this.id, this.amount, this.description);
}

/// Monolithic "Fat" Interface combining read-only queries with sensitive financial mutations.
abstract class DriverWalletManager {
  // Read-only queries
  Future<double> getAvailableBalance();
  Future<List<WalletTransaction>> getRecentTransactions();

  // Sensitive transactional mutations
  Future<bool> executeInstantCashout(double amount);
  Future<void> linkBankAccount({required String iban, required String bankName});
  Future<void> disputeTripDeduction({required String tripId, required String explanation});
}

/// VIOLATION: A read-only UI header forced to depend on sensitive financial operations!
class DriverHeaderBalanceWidget {
  final DriverWalletManager _wallet;

  DriverHeaderBalanceWidget(this._wallet);

  Future<void> renderBalance() async {
    final balance = await _wallet.getAvailableBalance();
    print('[HeaderWidget] Rendering top bar balance: \$${balance.toStringAsFixed(2)}');

    // DANGEROUS ARCHITECTURAL LEAKAGE:
    // This simple read-only UI widget has access to execute real money transfers:
    // await _wallet.executeInstantCashout(100.0);
    // await _wallet.linkBankAccount(iban: '...', bankName: '...');
  }
}
