import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models.dart';
import '../utils/ai_response_processor.dart';

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
        // Clean the response before returning
        return AIResponseProcessor.cleanResponse(geminiResponse.result);
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
        // Clean the response before returning
        return AIResponseProcessor.cleanResponse(geminiResponse.result);
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
        // Clean the response before returning
        return AIResponseProcessor.cleanResponse(geminiResponse.description);
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

  /// Ask a question about a specific restaurant with menu context
  ///
  /// PRIORITY: Menu-related questions are answered first
  /// This method accepts optional menu items to provide context about the restaurant's menu
  ///
  /// Parameters:
  /// - [question]: User's question
  /// - [restaurantName]: Name of the restaurant
  /// - [cuisine]: Type of cuisine
  /// - [district]: Restaurant location
  /// - [menuItems]: Optional list of menu items for menu-specific queries
  ///
  /// Returns AI response focusing on menu if menu-related question is detected
  Future<String?> askAboutRestaurant(
    String question,
    String restaurantName, {
    String? cuisine,
    String? district,
    List<MenuItem>? menuItems,
  }) async {
    final context = StringBuffer();
    context.write('Restaurant: $restaurantName');
    if (cuisine != null) context.write(', Cuisine: $cuisine');
    if (district != null) context.write(', Location: $district');

    // Add menu context if available and question seems menu-related
    if (menuItems != null && menuItems.isNotEmpty) {
      final isMenuRelated = _isMenuRelatedQuestion(question);

      if (isMenuRelated) {
        // Prioritize menu items in the context
        context.write('\n\nMENU ITEMS (answer questions about the menu using this information first):');
        for (final item in menuItems.take(20)) { // Limit to 20 items to avoid token limits
          final name = item.nameEn ?? item.nameTc ?? 'Unknown';
          final description = item.descriptionEn ?? item.descriptionTc ?? '';
          final price = item.price != null ? '\$${item.price}' : '';
          context.write('\n- $name${price.isNotEmpty ? ' ($price)' : ''}');
          if (description.isNotEmpty) {
            context.write(': $description');
          }
        }
      }
    }

    final prompt = '$context\n\nQuestion: $question';

    return chat(
      prompt,
      useInternalHistory: false,
    );
  }

  /// Detect if a question is menu-related
  ///
  /// Checks for common menu-related keywords in the question
  bool _isMenuRelatedQuestion(String question) {
    final lowerQuestion = question.toLowerCase();
    final menuKeywords = [
      'menu', 'dish', 'food', 'meal', 'eat', 'serve', 'offer',
      'recommend', 'popular', 'special', 'signature', 'price',
      'cost', 'expensive', 'cheap', 'affordable', 'item',
      '菜單', '菜', '食', '餐', '推薦', '價錢', '價格', '平', '貴'
    ];

    return menuKeywords.any((keyword) => lowerQuestion.contains(keyword));
  }

  /// Get menu suggestions and recommendations
  ///
  /// Specifically designed for menu-related queries
  /// This method is available to ALL users (including guests)
  Future<String?> getMenuSuggestions({
    String? restaurantName,
    List<MenuItem>? menuItems,
    List<String>? dietaryRestrictions,
    bool isTraditionalChinese = false,
  }) async {
    final prompt = StringBuffer();

    if (restaurantName != null) {
      prompt.write('Restaurant: $restaurantName\n\n');
    }

    // Add menu items if available
    if (menuItems != null && menuItems.isNotEmpty) {
      prompt.write('MENU ITEMS:\n');
      for (final item in menuItems.take(20)) {
        final name = isTraditionalChinese
            ? (item.nameTc ?? item.nameEn ?? 'Unknown')
            : (item.nameEn ?? item.nameTc ?? 'Unknown');
        final description = isTraditionalChinese
            ? (item.descriptionTc ?? item.descriptionEn ?? '')
            : (item.descriptionEn ?? item.descriptionTc ?? '');
        final price = item.price != null ? '\$${item.price}' : '';

        prompt.write('- $name${price.isNotEmpty ? ' ($price)' : ''}');
        if (description.isNotEmpty) {
          prompt.write(': $description');
        }
        prompt.write('\n');
      }
      prompt.write('\n');
    }

    // Add dietary restrictions if provided
    if (dietaryRestrictions != null && dietaryRestrictions.isNotEmpty) {
      prompt.write('Dietary restrictions: ${dietaryRestrictions.join(', ')}\n\n');
      prompt.write('Based on the menu above, recommend dishes that fit these dietary restrictions. ');
    } else {
      prompt.write('Based on the menu above, recommend the most popular or signature dishes. ');
    }

    prompt.write(isTraditionalChinese
        ? '請提供3個推薦菜式並解釋為何推薦。'
        : 'Provide 3 recommendations with reasons why you recommend them.');

    return generate(
      prompt.toString(),
      temperature: 0.7,
      maxTokens: 400,
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
