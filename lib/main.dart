// Part of solid_principles_demo by Ibrahim Abo El-Haggag

import 'package:flutter/material.dart';

// SRP Solutions
import 'srp/solution_1/accept_trip_use_case.dart' as srp1;
import 'srp/solution_2/driver_document_processor.dart' as srp2;
import 'srp/solution_3/shift_earnings_module.dart' as srp3;

// OCP Solutions
import 'ocp/solution_1/payout_gateway.dart' as ocp1;
import 'ocp/solution_2/fare_strategy.dart' as ocp2;
import 'ocp/solution_3/order_matching_rules.dart' as ocp3;

// LSP Solutions
import 'lsp/solution_1/vehicle_hierarchy.dart' as lsp1;
import 'lsp/solution_2/safe_cancellation_policy.dart' as lsp2;
import 'lsp/solution_3/safe_navigation_router.dart' as lsp3;

// ISP Solutions
import 'isp/solution_1/segregated_trip_listeners.dart' as isp1;
import 'isp/solution_2/segregated_telemetry.dart' as isp2;
import 'isp/solution_3/segregated_wallet.dart' as isp3;

// DIP Solutions
import 'dip/solution_1/inverted_tracking_service.dart' as dip1;
import 'dip/solution_2/inverted_trip_sync.dart' as dip2;
import 'dip/solution_3/inverted_alert_manager.dart' as dip3;

import 'dart:typed_data';

void main() {
  runApp(const SolidPrinciplesDemoApp());
}

