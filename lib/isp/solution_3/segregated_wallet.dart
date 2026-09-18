// Part of solid_principles_demo by Ibrahim Abo El-Haggag

/*
================================================================================
INTERFACE SEGREGATION PRINCIPLE (ISP) — SOLUTION 3
Feature: Driver Wallet & Financial Management Operations (Refactored)
================================================================================

1. WHAT CHANGED STRUCTURALLY:
   We separated queries from sensitive commands following Command-Query Segregation (CQS):
   - `WalletBalanceReader`: Read-only queries (fetch balance and transaction history).
   - `CashoutCommandService`: Sensitive transactional operations (instant cashout).
   - `BankAccountService`: Account linking and verification operations.
   - `DisputeService`: Dispute filing workflows.
   - The read-only header widget depends ONLY on `WalletBalanceReader`.

2. WHY THIS FIXES THE EXACT PROBLEM FROM PROBLEM 3:
   - Principle of Least Privilege: `CleanDriverHeaderBalanceWidget` cannot physically call
     cashout or bank account modification methods because they do not exist on its contract.
   - Unit tests for the balance header need only a stub returning a numerical balance.
   - Financial security audits can easily verify that display widgets have zero access
     to transfer execution APIs.

3. WHY THIS IS PROPORTIONATE (NOT OVER-ENGINEERING):
   Financial apps demand defense-in-depth. Restricting presentation widgets to read-only
   interfaces prevents accidental money transfers and simplifies authorization checks.
================================================================================
*/

class WalletTransaction {
  final String id;
  final double amount;
  final String description;
  const WalletTransaction(this.id, this.amount, this.description);
}

/// Segregated Interface 1: Read-only balance & transactions (Queries)
abstract class WalletBalanceReader {
  Future<double> getAvailableBalance();
  Future<List<WalletTransaction>> getRecentTransactions();
}

/// Segregated Interface 2: Financial cashout commands (Mutations)
abstract class CashoutCommandService {
  Future<bool> executeInstantCashout(double amount);
}

/// Segregated Interface 3: Bank account management
abstract class BankAccountService {
  Future<void> linkBankAccount({required String iban, required String bankName});
}

/// Segregated Interface 4: Financial dispute management
abstract class DisputeService {
  Future<void> disputeTripDeduction({required String tripId, required String explanation});
}

/// Clean Client 1: Read-only balance header widget
class CleanDriverHeaderBalanceWidget {
  final WalletBalanceReader _reader;

  CleanDriverHeaderBalanceWidget(this._reader);

  Future<void> renderBalance() async {
    final balance = await _reader.getAvailableBalance();
    print('[CleanHeaderWidget] Displaying top bar balance: \$${balance.toStringAsFixed(2)}');
    // Notice: It is impossible for this widget to accidentally call cashout!
  }
}

/// Clean Client 2: Dedicated cashout modal screen depends on CashoutCommandService
class CashoutModalDialog {
  final CashoutCommandService _cashoutService;

  CashoutModalDialog(this._cashoutService);

  Future<void> submitCashout(double amount) async {
    print('[CashoutDialog] Confirming cashout of \$${amount.toStringAsFixed(2)}...');
    final success = await _cashoutService.executeInstantCashout(amount);
    print('[CashoutDialog] Cashout result: $success');
  }
}

/// Combined Repository: Can implement multiple interfaces cleanly in the data layer.
class DriverWalletRepository implements WalletBalanceReader, CashoutCommandService {
  double _balance = 245.50;

  @override
  Future<double> getAvailableBalance() async => _balance;

  @override
  Future<List<WalletTransaction>> getRecentTransactions() async => [
        const WalletTransaction('tx-1', 18.50, 'Trip fare Downtown'),
        const WalletTransaction('tx-2', 5.00, 'Customer tip'),
      ];

  @override
  Future<bool> executeInstantCashout(double amount) async {
    if (amount <= _balance) {
      _balance -= amount;
      print('[WalletRepo] Instant cashout of \$$amount processed. Remaining: \$$_balance');
      return true;
    }
    return false;
  }
}
