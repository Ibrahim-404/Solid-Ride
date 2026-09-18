// Part of solid_principles_demo by Ibrahim Abo El-Haggag

/*
================================================================================
SINGLE RESPONSIBILITY PRINCIPLE (SRP) — PROBLEM 3
Feature: Shift Earnings Report & Driver Statement Generation
================================================================================

1. WHAT THIS CODE DOES:
   At the end of a shift or weekly cycle, a driver views their earnings breakdown:
   completed trips, tips, toll reimbursements, and platform commission. This class
   calculates the net earnings, formats the summary string with currency symbols and
   localized date stamps, generates a CSV export string, and sends an email/SMS receipt
   to the driver's registered phone number.

   EXECUTION FLOW (MONOLITHIC):
   Driver finishes shift
           ↓
   [ShiftEarningsReporter] (One Class)
      ├── 1. Accounting: Deducts commission & sums tips
      ├── 2. Localization: Formats currency (\$/EGP) & dates
      ├── 3. Exporter: Formats raw CSV text
      └── 4. Messenger: Sends email/SMS receipt
   (Mixed concerns: accounting, UI formatting, exports, and messaging)

2. WHY IT LOOKS FINE AT FIRST GLANCE:
   It keeps everything related to "Shift Earnings Report" in a single class called
   `ShiftEarningsReporter`. It feels organized because the class name matches the feature.

3. WHAT SPECIFIC PROBLEM IT CAUSES AS CODE GROWS:
   - If the accounting team updates the toll reimbursement policy or adds tax deductions,
     you must modify this file.
   - If UI designers want to support Arabic (EGP) localization or multi-currency formatting,
     you must modify this file.
   - If export format changes from CSV to PDF or Excel, you must modify this file.
   - If notifications switch from Twilio SMS to Firebase In-App Messaging or WhatsApp API,
     you must modify this file.
   Editing presentation, math, or transmission creates continuous regression risk across all three.

4. WHICH SOLID PRINCIPLE IT VIOLATES & WHY:
   Violates the Single Responsibility Principle (SRP).
   `ShiftEarningsReporter` changes for four completely different stakeholders:
   (1) Accountants (tax and commission math),
   (2) Localization/UI designers (currency symbols, date formats),
   (3) Reporting team (export file format),
   (4) Communications team (SMS/Email delivery providers).
================================================================================
*/

class ShiftRecord {
  final String driverId;
  final DateTime shiftDate;
  final int completedTripsCount;
  final double grossFares;
  final double tips;
  final double tollReimbursements;
  final double platformFeeRate; // e.g. 0.20 for 20%

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

class ShiftEarningsReporter {
  void processAndDispatchReport(ShiftRecord record, String driverEmail) {
    // 1. Math & accounting responsibility
    final platformCommission = record.grossFares * record.platformFeeRate;
    final netFares = record.grossFares - platformCommission;
    // Tips and tolls are 100% driver's, not subject to commission
    final netDriverPayout = netFares + record.tips + record.tollReimbursements;

    // 2. Presentation & localization responsibility
    final formattedDate = '${record.shiftDate.year}-${record.shiftDate.month.toString().padLeft(2, '0')}-${record.shiftDate.day.toString().padLeft(2, '0')}';
    final formattedNet = '\$${netDriverPayout.toStringAsFixed(2)}';
    final summaryText = '--- Shift Summary for Driver ${record.driverId} ($formattedDate) ---\n'
        'Completed Trips: ${record.completedTripsCount}\n'
        'Gross Fares: \$${record.grossFares.toStringAsFixed(2)}\n'
        'Commission: -\$${platformCommission.toStringAsFixed(2)}\n'
        'Tips: +\$${record.tips.toStringAsFixed(2)}\n'
        'Tolls: +\$${record.tollReimbursements.toStringAsFixed(2)}\n'
        'Total Net Payout: $formattedNet\n';

    print('[Presentation]\n$summaryText');

    // 3. File export responsibility (CSV format)
    final csvContent = 'Date,DriverId,Trips,Gross,Commission,Tips,Tolls,Net\n'
        '$formattedDate,${record.driverId},${record.completedTripsCount},'
        '${record.grossFares},$platformCommission,${record.tips},${record.tollReimbursements},'
        '$netDriverPayout';
    print('[CSV Export] Generated export file content:\n$csvContent');

    // 4. Communication & messaging responsibility
    print('[Email Service] Sending shift receipt to $driverEmail with body:\n$summaryText');
  }
}
