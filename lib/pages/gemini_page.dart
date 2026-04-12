import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/gemini_service.dart';
import '../widgets/ai/suggestion_chips.dart';
import '../widgets/common/loading_indicator.dart';
import '../utils/ai_response_processor.dart';
import '../models.dart';

/// Gemini AI Chat Page
///
/// Full-screen chat interface with Google Gemini AI.
/// Features:
/// - Conversational chat with maintained history
/// - Suggested questions for quick interaction
/// - Context-aware responses with menu support (PRIORITY: Menu questions first)
/// - Bilingual support (EN/TC)
/// - Loading states and error handling
/// - Guest user support (no login required)
class GeminiChatRoomPage extends StatefulWidget {
  final bool isTraditionalChinese;
  final String? restaurantName;
  final String? restaurantCuisine;
  final String? restaurantDistrict;
  final String? restaurantId; // For fetching menu items

  const GeminiChatRoomPage({
    required this.isTraditionalChinese,
    this.restaurantName,
    this.restaurantCuisine,
    this.restaurantDistrict,
    this.restaurantId, // Optional restaurant ID for menu context
    super.key,
  });

  @override
  State<GeminiChatRoomPage> createState() => _GeminiChatRoomPageState();
}

class _GeminiChatRoomPageState extends State<GeminiChatRoomPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Restore previous conversation from service if it exists
      final geminiService = context.read<GeminiService>();
      if (geminiService.displayMessages.isNotEmpty) {
        setState(() {
          _messages.addAll(geminiService.displayMessages);
        });
        _scrollToBottom();
      } else {
        _addWelcomeMessage();
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addWelcomeMessage() {
    final msg = {
      'role': 'model',
      'content': _buildWelcomeMessage(),
      'timestamp': DateTime.now(),
    };
    setState(() {
      _messages.add(msg);
    });
    // Persist to service so the welcome message survives page dispose
    context.read<GeminiService>().addDisplayMessage(msg);
  }

  /// Build welcome message based on context
  String _buildWelcomeMessage() {
    if (widget.restaurantName != null) {
      return widget.isTraditionalChinese
          ? '哈囉！我在這裡幫你答關於${widget.restaurantName}嘅問題，包括菜單、開放時間、聯絡方法等等。有咩想知隨時問啦！'
          : 'Hey! I\'m here to answer any questions about ${widget.restaurantName} — menu, opening hours, contact info, you name it. Just ask away!';
    } else {
      return widget.isTraditionalChinese
          ? '哈囉！我是你嘅素食餐廳助手嚟㗎。我可以幫你推介餐廳、答問題，或者畀啲食飯建議你。有咩可以幫到你呀？'
          : 'Hey! I\'m your vegetarian restaurant mate. I can recommend places, answer questions, or give you some dining tips. What can I do for you?';
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    final geminiService = context.read<GeminiService>();

    // Add user message to UI and persist to service
    final userMsg = {
      'role': 'user',
      'content': message,
      'timestamp': DateTime.now(),
    };
    setState(() {
      _messages.add(userMsg);
    });
    geminiService.addDisplayMessage(userMsg);

    _messageController.clear();
    _scrollToBottom();

    // Get AI response
    String? response;
    if (widget.restaurantId != null) {
      // Restaurant-specific chat: server fetches info + menu from Firestore automatically
      response = await geminiService.chatAboutRestaurant(
        widget.restaurantId!,
        message,
      );
    } else if (widget.restaurantName != null) {
      // Fallback: no restaurantId — use client-side context
      response = await geminiService.askAboutRestaurant(
        message,
        widget.restaurantName!,
        cuisine: widget.restaurantCuisine,
        district: widget.restaurantDistrict,
      );
    } else {
      // General chat
      response = await geminiService.chat(message);
    }

    // Add AI response to UI and persist to service
    if (response != null) {
      // Clean the response to remove context markers and process markdown
      final cleanedResponse = AIResponseProcessor.cleanResponse(response);
      final aiMsg = {
        'role': 'model',
        'content': cleanedResponse,
        'timestamp': DateTime.now(),
      };
      setState(() {
        _messages.add(aiMsg);
      });
      geminiService.addDisplayMessage(aiMsg);
      _scrollToBottom();
    } else if (geminiService.errorMessage != null) {
      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(geminiService.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onSuggestionTapped(String suggestion) {
    _messageController.text = suggestion;
    _sendMessage(suggestion);
  }

  Widget _buildMessage(Map<String, dynamic> message) {
    final isUser = message['role'] == 'user';
    final content = message['content'] as String;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          left: isUser ? 64 : 16,
          right: isUser ? 16 : 64,
          top: 4,
          bottom: 4,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isUser)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.purple.shade400,
                          Colors.blue.shade400,
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                if (!isUser) const SizedBox(width: 8),
                Text(
                  isUser
                      ? (widget.isTraditionalChinese ? '您' : 'You')
                      : (widget.isTraditionalChinese ? 'AI 助手' : 'AI'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: isUser
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Use RichText for AI responses to support markdown formatting
            isUser 
              ? Text(
                  content,
                  style: TextStyle(
                    fontSize: 15,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    height: 1.4,
                  ),
                )
              : AIResponseProcessor.hasMarkdownFormatting(content)
                ? AIResponseProcessor.buildRichText(
                    content,
                    defaultStyle: TextStyle(
                      fontSize: 15,
                      color: Theme.of(context).colorScheme.onSurface,
                      height: 1.4,
                    ),
                    boldStyle: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                      height: 1.4,
                    ),
                    italicStyle: TextStyle(
                      fontSize: 15,
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context).colorScheme.onSurface,
                      height: 1.4,
                    ),
                  )
                : Text(
                    content,
                    style: TextStyle(
                      fontSize: 15,
                      color: Theme.of(context).colorScheme.onSurface,
                      height: 1.4,
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    final geminiService = context.watch<GeminiService>();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: widget.isTraditionalChinese
                    ? '輸入訊息...'
                    : 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: geminiService.isLoading ? null : _sendMessage,
              enabled: !geminiService.isLoading,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.purple.shade400,
                  Colors.blue.shade400,
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: geminiService.isLoading
                  ? null
                  : () => _sendMessage(_messageController.text),
              icon: geminiService.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: LoadingIndicator.small(),
                    )
                  : const Icon(Icons.send, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.restaurantName != null
        ? widget.restaurantName!
        : (widget.isTraditionalChinese ? 'AI 助手' : 'AI Assistant');

    final subtitle = widget.restaurantName != null
        ? (widget.isTraditionalChinese ? 'AI 助手' : 'AI Assistant')
        : (widget.isTraditionalChinese ? '素食餐廳顧問' : 'Dining Consultant');

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(widget.isTraditionalChinese
                      ? '清除對話'
                      : 'Clear Conversation'),
                  content: Text(widget.isTraditionalChinese
                      ? '確定要清除所有對話記錄嗎？'
                      : 'Clear all conversation history?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                          widget.isTraditionalChinese ? '取消' : 'Cancel'),
                    ),
                    FilledButton(
                      onPressed: () {
                        setState(() {
                          _messages.clear();
                          _addWelcomeMessage();
                        });
                        context.read<GeminiService>().clearHistory();
                        Navigator.pop(context);
                      },
                      child:
                          Text(widget.isTraditionalChinese ? '清除' : 'Clear'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.delete_outline),
            tooltip: widget.isTraditionalChinese ? '清除對話' : 'Clear chat',
          ),
        ],
      ),
      body: Column(
        children: [
          // Suggestion chips
          if (_messages.length <= 1)
            SuggestionChips(
              isTraditionalChinese: widget.isTraditionalChinese,
              onSuggestionTapped: _onSuggestionTapped,
              restaurantName: widget.restaurantName,
            ),
          const Divider(height: 1),

          // Messages list
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.purple.shade400,
                                Colors.blue.shade400,
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.isTraditionalChinese
                              ? '開始對話'
                              : 'Start a conversation',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessage(_messages[index]);
                    },
                  ),
          ),

          // Message input
          _buildMessageInput(),
        ],
      ),
    );
  }
}