class SolidPrinciplesDemoApp extends StatelessWidget {
  const SolidPrinciplesDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SOLID Principles Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F9D58),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F9D58),
          brightness: Brightness.dark,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<PrincipleData> _principles = [
    PrincipleData(
      key: 'srp',
      acronym: 'SRP',
      name: 'Single Responsibility',
      tagline: 'A class should have one, and only one, reason to change.',
      color: Colors.blue,
      icon: Icons.filter_1,
      pairs: [
        PairScenario(
          title: 'Trip Dispatch & Order Acceptance',
          context: 'Driver taps "Accept Order" on incoming dispatch screen.',
          problemSummary:
              'Monolithic TripAcceptanceService handled local SQLite DB, backend HTTP API, surge payout math, Firebase analytics, and phone audio/vibrations in one 90-line class.',
          problemBreaks:
              'Changing finance commission rules or switching analytics from Firebase to Mixpanel forces modifying core trip dispatch code, risking high-frequency regressions.',
          problemFlow: '''Driver presses "Accept"
        ↓
[TripAcceptanceService] (One Monolithic Class)
   ├── 1. SQLite: Saves trip state
   ├── 2. HTTP POST: Notifies backend dispatch
   ├── 3. Math: Calculates surge & commission
   ├── 4. Analytics: Logs Firebase event
   └── 5. Hardware: Plays chime & triggers haptic
(5 reasons to change - fragile & risky!)''',
          solutionSummary:
              'Separated into TripRepository, TripPayoutCalculator, TripAnalyticsTracker, and TripAlertService, orchestrated cleanly by AcceptTripUseCase.',
          solutionFixes:
              'Finance rules, analytics vendors, and audio chimes are each 100% isolated. Zero merge conflicts and pure, millisecond unit testing for financial formulas.',
          solutionFlow: '''Driver presses "Accept"
        ↓
[AcceptTripUseCase] (Orchestrator)
   ├── 1. [TripPayoutCalculator] ──> Calculates net payout
   ├── 2. [TripRepository]       ──> SQLite + Backend API
   ├── 3. [TripAnalyticsTracker] ──> Emits analytics event
   └── 4. [TripAlertService]     ──> Plays sound & haptics
(Each class has 1 reason to change; 100% testable)''',
          onRunSolution: () async {
            final repo = srp1.TripRepository();
            final calc = srp1.TripPayoutCalculator();
            final analytics = srp1.TripAnalyticsTracker();
            final alert = srp1.TripAlertService();
            final useCase = srp1.AcceptTripUseCase(
              repository: repo,
              calculator: calc,
              analytics: analytics,
              alertService: alert,
            );
            const trip = srp1.DriverTrip(
              tripId: 'TRIP-789',
              passengerName: 'Kareem T.',
              pickupAddress: 'Tahrir Square',
              destinationAddress: 'Cairo Festival City',
              baseFare: 65.0,
              surgeMultiplier: 1.4,
            );
            final payout = await useCase.execute(trip: trip, driverId: 'DRV-404');
            return 'Accepted trip TRIP-789!\n'
                'Gross Fare: \$${payout.grossFare.toStringAsFixed(2)}\n'
                'Platform Fee: -\$${payout.platformCommission.toStringAsFixed(2)}\n'
                'Net Driver Earnings: \$${payout.netDriverEarnings.toStringAsFixed(2)}';
          },
        ),
        PairScenario(
          title: 'Driver Document Onboarding',
          context: 'Driver uploads license & vehicle registration for verification.',
          problemSummary:
              'DriverDocumentService handled image byte compression, OCR text extraction, AWS S3 upload, and license expiration validation rules all together.',
          problemBreaks:
              'Tuning compression quality, switching from AWS to Cloudflare R2, or updating legal expiry thresholds required touching the same monolithic file.',
          problemFlow: '''Driver uploads Document Photo
        ↓
[DriverDocumentService] (All-in-One Class)
   ├── 1. Image Compression (Resizes raw bytes)
   ├── 2. OCR Engine (Extracts ID & expiry dates)
   ├── 3. Compliance Rules (Rejects if < 30 days valid)
   ├── 4. Cloud Storage (Uploads bytes to AWS S3)
   └── 5. Database Profile (Marks status = VERIFIED)''',
          solutionSummary:
              'Decomposed into DocumentImageCompressor, DocumentOcrParser, DocumentComplianceValidator, DocumentCloudStorage, and DriverProfileRepository.',
          solutionFixes:
              'Legal compliance validation rules can now be tested in unit tests with zero mocking of camera bytes or cloud credentials.',
          solutionFlow: '''Driver uploads Document Photo
        ↓
[DriverDocumentProcessor] (Pipeline Orchestrator)
   ├── 1. [DocumentImageCompressor]     ──> WebP optimization
   ├── 2. [DocumentOcrParser]           ──> OCR text extraction
   ├── 3. [DocumentComplianceValidator] ──> Expiry rule checks
   ├── 4. [DocumentCloudStorage]        ──> S3 / GCS upload
   └── 5. [DriverProfileRepository]     ──> Updates database''',
          onRunSolution: () async {
            final processor = srp2.DriverDocumentProcessor(
              compressor: srp2.DocumentImageCompressor(),
              ocrParser: srp2.DocumentOcrParser(),
              validator: srp2.DocumentComplianceValidator(),
              storage: srp2.DocumentCloudStorage(),
              profileRepo: srp2.DriverProfileRepository(),
            );
            final submission = srp2.DocumentSubmission(
              documentType: 'DRIVING_LICENSE',
              rawImageBytes: Uint8List.fromList([1, 2, 3, 4]),
              driverId: 'DRV-404',
            );
            final result = await processor.processSubmission(submission);
            return result
                ? 'Document verified and approved successfully!'
                : 'Document validation rejected.';
          },
        ),
        PairScenario(
          title: 'Shift Earnings Statement',
          context: 'Driver completes a 10-hour shift and requests statement.',
          problemSummary:
              'ShiftEarningsReporter computed net accounting math, formatted localized text, built CSV files, and sent email receipts in one method.',
          problemBreaks:
              'Changing tax withholding or adding multi-currency (EGP/SAR) formatting risked breaking accounting calculations or CSV export syntax.',
          problemFlow: '''Driver finishes shift
        ↓
[ShiftEarningsReporter] (One Class)
   ├── 1. Accounting: Deducts commission & sums tips
   ├── 2. Localization: Formats currency (\$/EGP) & dates
   ├── 3. Exporter: Formats raw CSV text
   └── 4. Messenger: Sends email/SMS receipt''',
          solutionSummary:
              'Segregated into ShiftEarningsCalculator, EarningsReportFormatter, EarningsCsvExporter, and EarningsReceiptSender.',
          solutionFixes:
              'Accounting arithmetic is decoupled from string formatting and communication transports.',
          solutionFlow: '''Driver finishes shift
        ↓
[GenerateShiftReportUseCase]
   ├── 1. [ShiftEarningsCalculator] ──> Pure financial arithmetic
   ├── 2. [EarningsReportFormatter] ──> UI localization & formatting
   ├── 3. [EarningsCsvExporter]     ──> Generates export file
   └── 4. [EarningsReceiptSender]   ──> Dispatches email/SMS''',
          onRunSolution: () async {
            final useCase = srp3.GenerateShiftReportUseCase(
              calculator: srp3.ShiftEarningsCalculator(),
              formatter: srp3.EarningsReportFormatter(),
              csvExporter: srp3.EarningsCsvExporter(),
              sender: srp3.EarningsReceiptSender(),
            );
            final record = srp3.ShiftRecord(
              driverId: 'DRV-404',
              shiftDate: DateTime.now(),
              completedTripsCount: 14,
              grossFares: 180.0,
              tips: 35.0,
              tollReimbursements: 12.0,
            );
            await useCase.execute(record: record, driverEmail: 'driver@solid.com');
            return 'Shift statement generated, formatted, and emailed successfully!';
          },
        ),
      ],
    ),
    PrincipleData(
      key: 'ocp',
      acronym: 'OCP',
      name: 'Open/Closed',
      tagline: 'Open for extension, closed for modification.',
      color: Colors.green,
      icon: Icons.filter_2,
      pairs: [
        PairScenario(
          title: 'Driver Payout & Cashout Gateways',
          context: 'Driver cashes out weekly earnings to preferred account.',
          problemSummary:
              'PayoutProcessor used a rigid switch statement for Bank Transfer, Debit Card, and Mobile Wallet with hardcoded fees and network calls.',
          problemBreaks:
              'Adding InstaPay or M-Pesa required modifying existing switch cases, risking breaking bank transfer fee math and causing merge conflicts.',
          problemFlow: '''Driver requests cashout
        ↓
[PayoutProcessor]
        ↓
   switch (method) {
      case Bank:   ──> [Hardcoded Bank Logic]
      case Card:   ──> [Hardcoded Card Logic]
      case Wallet: ──> [Hardcoded Wallet Logic]
   }
(Adding InstaPay = Modifying & risking all existing cases!)''',
          solutionSummary:
              'Polymorphic PayoutGateway interface with self-contained gateway classes (BankTransfer, InstantCard, MobileWallet, InstaPay).',
          solutionFixes:
              'New payout methods are added simply by creating a new class. PayoutService is 100% closed for modification.',
          solutionFlow: '''Driver requests cashout
        ↓
[PayoutService] (CLOSED for modification)
        ↓ delegates to
[PayoutGateway] (OPEN for extension)
      ▲
      ├── [BankTransferPayoutGateway]
      ├── [InstantCardPayoutGateway]
      ├── [MobileWalletPayoutGateway]
      └── [InstaPayPayoutGateway] (Added with ZERO edits!)''',
          onRunSolution: () async {
            final service = ocp1.PayoutService();
            final gateway = ocp1.InstaPayPayoutGateway();
            final success = await service.processPayout(
              driverId: 'DRV-404',
              amount: 150.0,
              destinationAccount: 'user@instapay',
              gateway: gateway,
            );
            return success
                ? 'Processed \$150 cashout via ${gateway.displayName} without touching existing gateways!'
                : 'Payout failed.';
          },
        ),
        PairScenario(
          title: 'Vehicle Type Fare Calculation',
          context: 'Computing fare based on vehicle tier (Economy, Comfort, Motorcycle).',
          problemSummary:
              'FareCalculator branched over VehicleCategory with hardcoded base fares, per-km rates, and minimum fees in one function.',
          problemBreaks:
              'Adding Electric Scooter or Cargo Van required editing the existing calculator and risked fat-fingering rates for passenger cars.',
          problemFlow: '''Calculate trip fare
        ↓
[TripFareCalculator]
        ↓
   switch (vehicleCategory) {
      case Economy:    ──> [Hardcoded Economy pricing]
      case Comfort:    ──> [Hardcoded Comfort pricing]
      case Motorcycle: ──> [Hardcoded Courier pricing]
   }
(Adding Electric Scooter = Modifying core calculator)''',
          solutionSummary:
              'Strategy Pattern: VehicleFareStrategy interface with dedicated strategies for Economy, Comfort, Motorcycle, and ElectricScooter.',
          solutionFixes:
              'Each vehicle tier encapsulates its own rates and minimum thresholds. Adding tiers touches zero existing lines.',
          solutionFlow: '''Calculate trip fare
        ↓
[FareCalculationService] (CLOSED for modification)
        ↓ executes
[VehicleFareStrategy] (OPEN for extension)
      ▲
      ├── [EconomyFareStrategy]
      ├── [ComfortFareStrategy]
      ├── [MotorcycleFareStrategy]
      └── [ElectricScooterFareStrategy] (Added with 0 edits!)''',
          onRunSolution: () async {
            final service = ocp2.FareCalculationService();
            final scooterStrategy = ocp2.ElectricScooterFareStrategy();
            final fare = service.calculate(
              strategy: scooterStrategy,
              distanceKm: 4.5,
              durationMinutes: 15,
              surgeMultiplier: 1.2,
            );
            return 'Calculated ${scooterStrategy.categoryName} Fare: \$${fare.toStringAsFixed(2)}';
          },
        ),
        PairScenario(
          title: 'Order Dispatch Matching Rules',
          context: 'Filtering orders before offering them to nearby drivers.',
          problemSummary:
              'OrderMatchingEngine chained if conditions for Cash-on-Delivery, driver ratings, package weight, and high-value insurance.',
          problemBreaks:
              'Adding Low-Emission Zone rules or VIP driver requirements meant continually bloating the engine with more nested conditions.',
          problemFlow: '''Incoming order offer
        ↓
[OrderMatchingEngine]
   ├── if (!driver.hasCash && order.isCash) return false;
   ├── if (driver.rating < order.minRating) return false;
   ├── if (order.weight > driver.maxWeight) return false;
   └── if (order.isHighValue && !driver.insured) return false;
(Adding Low Emission rule = Bloating engine method)''',
          solutionSummary:
              'Specification / Rule Pipeline: OrderMatchingRule interface with modular rules executed sequentially by OrderMatchingPipeline.',
          solutionFixes:
              'New operational or municipal constraints are added as standalone rules without editing the matching engine.',
          solutionFlow: '''Incoming order offer
        ↓
[OrderMatchingPipeline] (CLOSED for modification)
        ↓ evaluates rule set
[OrderMatchingRule] (OPEN for extension)
      ▲
      ├── [CashOnDeliveryRule]
      ├── [RatingThresholdRule]
      ├── [WeightCapacityRule]
      └── [LowEmissionZoneRule] (Plug in new rule effortlessly)''',
          onRunSolution: () async {
            final pipeline = ocp3.OrderMatchingPipeline([
              ocp3.CashOnDeliveryRule(),
              ocp3.RatingThresholdRule(),
              ocp3.WeightCapacityRule(),
              ocp3.LowEmissionZoneRule(),
            ]);
            const driver = ocp3.DriverProfile(
              driverId: 'DRV-404',
              rating: 4.9,
              hasCashCollectionEnabled: true,
              maxPayloadCapacityKg: 20.0,
              isInsuredForHighValue: true,
              isElectricVehicle: true,
            );
            const order = ocp3.DeliveryOrder(
              orderId: 'ORD-991',
              isCashOnDelivery: true,
              minRatingRequired: 4.7,
              packageWeightKg: 8.5,
              isHighValue: false,
              requiresLowEmissionVehicle: true,
            );
            final eligible = pipeline.evaluateDriver(driver: driver, order: order);
            return eligible
                ? 'Driver DRV-404 passed all 4 modular dispatch rules!'
                : 'Driver rejected by dispatch rule.';
          },
        ),
      ],
    ),
    PrincipleData(
      key: 'lsp',
      acronym: 'LSP',
      name: 'Liskov Substitution',
      tagline: 'Subtypes must be substitutable for base types without altering correctness.',
      color: Colors.orange,
      icon: Icons.filter_3,
      pairs: [
        PairScenario(
          title: 'Fleet Vehicle Hierarchy',
          context: 'Managing passenger cars and courier two-wheelers in a single fleet.',
          problemSummary:
              'Base Vehicle class declared turnOnAirConditioning() and lockDoors(). BicycleCourier inherited it and threw UnsupportedError at runtime.',
          problemBreaks:
              'The passenger dispatch loop crashed with unhandled exceptions when preparing rides, forcing developers to write dirty type checks.',
          problemFlow: '''Passenger Dispatch Coordinator
        ↓
Loops through: List<Vehicle>
   ├── Car  ──> vehicle.turnOnAirConditioning() ──> OK
   └── Bike ──> vehicle.turnOnAirConditioning() ──> CRASH!
(UnsupportedError: Bicycles have no AC or doors!)''',
          solutionSummary:
              'Sound hierarchy: Vehicle (general), PassengerVehicle (climate control, doors, seats), and CargoCourierVehicle (cargo volume).',
          solutionFixes:
              'PassengerDispatchCoordinator strictly accepts PassengerVehicle. Any subtype (Sedan, Luxury SUV) is 100% substitutable with zero crashes.',
          solutionFlow: '''Passenger Dispatch Coordinator
        ↓
Accepts ONLY: List<PassengerVehicle>
   ├── SedanCar  ──> car.turnOnClimateControl() ──> OK
   └── LuxurySuv ──> car.turnOnClimateControl() ──> OK
(BicycleCourier inherits from CargoCourierVehicle; 100% safe)''',
          onRunSolution: () async {
            final coordinator = lsp1.PassengerDispatchCoordinator();
            final fleet = <lsp1.PassengerVehicle>[
              lsp1.SedanRideCar(
                vehicleId: 'CAR-01',
                driverId: 'DRV-1',
                location: const lsp1.GeoLocation(30.04, 31.23),
              ),
              lsp1.LuxurySuvCar(
                vehicleId: 'CAR-02',
                driverId: 'DRV-2',
                location: const lsp1.GeoLocation(30.05, 31.24),
              ),
            ];
            coordinator.prepareFleetForPassengerRide(fleet);
            return 'Prepared ${fleet.length} passenger vehicles safely. Zero runtime exceptions!';
          },
        ),
        PairScenario(
          title: 'Trip Cancellation Invariants',
          context: 'Evaluating cancellation fee when a rider or driver cancels.',
          problemSummary:
              'Subclass NonCancellableGovPromoPolicy threw unexpected StateError inside calculateCancellationFee, crashing the UI cancellation sheet.',
          problemBreaks:
              'Callers expected a safe non-negative fee query. The subclass violated preconditions and postconditions, crashing the active trip session.',
          problemFlow: '''Rider / Driver cancels trip
        ↓
[CancellationCoordinator]
        ↓
policy.calculateCancellationFee()
   ├── StandardPolicy ──> Returns \$5.00
   └── GovPromoPolicy ──> CRASH! Throws StateError
(Subtype breaks contract by throwing surprise error!)''',
          solutionSummary:
              'CancellationResult result object encapsulating isPermitted, feeCharged, and user explanation without throwing exceptions.',
          solutionFixes:
              'All cancellation policy subtypes honor the base contract. The UI handles non-cancellable promos gracefully without try/catch guards.',
          solutionFlow: '''Rider / Driver cancels trip
        ↓
[SafeCancellationCoordinator]
        ↓
policy.evaluateCancellation()
   ├── StandardPolicy ──> CancellationResult.allowed(fee: \$5.00)
   └── GovPromoPolicy ──> CancellationResult.denied(reason: "Contact Support")
(All subtypes return safe result; zero unexpected crashes)''',
          onRunSolution: () async {
            final coordinator = lsp2.SafeCancellationCoordinator(
              lsp2.GovSubsidizedCancellationPolicy(),
            );
            const trip = lsp2.TripOrder(
              tripId: 'TRIP-303',
              baseFare: 40.0,
              driverId: 'DRV-404',
              riderId: 'RDR-12',
            );
            coordinator.processCancellation(trip, 5);
            return 'Evaluated government subsidized trip cancellation. Returned friendly explanation with zero crashes!';
          },
        ),
        PairScenario(
          title: 'Turn-by-Turn Navigation Routing',
          context: 'Calculating route maneuvers for cars, motorbikes, and walking couriers.',
          problemSummary:
              'PedestrianCourierRouter threw UnsupportedError on highway destinations and returned empty turn directions, crashing the HUD widget.',
          problemBreaks:
              'The turn-by-turn widget crashed reading route.turnDirections.first, forcing developers to write "if (router is PedestrianRouter)".',
          problemFlow: '''Turn-by-turn Navigation HUD
        ↓
router.calculateRoute()
   ├── CarRouter        ──> Returns route with turn maneuvers
   └── PedestrianRouter ──> Throws UnsupportedError OR returns []
                            └──> CRASH on route.turnDirections.first''',
          solutionSummary:
              'NavigationRouter returns RouteResult guaranteeing non-empty maneuvers on success, and clean domain failures for infeasible routes.',
          solutionFixes:
              'Car, Motorcycle, and Walking routers are 100% substitutable. The HUD controller operates without type-checking or crashing.',
          solutionFlow: '''Turn-by-turn Navigation HUD
        ↓
router.calculateRoute()
   ├── CarRouter        ──> RouteResult.success(routeWithSteps)
   ├── MotorbikeRouter  ──> RouteResult.success(routeWithShortcuts)
   └── PedestrianRouter ──> RouteResult.failure("Exceeds walking distance")
(HUD handles all routers uniformly without type checks)''',
          onRunSolution: () async {
            final controller = lsp3.SafeNavigationHudController(
              lsp3.MotorcycleNavigationRouter(),
            );
            await controller.launchRoute(
              const lsp3.GeoPoint(30.04, 31.23),
              const lsp3.GeoPoint(30.08, 31.28),
            );
            return 'Route calculated and launched successfully using motorcycle courier shortcuts!';
          },
        ),
      ],
    ),
    PrincipleData(
      key: 'isp',
      acronym: 'ISP',
      name: 'Interface Segregation',
      tagline: 'Clients should not be forced to depend on interfaces they do not use.',
      color: Colors.purple,
      icon: Icons.filter_4,
      pairs: [
        PairScenario(
          title: 'Trip Lifecycle Event Listeners',
          context: 'Handling driver app events during active rides and deliveries.',
          problemSummary:
              'Giant DriverTripEventListener forced food delivery widgets to implement empty or throwing stubs for passenger boarding and toll payments.',
          problemBreaks:
              'Adding a new method like onChildSeatInspected() broke every food courier listener in the app and caused build failures.',
          problemFlow: '''[DriverTripEventListener] (FAT Interface: 7 methods)
      ▲
      ├── FoodDeliveryWidget (Only needs foodPickedUp & signature)
      │     ├── onFoodPickedUp() ──────────> Uses this
      │     ├── onPassengerBoarded() ──────> Forced empty stub / error!
      │     ├── onLuggageLoaded() ─────────> Forced empty stub / error!
      │     └── onTollPaid() ──────────────> Forced empty stub!
(Adding onChildSeat() breaks all food widgets in the app!)''',
          solutionSummary:
              'Segregated into TripOfferListener, PassengerRideListener, FoodDeliveryListener, and TollExpenseListener.',
          solutionFixes:
              'CleanFoodDeliveryTrackingWidget implements ONLY FoodDeliveryListener. Zero boilerplate stubs, zero broken builds when taxi listeners change.',
          solutionFlow: '''Role-Specific Segregated Interfaces:
   ├── [PassengerRideListener]  ── implemented by ──> TaxiRideScreen
   ├── [FoodDeliveryListener]   ── implemented by ──> FoodDeliveryWidget
   └── [TollExpenseListener]    ── implemented by ──> TollPaymentCard
(Food widget implements ONLY what it needs. Zero dummy stubs!)''',
          onRunSolution: () async {
            final foodWidget = isp1.CleanFoodDeliveryTrackingWidget('ORD-555');
            foodWidget.onFoodPackagePickedUp('ORD-555', 'Burger King Zamalek');
            foodWidget.onCustomerSignatureCollected('data:image/svg+xml;...');
            return 'Food delivery widget handled relevant events with ZERO passenger stubs!';
          },
        ),
        PairScenario(
          title: 'Device Hardware & Telemetry',
          context: 'Accessing GPS stream, battery level, crash sensor, and Bluetooth taximeter.',
          problemSummary:
              'DriverDeviceTelemetry combined GPS, battery, accelerometer, and Bluetooth meters. Map widget had to depend on the entire sensor suite.',
          problemBreaks:
              'Testing the map required mocking Bluetooth taximeters and crash sensors. Hardware protocol changes forced re-testing UI screens.',
          problemFlow: '''[DriverDeviceTelemetry] (GPS + Battery + Crash Sensors + Bluetooth Taximeter)
      ▲
      └── DriverMapWidget (Only needs GPS location to move pin!)
            (Coupled to taximeters & crash sensors; hard to test)''',
          solutionSummary:
              'Segregated into LocationProvider, BatteryMonitor, CrashDetectionSensor, and TaximeterIntegration.',
          solutionFixes:
              'Map widget depends strictly on LocationProvider. Widget tests take 3 lines to mock with zero hardware coupling.',
          solutionFlow: '''Segregated Interfaces:
   ├── [LocationProvider]     ── used by ──> DriverMapWidget (Clean & focused)
   ├── [BatteryMonitor]       ── used by ──> BatteryStatusBanner
   └── [TaximeterIntegration] ── used by ──> BluetoothMeterSyncService''',
          onRunSolution: () async {
            final hardware = isp2.PhoneHardwareManager();
            final mapWidget = isp2.CleanDriverMapTrackingWidget(hardware);
            mapWidget.renderDriverMarkerOnMap();
            return 'Map tracking widget subscribed strictly to LocationProvider. Zero exposure to taximeter or crash sensors!';
          },
        ),
        PairScenario(
          title: 'Driver Wallet & Financial Operations',
          context: 'Viewing balance on home screen vs executing cashouts.',
          problemSummary:
              'DriverWalletManager gave read-only balance header widget access to executeInstantCashout() and linkBankAccount().',
          problemBreaks:
              'Principle of Least Privilege violated: a presentation header had full capability to trigger real financial wire transfers.',
          problemFlow: '''[DriverWalletManager] (Balance Query + Instant Cashout + Link Bank Account)
      ▲
      └── DriverHeaderBalanceWidget (Display ONLY)
            (Security risk: simple UI display can trigger cashouts!)''',
          solutionSummary:
              'Separated into WalletBalanceReader (queries) and CashoutCommandService / BankAccountService (mutating commands).',
          solutionFixes:
              'Header widget only accepts WalletBalanceReader. Impossible for accidental UI clicks to initiate money transfers.',
          solutionFlow: '''Segregated Contracts (Command-Query Segregation):
   ├── [WalletBalanceReader]   ── used by ──> DriverHeaderBalanceWidget (Read-only)
   └── [CashoutCommandService] ── used by ──> CashoutModalDialog (Secure mutation)''',
          onRunSolution: () async {
            final repo = isp3.DriverWalletRepository();
            final header = isp3.CleanDriverHeaderBalanceWidget(repo);
            await header.renderBalance();
            return 'Rendered top bar balance safely. Mutating cashout operations are physically inaccessible to the header!';
          },
        ),
      ],
    ),
    PrincipleData(
      key: 'dip',
      acronym: 'DIP',
      name: 'Dependency Inversion',
      tagline: 'High-level modules should depend on abstractions, not concrete details.',
      color: Colors.teal,
      icon: Icons.filter_5,
      pairs: [
        PairScenario(
          title: 'Live Trip Tracking & Cloud Publisher',
          context: 'Broadcasting driver GPS position to passengers and dispatchers.',
          problemSummary:
              'DriverLiveTrackingUseCase instantiated concrete GeolocatorPlugin and FirebaseRealtimeDatabase inside its constructor.',
          problemBreaks:
              'Business tracking logic could not be unit tested without native GPS hardware and live Firebase servers. Migrating to MQTT was blocked.',
          problemFlow: '''[DriverLiveTrackingUseCase] (High-Level Business Logic)
      │ (Directly instantiates concrete low-level SDKs)
      ├── new GeolocatorDevicePlugin()
      └── new FirebaseRealtimeDatabase()
(Cannot unit test without hardware & cloud; locked to Firebase)''',
          solutionSummary:
              'Use case depends on LocationStreamSource and LiveLocationPublisher abstractions. Concrete adapters are injected.',
          solutionFixes:
              'Unit testing takes 5ms with fake stream sources. Switching to MQTT or Supabase requires 1 new adapter with zero use case changes.',
          solutionFlow: '''[DriverLiveTrackingUseCase] (High-Level Business Logic)
      │ (Depends strictly on domain abstractions)
      ▼
[LocationStreamSource]           [LiveLocationPublisher]
      ▲                                    ▲
      │ (implemented by)                   │ (implemented by)
[DeviceGpsLocationSource]        [FirebasePublisher] / [MqttPublisher]''',
          onRunSolution: () async {
            final useCase = dip1.DriverLiveTrackingUseCase(
              driverId: 'DRV-404',
              locationSource: dip1.DeviceGpsLocationSource(),
              locationPublisher: dip1.MqttLocationPublisher(),
            );
            useCase.startTrackingSession();
            return 'Live tracking session launched using swappable MQTT publisher via abstraction!';
          },
        ),
        PairScenario(
          title: 'Offline Trip Queue Synchronization',
          context: 'Queuing trips offline in tunnels/garages and syncing when reconnected.',
          problemSummary:
              'OfflineTripSyncCoordinator directly imported and called SqfliteDatabase.instance and DioHttpClient in its sync method.',
          problemBreaks:
              'Sync policy was tightly bound to raw SQL strings and Dio headers. Upgrading SQLite to Hive or Isar required rewriting sync logic.',
          problemFlow: '''[OfflineTripSyncCoordinator] (High-Level Sync Policy)
      │ (Directly coupled to concrete storage & network)
      ├── SqfliteLocalDatabase.instance (Raw SQL queries)
      └── DioHttpClient() (Raw HTTP calls)
(Migrating SQLite to Hive requires rewriting the entire sync policy!)''',
          solutionSummary:
              'Coordinator depends on OfflineTripQueue and RemoteTripSyncGateway interfaces. Storage and HTTP clients are decoupled adapters.',
          solutionFixes:
              'Sync retry rules, batching, and error policies are completely storage-agnostic and unit-testable in pure Dart.',
          solutionFlow: '''[OfflineTripSyncCoordinator] (High-Level Sync Policy)
      │ (Depends strictly on abstractions)
      ▼
[OfflineTripQueue]               [RemoteTripSyncGateway]
      ▲                                    ▲
      │ (implemented by)                   │ (implemented by)
[SqfliteAdapter] / [HiveAdapter]     [HttpTripSyncGateway]''',
          onRunSolution: () async {
            final coordinator = dip2.OfflineTripSyncCoordinator(
              queue: dip2.SqfliteTripQueueAdapter(),
              remoteGateway: dip2.HttpTripSyncGateway(),
            );
            final count = await coordinator.synchronizeOfflineTrips(batchLimit: 10);
            return 'Synchronized $count offline trips cleanly using decoupled repository abstractions!';
          },
        ),
        PairScenario(
          title: 'Dispatch Alerts & Urgent Notifications',
          context: 'Alerting driver of high-surge orders via push and audible chimes.',
          problemSummary:
              'DispatchAlertCoordinator directly instantiated FirebaseCloudMessagingPlugin and FlutterLocalNotificationsPlugin.',
          problemBreaks:
              'Crashed on devices lacking Google Play Services (Huawei devices, dedicated POS terminals). High-level escalation was untestable.',
          problemFlow: '''[DispatchAlertCoordinator] (High-Level Escalation Policy)
      │ (Directly coupled to Google FCM & local audio plugins)
      ├── new FirebaseCloudMessagingPlugin()
      └── new FlutterLocalNotificationsPlugin()
(Crashes on Huawei devices without Google Play Services; untestable)''',
          solutionSummary:
              'Coordinator depends on PushNotificationGateway and UrgentSoundAlertGateway. Firebase, Huawei, and Mock gateways implement them.',
          solutionFixes:
              'Multi-store deployment (Google Play vs Huawei AppGallery) works out-of-the-box by injecting the appropriate gateway.',
          solutionFlow: '''[DispatchAlertCoordinator] (High-Level Escalation Policy)
      │ (Depends strictly on abstractions)
      ▼
[PushNotificationGateway]        [UrgentSoundAlertGateway]
      ▲                                    ▲
      │ (implemented by)                   │ (implemented by)
[FirebasePush] / [HuaweiPush]    [NativeDeviceAudioGateway]''',
          onRunSolution: () async {
            final coordinator = dip3.DispatchAlertCoordinator(
              pushGateway: dip3.HuaweiPushKitGateway(),
              soundGateway: dip3.NativeDeviceAudioGateway(),
            );
            await coordinator.notifyDriverOfUrgentOrder(
              driverId: 'DRV-404',
              deviceToken: 'hms_token_999',
              orderId: 'SURGE-77',
              surgeMultiplier: 2.1,
            );
            return 'High-surge alert dispatched cleanly using Huawei Push Kit abstraction for non-Google devices!';
          },
        ),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _principles.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SOLID Principles Demo',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'Ride-Hailing & Delivery Driver Domain • by Ibrahim Abo El-Haggag',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _principles
              .map(
                (p) => Tab(
                  icon: Icon(p.icon),
                  text: p.acronym,
                ),
              )
              .toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _principles.map((principle) => PrincipleView(principle: principle)).toList(),
      ),
    );
  }
}

