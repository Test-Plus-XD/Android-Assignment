/// Chat history item for Gemini conversations
///
/// Represents a single turn in a conversation with the AI
class GeminiChatHistory {
  final String role; // 'user' or 'model'
  final String content;

  GeminiChatHistory({
    required this.role,
    required this.content,
  });

  factory GeminiChatHistory.fromJson(Map<String, dynamic> json) {
    return GeminiChatHistory(
      role: json['role'] ?? 'user',
      content: json['content'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'parts': [{'text': content}],
    };
  }
}

/// Request model for Gemini generate endpoint
///
/// Configure text generation parameters for one-shot responses
class GeminiGenerateRequest {
  final String prompt;
  final String? model;
  final double? temperature;
  final int? maxTokens;
  final double? topP;
  final int? topK;

  GeminiGenerateRequest({
    required this.prompt,
    this.model,
    this.temperature,
    this.maxTokens,
    this.topP,
    this.topK,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'prompt': prompt,
    };
    if (model != null) json['model'] = model;
    if (temperature != null) json['temperature'] = temperature;
    if (maxTokens != null) json['maxTokens'] = maxTokens;
    if (topP != null) json['topP'] = topP;
    if (topK != null) json['topK'] = topK;
    return json;
  }
}

/// Response model for Gemini generate endpoint
///
/// Contains generated text and token usage statistics
class GeminiGenerateResponse {
  final String result;
  final String model;
  final int? promptTokens;
  final int? completionTokens;
  final int? totalTokens;

  GeminiGenerateResponse({
    required this.result,
    required this.model,
    this.promptTokens,
    this.completionTokens,
    this.totalTokens,
  });

  factory GeminiGenerateResponse.fromJson(Map<String, dynamic> json) {
    return GeminiGenerateResponse(
      result: json['result'] ?? '',
      model: json['model'] ?? 'gemini-2.5-flash-lite-preview-09-2025',
      promptTokens: json['promptTokens'],
      completionTokens: json['completionTokens'],
      totalTokens: json['totalTokens'],
    );
  }
}

/// Request model for Gemini chat endpoint
///
/// Multi-turn conversation with conversation history
class GeminiChatRequest {
  final String message;
  final List<GeminiChatHistory>? history;
  final String? model;

  GeminiChatRequest({
    required this.message,
    this.history,
    this.model,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'message': message,
    };
    if (history != null) {
      json['history'] = history!.map((h) => h.toJson()).toList();
    }
    if (model != null) json['model'] = model;
    return json;
  }
}

/// Response model for Gemini chat endpoint
///
/// Contains AI response and updated conversation history
class GeminiChatResponse {
  final String result;
  final String model;
  final List<GeminiChatHistory>? history;

  GeminiChatResponse({
    required this.result,
    required this.model,
    this.history,
  });

  factory GeminiChatResponse.fromJson(Map<String, dynamic> json) {
    List<GeminiChatHistory>? historyList;
    if (json['history'] != null) {
      historyList = (json['history'] as List)
          .map((h) => GeminiChatHistory(
                role: h['role'] ?? 'user',
                content: h['parts'] != null && h['parts'].isNotEmpty
                    ? h['parts'][0]['text'] ?? ''
                    : '',
              ))
          .toList();
    }

    return GeminiChatResponse(
      result: json['result'] ?? '',
      model: json['model'] ?? 'gemini-2.5-flash-lite-preview-09-2025',
      history: historyList,
    );
  }
}

/// Request model for restaurant description generation
///
/// Generate marketing copy for a restaurant
class GeminiRestaurantDescriptionRequest {
  final String name;
  final String? cuisine;
  final String? district;
  final List<String>? keywords;
  final String? language;

  GeminiRestaurantDescriptionRequest({
    required this.name,
    this.cuisine,
    this.district,
    this.keywords,
    this.language,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'name': name,
    };
    if (cuisine != null) json['cuisine'] = cuisine;
    if (district != null) json['district'] = district;
    if (keywords != null) json['keywords'] = keywords;
    if (language != null) json['language'] = language;
    return json;
  }
}

/// Response model for restaurant description generation
///
/// Contains generated description and optional restaurant data
class GeminiRestaurantDescriptionResponse {
  final String description;
  final Map<String, dynamic>? restaurant;

  GeminiRestaurantDescriptionResponse({
    required this.description,
    this.restaurant,
  });

  factory GeminiRestaurantDescriptionResponse.fromJson(
      Map<String, dynamic> json) {
    return GeminiRestaurantDescriptionResponse(
      description: json['description'] ?? '',
      restaurant: json['restaurant'],
    );
  }
}
