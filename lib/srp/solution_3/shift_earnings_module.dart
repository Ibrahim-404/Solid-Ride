// Part of solid_principles_demo by Ibrahim Abo El-Haggag

/*
================================================================================
SINGLE RESPONSIBILITY PRINCIPLE (SRP) — SOLUTION 3
Feature: Shift Earnings Report & Driver Statement Generation (Refactored)
================================================================================

1. WHAT CHANGED STRUCTURALLY:
   `ShiftEarningsReporter` was split into four single-responsibility collaborators:
   - `ShiftEarningsCalculator`: Calculates financial deductions, commissions, and net earnings.
   - `EarningsReportFormatter`: Formats data into readable, localized text for the driver's UI.
   - `EarningsCsvExporter`: Encapsulates CSV format generation for accounting exports.
   - `EarningsReceiptSender`: Handles sending statements via external communication channels.
   - `GenerateShiftReportUseCase`: Orchestrates the flow cleanly.

   REFACTORED CLEAN FLOW:
   Driver finishes shift
           ↓
   [GenerateShiftReportUseCase]
      ├── 1. [ShiftEarningsCalculator] ──> Pure financial arithmetic
      ├── 2. [EarningsReportFormatter] ──> UI localization & formatting
      ├── 3. [EarningsCsvExporter]     ──> Generates export file
      └── 4. [EarningsReceiptSender]   ──> Dispatches email/SMS
   (Each responsibility is isolated and independently testable)

2. WHY THIS FIXES THE EXACT PROBLEM FROM PROBLEM 3:
   - Adding a government withholding tax or changing toll policies touches ONLY
     `ShiftEarningsCalculator`.
   - Adding multi-currency support (SAR, EGP, AED, USD) or RTL formatting touches ONLY
     `EarningsReportFormatter`.
   - Switching export from CSV to PDF touches ONLY the exporter.
   - Switching messaging providers (SendGrid, Twilio, WhatsApp) touches ONLY `EarningsReceiptSender`.

3. WHY THIS IS PROPORTIONATE (NOT OVER-ENGINEERING):
   Financial statements in driver apps directly affect driver trust. Bugs in currency formatting
   or commission math can cause strikes or legal disputes. Isolating the calculation from
   the presentation and export mechanisms ensures high testability and rock-solid reliability.
================================================================================
*/

class ShiftRecord {
  final String driverId;
  final DateTime shiftDate;
  final int completedTripsCount;
  final double grossFares;
  final double tips;
  final double tollReimbursements;
  final double platformFeeRate;

  const ShiftRecord({
    required this.driverId,
    required this.shiftDate,
    required this.completedTripsCount,
    required this.grossFares,
    required this.tips,
    required this.tollReimbursements,
    this.platformFeeRate = 0.20,
  });
}

class CalculatedShiftEarnings {
  final double grossFares;
  final double commissionAmount;
  final double tips;
  final double tollReimbursements;
  final double netPayout;

  const CalculatedShiftEarnings({
    required this.grossFares,
    required this.commissionAmount,
    required this.tips,
    required this.tollReimbursements,
    required this.netPayout,
  });
}

/// Responsibility 1: Pure financial arithmetic.
class ShiftEarningsCalculator {
  CalculatedShiftEarnings calculate(ShiftRecord record) {
    final commission = record.grossFares * record.platformFeeRate;
    final netFares = record.grossFares - commission;
    final totalNet = netFares + record.tips + record.tollReimbursements;

    return CalculatedShiftEarnings(
      grossFares: record.grossFares,
      commissionAmount: commission,
      tips: record.tips,
      tollReimbursements: record.tollReimbursements,
      netPayout: totalNet,
    );
  }
}

/// Responsibility 2: Presentation and localization.
class EarningsReportFormatter {
  String formatSummary(ShiftRecord record, CalculatedShiftEarnings earnings, {String currency = '\$'}) {
    final dateStr = '${record.shiftDate.year}-${record.shiftDate.month.toString().padLeft(2, '0')}-${record.shiftDate.day.toString().padLeft(2, '0')}';
    return '--- Driver ${record.driverId} Statement ($dateStr) ---\n'
        'Completed Trips: ${record.completedTripsCount}\n'
        'Gross Fares: $currency${earnings.grossFares.toStringAsFixed(2)}\n'
        'Platform Fee: -$currency${earnings.commissionAmount.toStringAsFixed(2)}\n'
        'Tips: +$currency${earnings.tips.toStringAsFixed(2)}\n'
        'Toll Refunds: +$currency${earnings.tollReimbursements.toStringAsFixed(2)}\n'
        'Total Net Payout: $currency${earnings.netPayout.toStringAsFixed(2)}';
  }
}

/// Responsibility 3: Document export formatting (CSV).
class EarningsCsvExporter {
  String exportToCsv(ShiftRecord record, CalculatedShiftEarnings earnings) {
    final dateStr = '${record.shiftDate.year}-${record.shiftDate.month.toString().padLeft(2, '0')}-${record.shiftDate.day.toString().padLeft(2, '0')}';
    return 'Date,DriverId,Trips,Gross,Commission,Tips,Tolls,Net\n'
        '$dateStr,${record.driverId},${record.completedTripsCount},'
        '${earnings.grossFares},${earnings.commissionAmount},${earnings.tips},'
        '${earnings.tollReimbursements},${earnings.netPayout}';
  }
}

/// Responsibility 4: Communication and receipt dispatch.
class EarningsReceiptSender {
  Future<void> sendEmailReceipt({
    required String driverEmail,
    required String statementBody,
  }) async {
    print('[ReceiptSender] Dispatched email statement to $driverEmail.');
  }
}

/// Orchestrator: Coordinates the statement workflow.
class GenerateShiftReportUseCase {
  final ShiftEarningsCalculator _calculator;
  final EarningsReportFormatter _formatter;
  final EarningsCsvExporter _csvExporter;
  final EarningsReceiptSender _sender;

  GenerateShiftReportUseCase({
    required ShiftEarningsCalculator calculator,
    required EarningsReportFormatter formatter,
    required EarningsCsvExporter csvExporter,
    required EarningsReceiptSender sender,
  })  : _calculator = calculator,
        _formatter = formatter,
        _csvExporter = csvExporter,
        _sender = sender;

  Future<void> execute({
    required ShiftRecord record,
    required String driverEmail,
  }) async {
    final earnings = _calculator.calculate(record);
    final summary = _formatter.formatSummary(record, earnings);
    print(summary);

    final csv = _csvExporter.exportToCsv(record, earnings);
    print('[Exporter] Generated CSV:\n$csv');

    await _sender.sendEmailReceipt(driverEmail: driverEmail, statementBody: summary);
  }
}
