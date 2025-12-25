import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'auth_service.dart';
import '../config.dart';
import '../models.dart';

/// DocuPipe Service
///
/// Manages document processing and menu extraction using DocuPipe API.
/// Admin feature for extracting menu items from PDF/image files.
class DocuPipeService extends ChangeNotifier {
  final AuthService _authService;
  final String _baseUrl = AppConfig.getEndpoint('API/DocuPipe');

  bool _isProcessing = false;
  String? _error;
  double _uploadProgress = 0.0;

  // Getters
  bool get isProcessing => _isProcessing;
  String? get error => _error;
  double get uploadProgress => _uploadProgress;

  DocuPipeService(this._authService);

  /// Get HTTP headers with authentication
  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getIdToken();
    return {
      'x-api-passcode': AppConfig.apiPasscode,
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Upload document for processing
  ///
  /// Uploads a document (PDF, PNG, JPG) to DocuPipe for OCR processing.
  /// Returns the document ID for tracking processing status.
  Future<String?> uploadDocument(
    File file, {
    String dataset = 'unassigned',
  }) async {
    try {
      _isProcessing = true;
      _uploadProgress = 0.0;
      _error = null;
      notifyListeners();

      // Prepare multipart request
      final uri = Uri.parse('$_baseUrl/upload?dataset=$dataset');
      final request = http.MultipartRequest('POST', uri);

      // Add headers
      final headers = await _getHeaders();
      request.headers.addAll(headers);

      // Detect MIME type
      final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
      final mimeTypeData = mimeType.split('/');

      // Add file
      final fileStream = http.ByteStream(file.openRead());
      final fileLength = await file.length();

      request.files.add(http.MultipartFile(
        'file',
        fileStream,
        fileLength,
        filename: file.path.split('/').last,
        contentType: MediaType(mimeTypeData[0], mimeTypeData[1]),
      ));

      // Send request with progress tracking
      final streamedResponse = await request.send();

      // Track upload progress
      int bytesUploaded = 0;
      streamedResponse.stream.listen(
        (chunk) {
          bytesUploaded += chunk.length;
          _uploadProgress = bytesUploaded / fileLength;
          notifyListeners();
        },
        onDone: () {
          _uploadProgress = 1.0;
          notifyListeners();
        },
      );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final documentId = data['documentId'] as String;

        if (kDebugMode) {
          print('DocuPipeService: Document uploaded successfully - ID: $documentId');
        }

        _isProcessing = false;
        _uploadProgress = 0.0;
        notifyListeners();
        return documentId;
      } else {
        final errorData = jsonDecode(response.body);
        _error = errorData['error'] ?? 'Failed to upload document';
        _isProcessing = false;
        _uploadProgress = 0.0;
        notifyListeners();
        return null;
      }
    } catch (e) {
      _error = 'Error uploading document: $e';
      _isProcessing = false;
      _uploadProgress = 0.0;
      notifyListeners();
      return null;
    }
  }

  /// Check processing job status
  ///
  /// Polls the DocuPipe API to check if document processing is complete.
  Future<JobStatus?> checkJobStatus(String jobId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/job/$jobId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return JobStatus.fromJson(data);
      }

      return null;
    } catch (e) {
      if (kDebugMode) print('DocuPipeService: Error checking job status - $e');
      return null;
    }
  }

  /// Get processed document
  ///
  /// Retrieves the fully processed document with extracted text and metadata.
  Future<DocumentResult?> getDocument(String documentId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/document/$documentId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return DocumentResult.fromJson(data);
      }

      return null;
    } catch (e) {
      if (kDebugMode) print('DocuPipeService: Error getting document - $e');
      return null;
    }
  }

  /// Extract menu items from document
  ///
  /// Uses DocuPipe's AI to extract structured menu data from a menu PDF/image.
  /// Returns a list of MenuItem objects ready for database insertion.
  Future<List<MenuItem>?> extractMenu(File menuFile) async {
    try {
      _isProcessing = true;
      _error = null;
      notifyListeners();

      // Prepare multipart request
      final uri = Uri.parse('$_baseUrl/extract-menu');
      final request = http.MultipartRequest('POST', uri);

      // Add headers
      final headers = await _getHeaders();
      request.headers.addAll(headers);

      // Detect MIME type
      final mimeType = lookupMimeType(menuFile.path) ?? 'application/octet-stream';
      final mimeTypeData = mimeType.split('/');

      // Add file
      final fileStream = http.ByteStream(menuFile.openRead());
      final fileLength = await menuFile.length();

      request.files.add(http.MultipartFile(
        'file',
        fileStream,
        fileLength,
        filename: menuFile.path.split('/').last,
        contentType: MediaType(mimeTypeData[0], mimeTypeData[1]),
      ));

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final menuItems = (data['menuItems'] as List<dynamic>)
            .map((json) => MenuItem.fromJson(json as Map<String, dynamic>))
            .toList();

        if (kDebugMode) {
          print('DocuPipeService: Extracted ${menuItems.length} menu items');
        }

        _isProcessing = false;
        notifyListeners();
        return menuItems;
      } else {
        final errorData = jsonDecode(response.body);
        _error = errorData['error'] ?? 'Failed to extract menu';
        _isProcessing = false;
        notifyListeners();
        return null;
      }
    } catch (e) {
      _error = 'Error extracting menu: $e';
      _isProcessing = false;
      notifyListeners();
      return null;
    }
  }

  /// Get standardization results
  ///
  /// Retrieves standardized/normalized data from DocuPipe processing.
  Future<StandardizationResult?> getStandardization(String standardizationId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/standardization/$standardizationId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return StandardizationResult.fromJson(data);
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('DocuPipeService: Error getting standardization - $e');
      }
      return null;
    }
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Reset processing state
  void reset() {
    _isProcessing = false;
    _error = null;
    _uploadProgress = 0.0;
    notifyListeners();
  }
}