class PrincipleData {
  final String key;
  final String acronym;
  final String name;
  final String tagline;
  final MaterialColor color;
  final IconData icon;
  final List<PairScenario> pairs;

  PrincipleData({
    required this.key,
    required this.acronym,
    required this.name,
    required this.tagline,
    required this.color,
    required this.icon,
    required this.pairs,
  });
}

class PairScenario {
  final String title;
  final String context;
  final String problemSummary;
  final String problemBreaks;
  final String problemFlow;
  final String solutionSummary;
  final String solutionFixes;
  final String solutionFlow;
  final Future<String> Function() onRunSolution;

  PairScenario({
    required this.title,
    required this.context,
    required this.problemSummary,
    required this.problemBreaks,
    required this.problemFlow,
    required this.solutionSummary,
    required this.solutionFixes,
    required this.solutionFlow,
    required this.onRunSolution,
  });
}

class PrincipleView extends StatelessWidget {
  final PrincipleData principle;

  const PrincipleView({super.key, required this.principle});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 2,
          color: principle.color.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: principle.color.withValues(alpha: 0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: principle.color,
                      foregroundColor: Colors.white,
                      child: Text(
                        principle.acronym,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            principle.name,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            principle.tagline,
                            style: TextStyle(
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Explore 3 realistic driver-app scenarios below with interactive execution and visual architecture flows.',
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...principle.pairs.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final pair = entry.value;
          return ScenarioCard(
            principleAcronym: principle.acronym,
            pairNumber: index,
            pair: pair,
            color: principle.color,
          );
        }),
      ],
    );
  }
}

