import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models.dart';

/// Gemini AI Service
///
/// Provides AI-powered features using Google Gemini API:
/// - Text generation
/// - Conversational chat with history
/// - Restaurant description generation
/// - Dining recommendations
///
/// All methods require the API passcode header.
/// Authentication tokens are not required for AI endpoints.
class GeminiService extends ChangeNotifier {
  // State management
  bool _isLoading = false;
  String? _errorMessage;
  List<GeminiChatHistory> _conversationHistory = [];

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<GeminiChatHistory> get conversationHistory =>
      List.unmodifiable(_conversationHistory);

  /// Default Gemini model
  static const String defaultModel = 'gemini-2.5-flash-lite-preview-09-2025';

  /// Generate text content from a prompt
  ///
  /// Parameters:
  /// - [prompt]: The text prompt for content generation
  /// - [model]: Optional model name (defaults to gemini-2.5-flash-lite)
  /// - [temperature]: Controls randomness (0.0-1.0, default 0.7)
  /// - [maxTokens]: Maximum tokens to generate (default 200)
  /// - [topP]: Nucleus sampling parameter (default 0.95)
  /// - [topK]: Top-k sampling parameter (default 40)
  ///
  /// Returns the generated text or null on error
  Future<String?> generate(
    String prompt, {
    String? model,
    double? temperature,
    int? maxTokens,
    double? topP,
    int? topK,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = GeminiGenerateRequest(
        prompt: prompt,
        model: model,
        temperature: temperature,
        maxTokens: maxTokens,
        topP: topP,
        topK: topK,
      );

      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/API/Gemini/generate'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-passcode': AppConfig.apiPasscode,
        },
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final geminiResponse = GeminiGenerateResponse.fromJson(data);
        _isLoading = false;
        notifyListeners();
        return geminiResponse.result;
      } else {
        _errorMessage =
            'Failed to generate content: ${response.statusCode} ${response.body}';
        if (kDebugMode) print(_errorMessage);
        _isLoading = false;
        notifyListeners();
        return null;
      }
    } catch (e) {
      _errorMessage = 'Error generating content: $e';
      if (kDebugMode) print(_errorMessage);
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Chat with AI using conversation history
  ///
  /// Parameters:
  /// - [message]: The user's message
  /// - [history]: Optional conversation history (uses internal history if null)
  /// - [model]: Optional model name
  /// - [useInternalHistory]: Whether to maintain internal conversation state (default true)
  ///
  /// Returns the AI's response or null on error
  Future<String?> chat(
    String message, {
    List<GeminiChatHistory>? history,
    String? model,
    bool useInternalHistory = true,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Use provided history or internal history
      final chatHistory = history ?? (useInternalHistory ? _conversationHistory : null);

      final request = GeminiChatRequest(
        message: message,
        history: chatHistory,
        model: model,
      );

      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/API/Gemini/chat'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-passcode': AppConfig.apiPasscode,
        },
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final geminiResponse = GeminiChatResponse.fromJson(data);

        // Update internal history if enabled
        if (useInternalHistory && geminiResponse.history != null) {
          _conversationHistory = geminiResponse.history!;
        }

        _isLoading = false;
        notifyListeners();
        return geminiResponse.result;
      } else {
        _errorMessage = 'Failed to chat: ${response.statusCode} ${response.body}';
        if (kDebugMode) print(_errorMessage);
        _isLoading = false;
        notifyListeners();
        return null;
      }
    } catch (e) {
      _errorMessage = 'Error chatting: $e';
      if (kDebugMode) print(_errorMessage);
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Generate restaurant description
  ///
  /// Parameters:
  /// - [name]: Restaurant name (required)
  /// - [cuisine]: Type of cuisine
  /// - [district]: District/location
  /// - [keywords]: List of keywords (e.g., "Organic", "Vegan")
  /// - [language]: Language for description (default "EN")
  ///
  /// Returns the generated description or null on error
  Future<String?> generateRestaurantDescription({
    required String name,
    String? cuisine,
    String? district,
    List<String>? keywords,
    String? language,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = GeminiRestaurantDescriptionRequest(
        name: name,
        cuisine: cuisine,
        district: district,
        keywords: keywords,
        language: language ?? 'EN',
      );

      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/API/Gemini/restaurant-description'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-passcode': AppConfig.apiPasscode,
        },
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final geminiResponse = GeminiRestaurantDescriptionResponse.fromJson(data);
        _isLoading = false;
        notifyListeners();
        return geminiResponse.description;
      } else {
        _errorMessage =
            'Failed to generate description: ${response.statusCode} ${response.body}';
        if (kDebugMode) print(_errorMessage);
        _isLoading = false;
        notifyListeners();
        return null;
      }
    } catch (e) {
      _errorMessage = 'Error generating description: $e';
      if (kDebugMode) print(_errorMessage);
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Ask a question about a specific restaurant
  ///
  /// Helper method that uses the chat endpoint with context
  Future<String?> askAboutRestaurant(
    String question,
    String restaurantName, {
    String? cuisine,
    String? district,
  }) async {
    final context = StringBuffer();
    context.write('Restaurant: $restaurantName');
    if (cuisine != null) context.write(', Cuisine: $cuisine');
    if (district != null) context.write(', Location: $district');

    final prompt = '$context\n\nQuestion: $question';

    return chat(
      prompt,
      useInternalHistory: false,
    );
  }

  /// Get dining recommendations based on preferences
  ///
  /// Parameters:
  /// - [preferences]: Map of user preferences (dietary, location, price, etc.)
  ///
  /// Returns recommendations or null on error
  Future<String?> getDiningRecommendation(
      Map<String, dynamic> preferences) async {
    final prompt = StringBuffer();
    prompt.write('Based on the following preferences, recommend vegetarian/vegan restaurants in Hong Kong:\n');

    preferences.forEach((key, value) {
      prompt.write('- $key: $value\n');
    });

    prompt.write('\nProvide 2-3 specific recommendations with reasons.');

    return generate(
      prompt.toString(),
      temperature: 0.8,
      maxTokens: 400,
    );
  }

  /// Get restaurant suggestions based on criteria
  ///
  /// Helper method for suggesting restaurants
  Future<String?> suggestRestaurants({
    String? district,
    String? cuisine,
    String? dietaryPreference,
    String? priceRange,
  }) async {
    final criteria = <String>[];
    if (district != null) criteria.add('in $district');
    if (cuisine != null) criteria.add('serving $cuisine');
    if (dietaryPreference != null) criteria.add('with $dietaryPreference options');
    if (priceRange != null) criteria.add('in $priceRange price range');

    final prompt = criteria.isEmpty
        ? 'Suggest some popular vegetarian/vegan restaurants in Hong Kong.'
        : 'Suggest vegetarian/vegan restaurants ${criteria.join(', ')} in Hong Kong.';

    return generate(
      prompt,
      temperature: 0.7,
      maxTokens: 300,
    );
  }

  /// Clear conversation history
  void clearHistory() {
    _conversationHistory = [];
    notifyListeners();
  }

  /// Add a message to conversation history manually
  void addToHistory(String role, String content) {
    _conversationHistory.add(GeminiChatHistory(
      role: role,
      content: content,
    ));
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
