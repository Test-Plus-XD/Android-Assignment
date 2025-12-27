# AI Response Processor

This utility processes AI responses to clean up context markers and convert markdown formatting to Flutter-compatible rich text.

## Features

- **Context Removal**: Removes `[CONTEXT: ...]` and `[END OF CONTEXT]` markers
- **Markdown Processing**: Converts `**bold**` and `*italic*` to Flutter TextSpan widgets
- **Whitespace Cleanup**: Removes excessive newlines and leading spaces

## Usage

```dart
import '../utils/ai_response_processor.dart';

// Clean AI response
String rawResponse = "[CONTEXT: Restaurant info] This is **important** text.";
String cleaned = AIResponseProcessor.cleanResponse(rawResponse);
// Result: "This is **important** text."

// Convert to rich text widget
Widget richText = AIResponseProcessor.buildRichText(
  cleaned,
  defaultStyle: TextStyle(fontSize: 16),
  boldStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
);

// Check if text has markdown
bool hasMarkdown = AIResponseProcessor.hasMarkdownFormatting(cleaned);

// Convert to plain text
String plainText = AIResponseProcessor.toPlainText(cleaned);
// Result: "This is important text."
```

## Integration

The processor is automatically used in:
- `GeminiService` - cleans responses at the API level
- `GeminiChatRoomPage` - renders rich text for AI messages