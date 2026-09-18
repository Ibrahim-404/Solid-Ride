// Part of solid_principles_demo by Ibrahim Abo El-Haggag

/*
================================================================================
SINGLE RESPONSIBILITY PRINCIPLE (SRP) — SOLUTION 2
Feature: Driver Document Verification & Onboarding (Refactored)
================================================================================

1. WHAT CHANGED STRUCTURALLY:
   The responsibilities previously conflated inside `DriverDocumentService` are now
   separated into dedicated classes, each with a single reason to change:
   - `DocumentImageCompressor`: Focused exclusively on image compression and formats.
   - `DocumentOcrParser`: Focused on parsing data from image text.
   - `DocumentComplianceValidator`: Pure business validation logic (dates, formats).
   - `DocumentCloudStorage`: Responsible for uploading assets to cloud storage.
   - `DriverProfileRepository`: Handles persisting verification flags to the database.
   - `DriverDocumentProcessor`: Orchestrates the flow in a clean, readable pipeline.

2. WHY THIS FIXES THE EXACT PROBLEM FROM PROBLEM 2:
   - If legal minimum validity changes from 30 to 90 days, we edit `DocumentComplianceValidator`.
     There is zero risk of breaking S3 uploads or image compression.
   - If cloud storage migrates from AWS to Google Cloud Storage or Cloudflare R2, we only touch
     `DocumentCloudStorage`.
   - `DocumentComplianceValidator` can now be tested in milliseconds using unit tests with 100%
     branch coverage without mocking camera feeds, OCR libraries, or network buckets.

3. WHY THIS IS PROPORTIONATE (NOT OVER-ENGINEERING):
   Driver onboarding documents have severe legal and regulatory compliance requirements.
   Keeping compliance rules isolated from low-level image byte manipulation prevents
   accidental approval of expired licenses caused by unintended side effects.
================================================================================
*/

import 'dart:typed_data';

class DocumentSubmission {
  final String documentType;
  final Uint8List rawImageBytes;
  final String driverId;

  const DocumentSubmission({
    required this.documentType,
    required this.rawImageBytes,
    required this.driverId,
  });
}

class ExtractedDocumentData {
  final String idNumber;
  final DateTime expiryDate;

  const ExtractedDocumentData({
    required this.idNumber,
    required this.expiryDate,
  });
}

/// Responsibility 1: Image compression and optimization.
class DocumentImageCompressor {
  Uint8List compressToWebP(Uint8List rawBytes, {int quality = 80}) {
    print('[ImageCompressor] Compressing ${rawBytes.lengthInBytes} bytes to WebP at $quality% quality.');
    return rawBytes; // simulated optimized bytes
  }
}

/// Responsibility 2: Optical Character Recognition parsing.
class DocumentOcrParser {
  ExtractedDocumentData extractData(Uint8List imageBytes) {
    print('[OCR Engine] Parsing text from document image...');
    return ExtractedDocumentData(
      idNumber: 'DL-98234-EG',
      expiryDate: DateTime.now().add(const Duration(days: 180)),
    );
  }
}

/// Responsibility 3: Pure business & legal compliance validation.
class DocumentComplianceValidator {
  static const int minValidityDaysRequired = 30;

  bool validateLicense(ExtractedDocumentData data) {
    final daysUntilExpiry = data.expiryDate.difference(DateTime.now()).inDays;
    if (daysUntilExpiry < minValidityDaysRequired) {
      print('[Validator] REJECTED: License expires in $daysUntilExpiry days (min: $minValidityDaysRequired).');
      return false;
    }
    if (!data.idNumber.startsWith('DL-')) {
      print('[Validator] REJECTED: Unrecognized license prefix "${data.idNumber}".');
      return false;
    }
    print('[Validator] APPROVED: License valid for $daysUntilExpiry days.');
    return true;
  }
}

/// Responsibility 4: Cloud storage asset management.
class DocumentCloudStorage {
  Future<String> uploadDocument({
    required String driverId,
    required String documentType,
    required Uint8List fileBytes,
  }) async {
    final url = 'https://s3.amazonaws.com/driver-docs/$driverId/$documentType.webp';
    print('[CloudStorage] Uploaded ${fileBytes.lengthInBytes} bytes to $url');
    return url;
  }
}

/// Responsibility 5: Profile database persistence.
class DriverProfileRepository {
  Future<void> markDocumentVerified({
    required String driverId,
    required String documentType,
    required String storageUrl,
  }) async {
    print('[ProfileRepo] Saved $documentType = VERIFIED (URL: $storageUrl) for driver $driverId.');
  }
}

/// Orchestrator: Coordinates the single-purpose components.
class DriverDocumentProcessor {
  final DocumentImageCompressor _compressor;
  final DocumentOcrParser _ocrParser;
  final DocumentComplianceValidator _validator;
  final DocumentCloudStorage _storage;
  final DriverProfileRepository _profileRepo;

  DriverDocumentProcessor({
    required DocumentImageCompressor compressor,
    required DocumentOcrParser ocrParser,
    required DocumentComplianceValidator validator,
    required DocumentCloudStorage storage,
    required DriverProfileRepository profileRepo,
  })  : _compressor = compressor,
        _ocrParser = ocrParser,
        _validator = validator,
        _storage = storage,
        _profileRepo = profileRepo;

  Future<bool> processSubmission(DocumentSubmission submission) async {
    // 1. Compress image
    final compressedBytes = _compressor.compressToWebP(submission.rawImageBytes);

    // 2. Extract data via OCR
    final extractedData = _ocrParser.extractData(compressedBytes);

    // 3. Validate compliance
    final isValid = _validator.validateLicense(extractedData);
    if (!isValid) return false;

    // 4. Store in cloud
    final fileUrl = await _storage.uploadDocument(
      driverId: submission.driverId,
      documentType: submission.documentType,
      fileBytes: compressedBytes,
    );

    // 5. Update driver profile
    await _profileRepo.markDocumentVerified(
      driverId: submission.driverId,
      documentType: submission.documentType,
      storageUrl: fileUrl,
    );

    return true;
  }
}
