import 'package:flutter/material.dart';

/// Utility class for processing AI responses
/// 
/// Handles:
/// - Removing context markers like [CONTEXT: ...] and [END OF CONTEXT]
/// - Converting markdown formatting to Flutter rich text
/// - Cleaning up unwanted formatting artifacts
class AIResponseProcessor {
  /// Clean AI response by removing context markers and processing markdown
  static String cleanResponse(String response) {
    String cleaned = response;
    
    // Remove context markers
    cleaned = _removeContextMarkers(cleaned);
    
    // Clean up extra whitespace
    cleaned = _cleanWhitespace(cleaned);
    
    return cleaned;
  }
  
  /// Convert markdown-formatted text to Flutter RichText widgets
  static List<TextSpan> parseMarkdownToSpans(String text, {
    TextStyle? defaultStyle,
    TextStyle? boldStyle,
    TextStyle? italicStyle,
  }) {
    final spans = <TextSpan>[];
    final buffer = StringBuffer();
    
    // Default styles
    defaultStyle ??= const TextStyle();
    boldStyle ??= defaultStyle.copyWith(fontWeight: FontWeight.bold);
    italicStyle ??= defaultStyle.copyWith(fontStyle: FontStyle.italic);
    
    int i = 0;
    while (i < text.length) {
      // Check for bold markdown **text**
      if (i < text.length - 1 && text.substring(i, i + 2) == '**') {
        // Add any accumulated text as normal span
        if (buffer.isNotEmpty) {
          spans.add(TextSpan(text: buffer.toString(), style: defaultStyle));
          buffer.clear();
        }
        
        // Find closing **
        int closeIndex = text.indexOf('**', i + 2);
        if (closeIndex != -1) {
          String boldText = text.substring(i + 2, closeIndex);
          spans.add(TextSpan(text: boldText, style: boldStyle));
          i = closeIndex + 2;
          continue;
        }
      }
      
      // Check for italic markdown *text*
      if (text[i] == '*' && (i == 0 || text[i - 1] != '*') && 
          (i == text.length - 1 || text[i + 1] != '*')) {
        // Add any accumulated text as normal span
        if (buffer.isNotEmpty) {
          spans.add(TextSpan(text: buffer.toString(), style: defaultStyle));
          buffer.clear();
        }
        
        // Find closing *
        int closeIndex = text.indexOf('*', i + 1);
        if (closeIndex != -1) {
          String italicText = text.substring(i + 1, closeIndex);
          spans.add(TextSpan(text: italicText, style: italicStyle));
          i = closeIndex + 1;
          continue;
        }
      }
      
      // Regular character
      buffer.write(text[i]);
      i++;
    }
    
    // Add any remaining text
    if (buffer.isNotEmpty) {
      spans.add(TextSpan(text: buffer.toString(), style: defaultStyle));
    }
    
    return spans;
  }
  
  /// Create a RichText widget from markdown text
  static Widget buildRichText(String text, {
    TextStyle? defaultStyle,
    TextStyle? boldStyle,
    TextStyle? italicStyle,
    TextAlign? textAlign,
  }) {
    final spans = parseMarkdownToSpans(
      text,
      defaultStyle: defaultStyle,
      boldStyle: boldStyle,
      italicStyle: italicStyle,
    );
    
    return RichText(
      textAlign: textAlign ?? TextAlign.start,
      text: TextSpan(children: spans),
    );
  }
  
  /// Remove context markers from AI response
  static String _removeContextMarkers(String text) {
    String cleaned = text;
    
    // Remove [CONTEXT: ...] blocks
    cleaned = cleaned.replaceAll(RegExp(r'\[CONTEXT:.*?\]', dotAll: true), '');
    
    // Remove [END OF CONTEXT] markers
    cleaned = cleaned.replaceAll(RegExp(r'\[END OF CONTEXT\]', caseSensitive: false), '');
    
    // Remove other common context markers
    cleaned = cleaned.replaceAll(RegExp(r'\[.*?CONTEXT.*?\]', caseSensitive: false), '');
    
    return cleaned;
  }
  
  /// Clean up whitespace and formatting
  static String _cleanWhitespace(String text) {
    String cleaned = text;
    
    // Remove leading/trailing whitespace first
    cleaned = cleaned.trim();
    
    // Remove spaces at the beginning of lines
    cleaned = cleaned.replaceAll(RegExp(r'^\s+', multiLine: true), '');
    
    // Remove excessive newlines (more than 2 consecutive) - do this last
    cleaned = cleaned.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    
    return cleaned;
  }
  
  /// Check if text contains markdown formatting
  static bool hasMarkdownFormatting(String text) {
    return text.contains('**') || 
           text.contains(RegExp(r'(?<!\*)\*(?!\*)')) ||
           text.contains('_') ||
           text.contains('#');
  }
  
  /// Extract plain text from markdown (remove all formatting)
  static String toPlainText(String markdownText) {
    String plain = markdownText;
    
    // Remove bold **text**
    plain = plain.replaceAllMapped(RegExp(r'\*\*(.*?)\*\*'), (match) => match.group(1)!);
    
    // Remove italic *text* (but not **text**)
    plain = plain.replaceAllMapped(RegExp(r'(?<!\*)\*([^*]+?)\*(?!\*)'), (match) => match.group(1)!);
    
    // Remove other markdown elements as needed
    plain = plain.replaceAll(RegExp(r'#{1,6}\s*'), ''); // Headers
    plain = plain.replaceAllMapped(RegExp(r'`(.*?)`'), (match) => match.group(1)!); // Inline code
    
    return plain;
  }
}