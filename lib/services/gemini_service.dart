import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models.dart';

// Gemini AI service for chat interactions and content generation
class GeminiService with ChangeNotifier {
  // Conversation history for context-aware responses
  List<GeminiMessage> _conversationHistory = [];
  // Loading state for API calls
  bool _isLoading = false;
  // Error message for UI display
  String? _errorMessage;
  // Last AI response for quick access
  String? _lastResponse;

  // Getters for UI consumption
  List<GeminiMessage> get conversationHistory => List.unmodifiable(_conversationHistory);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get lastResponse => _lastResponse;

  // Gets HTTP headers for API requests
  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'X-API-Passcode': AppConfig.apiPasscode,
    };
  }

  // Sends a chat message and receives AI response with conversation history
  Future<String?> sendChatMessage(String message) async {
    if (message.trim().isEmpty) return null;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Add user message to history
      _conversationHistory.add(GeminiMessage(role: 'user', content: message.trim()));

      // Build request body with history
      final body = {
        'message': message.trim(),
        'history': _conversationHistory.map((m) => m.toJson()).toList(),
      };

      final response = await http.post(
        Uri.parse(AppConfig.geminiChatEndpoint),
        headers: _getHeaders(),
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiResponse = data['response'] as String? ?? data['text'] as String? ?? '';

        // Add AI response to history
        _conversationHistory.add(GeminiMessage(role: 'model', content: aiResponse));

        _lastResponse = aiResponse;
        _isLoading = false;
        notifyListeners();

        if (kDebugMode) print('GeminiService: Received response');
        return aiResponse;
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } catch (error) {
      _errorMessage = 'Failed to get response: $error';
      _isLoading = false;
      notifyListeners();
      if (kDebugMode) print('GeminiService: Error - $error');
      return null;
    }
  }

  // Generates text without conversation history context
  Future<String?> generateText(String prompt) async {
    if (prompt.trim().isEmpty) return null;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse(AppConfig.geminiGenerateEndpoint),
        headers: _getHeaders(),
        body: jsonEncode({'prompt': prompt.trim()}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final generatedText = data['response'] as String? ?? data['text'] as String? ?? '';

        _lastResponse = generatedText;
        _isLoading = false;
        notifyListeners();

        return generatedText;
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } catch (error) {
      _errorMessage = 'Failed to generate text: $error';
      _isLoading = false;
      notifyListeners();
      if (kDebugMode) print('GeminiService: Error - $error');
      return null;
    }
  }

  // Generates a restaurant description based on restaurant data
  Future<String?> generateRestaurantDescription(Map<String, dynamic> restaurantData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse(AppConfig.geminiRestaurantEndpoint),
        headers: _getHeaders(),
        body: jsonEncode(restaurantData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final description = data['description'] as String? ?? data['response'] as String? ?? '';

        _lastResponse = description;
        _isLoading = false;
        notifyListeners();

        return description;
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } catch (error) {
      _errorMessage = 'Failed to generate description: $error';
      _isLoading = false;
      notifyListeners();
      if (kDebugMode) print('GeminiService: Error - $error');
      return null;
    }
  }

  // Provides quick suggestions for common user queries
  List<String> getQuickSuggestions(bool isTraditionalChinese) {
    if (isTraditionalChinese) {
      return [
        '推薦附近的素食餐廳',
        '今天有什麼特別推薦？',
        '哪裡可以找到全素餐廳？',
        '素食餐廳的營業時間',
        '如何預訂餐廳？',
      ];
    }
    return [
      'Recommend nearby vegan restaurants',
      'What are today\'s specials?',
      'Where can I find fully vegan restaurants?',
      'Restaurant opening hours',
      'How do I make a reservation?',
    ];
  }

  // Clears conversation history for a fresh start
  void clearHistory() {
    _conversationHistory = [];
    _lastResponse = null;
    _errorMessage = null;
    notifyListeners();
    if (kDebugMode) print('GeminiService: History cleared');
  }

  // Clears error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Removes the last message pair from history (undo last question)
  void undoLastMessage() {
    if (_conversationHistory.length >= 2) {
      _conversationHistory.removeLast(); // Remove AI response
      _conversationHistory.removeLast(); // Remove user question
      notifyListeners();
    }
  }
}