class ScenarioCard extends StatefulWidget {
  final String principleAcronym;
  final int pairNumber;
  final PairScenario pair;
  final MaterialColor color;

  const ScenarioCard({
    super.key,
    required this.principleAcronym,
    required this.pairNumber,
    required this.pair,
    required this.color,
  });

  @override
  State<ScenarioCard> createState() => _ScenarioCardState();
}

class _ScenarioCardState extends State<ScenarioCard> {
  bool _isExpanded = false;
  String? _executionResult;
  bool _isRunning = false;

  void _runCode() async {
    setState(() {
      _isRunning = true;
      _executionResult = null;
    });
    try {
      final res = await widget.pair.onRunSolution();
      if (mounted) {
        setState(() {
          _isRunning = false;
          _executionResult = res;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRunning = false;
          _executionResult = 'Error: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Pair ${widget.pairNumber}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: widget.color.shade800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.pair.title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                  onPressed: () => setState(() => _isExpanded = !_isExpanded),
                ),
              ],
            ),
            Text(
              'Context: ${widget.pair.context}',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            // Problem Container
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.cancel, color: Colors.red, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Problem (Common Mistake):',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(widget.pair.problemSummary, style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '⚡ Problem Execution Flow:',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.pair.problemFlow,
                          style: const TextStyle(fontSize: 11, fontFamily: 'monospace', height: 1.3),
                        ),
                      ],
                    ),
                  ),
                  if (_isExpanded) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Why it breaks: ${widget.pair.problemBreaks}',
                      style: TextStyle(fontSize: 12, color: Colors.red.shade800, fontWeight: FontWeight.w500),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Solution Container
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withValues(alpha: 0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Solution (Clean Architecture):',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(widget.pair.solutionSummary, style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '✨ Decoupled Solution Flow:',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.pair.solutionFlow,
                          style: const TextStyle(fontSize: 11, fontFamily: 'monospace', height: 1.3),
                        ),
                      ],
                    ),
                  ),
                  if (_isExpanded) ...[
                    const SizedBox(height: 6),
                    Text(
                      'What is fixed: ${widget.pair.solutionFixes}',
                      style: TextStyle(fontSize: 12, color: Colors.green.shade800, fontWeight: FontWeight.w500),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Folder: lib/${widget.principleAcronym.toLowerCase()}/solution_${widget.pairNumber}/',
                  style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.outline),
                ),
                ElevatedButton.icon(
                  onPressed: _isRunning ? null : _runCode,
                  icon: _isRunning
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow, size: 16),
                  label: const Text('Run Solution Demo', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            if (_executionResult != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Console / Execution Output:',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _executionResult!,
                      style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
