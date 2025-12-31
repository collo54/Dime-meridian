import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_ai/firebase_ai.dart'; // The unified SDK
import 'package:flutter/foundation.dart';
import 'package:mime/mime.dart';

class FinancialAiService {
  late final GenerativeModel _model;
  late final ChatSession _chat;

  // Define the tool name constant
  static const String _toolName = 'runRevenueQuery';

  FinancialAiService() {
    _initModel();
  }

  void _initModel() {
    // 1. Define the Tool (Function Declaration)
    // This tells Gemini: "I have a function that can run SQL queries."
    final queryTool = FunctionDeclaration(
      _toolName,
      'Executes a Standard SQL query against the BigQuery revenue database to answer financial questions.',
      parameters: {
        'sqlQuery': Schema(
          SchemaType.string,
          description: 'The Standard SQL query to execute.',
        ),
      },
      // In this package, items NOT in 'optionalParameters' are required by default.
      // Since we want sqlQuery to be required, we just leave this empty or omit it.
      optionalParameters: [],
    );

    // 2. Define the Schema (System Instructions)
    // This tells Gemini the table structure so it knows HOW to write the SQL.
    const systemPrompt = '''
    You are an expert Data Analyst and SQL Engineer.
    
    Your goal is to answer user questions about app revenue.
    You have access to two sources of information:
    1. A BigQuery database (via the `runRevenueQuery` tool).
    2. User-uploaded documents (PDFs/CSVs) which may contain invoices or expenses.
    
    DATABASE SCHEMA:
    Project: `dime-meridian`
    Dataset: `analytics`
    Table: `revenue_events`
    
    Columns:
    - event_id (STRING): Unique ID
    - user_id (STRING): App User ID
    - product_id (STRING): The product purchased (e.g., 'monthly_sub', 'lifetime')
    - amount_usd (FLOAT): Revenue in USD
    - store (STRING): 'APP_STORE' or 'PLAY_STORE'
    - type (STRING): Event type. Values: 'INITIAL_PURCHASE', 'RENEWAL', 'CANCELLATION', 'EXPIRATION'
    - timestamp (TIMESTAMP): When the event happened.
    
    RULES:
    1. ALWAYS use Standard SQL.
    2. ALWAYS use the full table name: `dime-meridian.analytics.revenue_events`
    3. If asked about "revenue", SUM(amount_usd).
    4. If asked about "sales" or "transactions", COUNT(*).
    
    CRITICAL INSTRUCTIONS FOR DOCUMENTS + DATABASE:
    5. If a document is attached, do NOT automatically apply the document's date to the Database Query. Only filter by date if the user explicitly asks (e.g. "revenue for the invoice's month").
    6. For general questions like "best performing store" or "total revenue", query the ENTIRE database history (no WHERE timestamp clause).
    7. If the user asks to compare (e.g. "profit"), extract the expense from the document and subtract it from the database revenue total.
    8. Do NOT say "I can only query the database". Combine the insights.
    ''';

    // 3. Initialize Model with Tools
    _model = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-2.5-flash',
      systemInstruction: Content.system(systemPrompt),
      tools: [
        Tool.functionDeclarations([queryTool]),
      ],
    );

    _chat = _model.startChat();
  }

  // --- NEW: Helper to pick a file ---
  Future<PlatformFile?> pickDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'csv', 'txt'],
        withData: true,
      );

      if (result == null) return null;
      return result.files.first;
    } catch (e) {
      debugPrint("Error picking file: $e");
      return null;
    }
  }

  // --- UPDATED: sendMessage handles Text AND Files ---
  Future<String> sendMessage(
    String userMessage, {
    PlatformFile? attachedFile,
  }) async {
    try {
      Content content;

      // 1. Check if a file is attached
      if (attachedFile != null) {
        Uint8List? fileBytes = attachedFile.bytes;

        // Fallback for mobile path reading if bytes are null
        if (fileBytes == null && attachedFile.path != null) {
          fileBytes = await File(attachedFile.path!).readAsBytes();
        }

        if (fileBytes == null) throw Exception("Could not read file data");

        // Determine MIME type
        String? mimeType =
            lookupMimeType(attachedFile.name) ?? 'application/pdf';
        if (attachedFile.extension == 'csv') mimeType = 'text/csv';

        // Create Multimodal Content (Text + File)
        content = Content.multi([
          TextPart(userMessage),
          InlineDataPart(mimeType, fileBytes),
        ]);
      } else {
        // Text Only
        content = Content.text(userMessage);
      }

      // 2. Send to Gemini
      var response = await _chat.sendMessage(content);

      // 3. Handle Function Calls (Existing Logic)
      // This allows the AI to decide: Analyze the PDF directly? OR Call the SQL tool?
      while (response.functionCalls.isNotEmpty) {
        final functionCall = response.functionCalls.first;

        if (functionCall.name == _toolName) {
          final sqlQuery = functionCall.args['sqlQuery'] as String;

          final apiResult = await _callCloudFunction(sqlQuery);

          response = await _chat.sendMessage(
            Content.functionResponse(functionCall.name, {'result': apiResult}),
          );
        }
      }

      return response.text ??
          "I processed the input but couldn't generate a summary.";
    } catch (e) {
      debugPrint("AI Error: $e");
      return "Sorry, I encountered an error: $e";
    }
  }

  /// Helper to call the Cloud Function
  Future<Object> _callCloudFunction(String sqlQuery) async {
    try {
      debugPrint("🤖 AI Generating SQL: $sqlQuery");

      final result = await FirebaseFunctions.instance
          .httpsCallable('runDynamicBigQuery')
          .call({'query': sqlQuery});

      final data = result.data as Map<String, dynamic>;

      if (data.containsKey('error')) {
        return "SQL Error: ${data['error']}";
      }

      return data['data']; // Returns the list of rows
    } catch (e) {
      return "System Error: $e";
    }
  }
}
