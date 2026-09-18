// Part of solid_principles_demo by Ibrahim Abo El-Haggag

/*
================================================================================
SINGLE RESPONSIBILITY PRINCIPLE (SRP) — PROBLEM 2
Feature: Driver Document Verification & Onboarding (License & Vehicle ID)
================================================================================

1. WHAT THIS CODE DOES:
   During driver onboarding or annual document renewal (e.g. driver's license,
   criminal background check, vehicle inspection paper), this class receives
   the raw camera image from the driver's phone, compresses the image to save bandwidth,
   runs OCR (Optical Character Recognition) to extract the driver's national ID and
   license expiry date, validates legal requirements (e.g. license not expired, valid
   in jurisdiction), uploads the compressed photo to an AWS S3 cloud bucket, and updates
   the driver's profile status in the database.

   EXECUTION FLOW (MONOLITHIC):
   Driver uploads Document Photo
           ↓
   [DriverDocumentService] (All-in-One Class)
      ├── 1. Image Compression (Resizes raw bytes)
      ├── 2. OCR Engine (Extracts ID & expiry dates)
      ├── 3. Compliance Rules (Rejects if < 30 days valid)
      ├── 4. Cloud Storage (Uploads bytes to AWS S3)
      └── 5. Database Profile (Marks status = VERIFIED)
   (4 distinct reasons to change - fragile and un-testable in isolation)

2. WHY IT LOOKS FINE AT FIRST GLANCE:
   To many developers, this is simply "the document verification service". Everything
   inside it is related to processing a driver's document from the camera capture.

3. WHAT SPECIFIC PROBLEM IT CAUSES AS CODE GROWS:
   - If the engineering team switches cloud providers (e.g. from AWS S3 to Google Cloud
     Storage or Cloudflare R2), this class must be rewritten.
   - If image compression settings need tuning (e.g. converting JPEG to WebP to reduce mobile data),
     this class must be edited.
   - If government regulations change (e.g. minimum validity required increases from 30 days
     to 90 days before expiry), this class must be edited.
   - You cannot write a unit test to verify document validation rules without executing image
     compression, OCR processing, and network uploads.

4. WHICH SOLID PRINCIPLE IT VIOLATES & WHY:
   Violates the Single Responsibility Principle (SRP).
   The class `DriverDocumentService` has at least FOUR distinct reasons to change:
   (1) Image compression and byte manipulation,
   (2) OCR extraction technology,
   (3) Business/legal compliance validation rules,
   (4) Cloud storage infrastructure.
================================================================================
*/

import 'dart:typed_data';

class DocumentSubmission {
  final String documentType; // 'DRIVING_LICENSE', 'VEHICLE_REGISTRATION'
  final Uint8List rawImageBytes;
  final String driverId;

  DocumentSubmission({
    required this.documentType,
    required this.rawImageBytes,
    required this.driverId,
  });
}

class DriverDocumentService {
  Future<bool> processAndVerifyDocument(DocumentSubmission submission) async {
    print('[Onboarding] Processing ${submission.documentType} for driver: ${submission.driverId}');

    // 1. Image Compression Responsibility
    print('[Image Compression] Resizing ${submission.rawImageBytes.lengthInBytes} bytes to WebP 80% quality...');
    final compressedBytes = submission.rawImageBytes; // simulated compression

    // 2. OCR Text Extraction Responsibility
    print('[OCR Engine] Scanning document text from image bytes...');
    final simulatedExtractedExpiry = DateTime.now().add(const Duration(days: 120));
    final simulatedExtractedIdNumber = 'DL-98234-EG';
    print('[OCR Engine] Found ID: $simulatedExtractedIdNumber, Expiry: $simulatedExtractedExpiry');

    // 3. Business / Legal Compliance Validation Responsibility
    final daysUntilExpiry = simulatedExtractedExpiry.difference(DateTime.now()).inDays;
    if (daysUntilExpiry < 30) {
      print('[Validation Error] Document expires too soon ($daysUntilExpiry days left). Minimum is 30 days.');
      return false;
    }
    if (!simulatedExtractedIdNumber.startsWith('DL-')) {
      print('[Validation Error] Invalid license format: $simulatedExtractedIdNumber');
      return false;
    }

    // 4. Cloud Storage Upload Responsibility (AWS S3)
    final s3Url = 'https://s3.amazonaws.com/driver-docs/${submission.driverId}/${submission.documentType}.webp';
    print('[AWS S3] Uploading ${compressedBytes.lengthInBytes} bytes to $s3Url');

    // 5. Database Profile Update Responsibility
    print('[Database] Updated driver ${submission.driverId}: ${submission.documentType} status = VERIFIED');

    return true;
  }
}
