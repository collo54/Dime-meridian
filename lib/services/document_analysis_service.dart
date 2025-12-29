import 'dart:io';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart';

class DocumentAnalysisService {
  late final GenerativeModel _model;

  DocumentAnalysisService() {
    // Initialize using Google AI backend
    _model = FirebaseAI.googleAI().generativeModel(
      model:
          'gemini-2.5-flash', // 1.5 Flash is faster/cheaper for text analysis
    );
  }

  /// 1. Helper to pick the file (UI calls this first)
  Future<PlatformFile?> pickDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'csv', 'txt'],
        withData: true, // Needed for bytes
      );

      if (result == null) return null;
      return result.files.first;
    } catch (e) {
      debugPrint("Error picking file: $e");
      return null;
    }
  }

  /// 2. Analyze the file that was already picked (UI calls this second)
  Future<String?> analyzeDocument({
    required String promptText,
    required PlatformFile file,
  }) async {
    try {
      Uint8List? fileBytes = file.bytes;

      // Fallback for mobile path reading if bytes are null
      if (fileBytes == null && file.path != null) {
        fileBytes = await File(file.path!).readAsBytes();
      }

      if (fileBytes == null) throw Exception("Could not read file data");

      // Determine MIME type
      String? mimeType = lookupMimeType(file.name) ?? 'application/pdf';
      if (file.extension == 'csv') mimeType = 'text/csv';

      // Construct Prompt
      final content = [
        Content.multi([
          TextPart(promptText),
          InlineDataPart(mimeType, fileBytes),
        ]),
      ];

      // Generate
      final response = await _model.generateContent(content);
      return response.text;
    } catch (e) {
      debugPrint("Error analyzing document: $e");
      rethrow;
    }
  }
}

// import 'dart:io';
// import 'dart:typed_data';
// import 'package:firebase_ai/firebase_ai.dart'; // The new unified package
// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';
// import 'package:mime/mime.dart'; // To detect 'application/pdf' or 'text/csv'

// class DocumentAnalysisService {
//   late final GenerativeModel _model;

//   DocumentAnalysisService() {
//     // 1. Initialize using the Google AI backend (Not Vertex)
//     // This uses the API Key method managed by Firebase AI Logic
//     _model = FirebaseAI.googleAI().generativeModel(model: 'gemini-2.5-flash');
//   }

//   /// Pick a document and ask a question about it
//   Future<String?> pickAndAnalyzeDocument(String promptText) async {
//     try {
//       // 2. Pick the file (PDF or CSV)
//       FilePickerResult? result = await FilePicker.platform.pickFiles(
//         type: FileType.custom,
//         allowedExtensions: ['pdf', 'csv', 'txt'],
//         withData: true, // Important: We need the bytes immediately
//       );

//       if (result == null) return null; // User canceled

//       PlatformFile file = result.files.first;
//       Uint8List? fileBytes = file.bytes;

//       // If bytes are null (sometimes on mobile), read from path
//       if (fileBytes == null && file.path != null) {
//         fileBytes = await File(file.path!).readAsBytes();
//       }

//       if (fileBytes == null) throw Exception("Could not read file data");

//       // 3. Determine MIME type (gemini needs this to know if it's a PDF or CSV)
//       String? mimeType = lookupMimeType(file.name) ?? 'application/pdf';

//       // Manual override for CSV if mime detection fails
//       if (file.extension == 'csv') mimeType = 'text/csv';

//       // 4. Construct the Multimodal Prompt
//       // We send the text prompt AND the file data together
//       final content = [
//         Content.multi([
//           TextPart(promptText),
//           // Pass the document as inline data
//           InlineDataPart(mimeType, fileBytes),
//         ]),
//       ];

//       // 5. Generate Response
//       final response = await _model.generateContent(content);

//       return response.text;
//     } catch (e) {
//       debugPrint("Error analyzing document: $e");
//       rethrow;
//     }
//   }
// }
