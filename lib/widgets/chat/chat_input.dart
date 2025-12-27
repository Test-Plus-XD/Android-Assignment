import 'package:flutter/material.dart';
import '../../services/image_service.dart';
import '../images/image_preview.dart';
import 'dart:io';

/// Chat Input Widget
///
/// Message input field with:
/// - Text input
/// - Send button
/// - Optional image attachment
/// - Typing indicator
/// - Character limit (optional)
class ChatInput extends StatefulWidget {
  final Function(String message, {String? imageUrl}) onSend;
  final Function(bool isTyping)? onTypingChanged;
  final bool isTraditionalChinese;
  final ImageService? imageService;
  final bool allowImages;

  const ChatInput({
    super.key,
    required this.onSend,
    this.onTypingChanged,
    this.isTraditionalChinese = false,
    this.imageService,
    this.allowImages = true,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  File? _selectedImage;
  String? _uploadedImageUrl;
  bool _isSending = false;
  bool _isTyping = false;
  bool _canSend = false; // Add explicit state for send button

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    final canSend = hasText || _uploadedImageUrl != null;
    
    if (hasText != _isTyping) {
      setState(() {
        _isTyping = hasText;
      });
      widget.onTypingChanged?.call(_isTyping);
    }
    
    if (canSend != _canSend) {
      setState(() {
        _canSend = canSend;
      });
    }
  }

  Future<void> _pickImage() async {
    if (widget.imageService == null) return;

    final image = await widget.imageService!.showImageSourceDialog(context);
    if (image != null) {
      setState(() {
        _selectedImage = image;
        _uploadedImageUrl = null;
      });

      // Upload image immediately in background (like Ionic app does)
      await _uploadImage();
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null || widget.imageService == null) return;

    setState(() => _isSending = true);

    try {
      final url = await widget.imageService!.uploadImage(
        imageFile: _selectedImage!,
        folder: 'Chat',
      );
      if (url != null) {
        setState(() {
          _uploadedImageUrl = url;
          _canSend = _controller.text.trim().isNotEmpty || url != null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isTraditionalChinese ? '圖片上傳失敗' : 'Failed to upload image',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _uploadedImageUrl = null;
      _canSend = _controller.text.trim().isNotEmpty;
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();

    // Require either text or uploaded image
    if (text.isEmpty && _uploadedImageUrl == null) {
      return;
    }

    setState(() => _isSending = true);

    try {
      // Send message with text and/or image URL
      // Use placeholder text "Image" if only sending image (like Ionic app)
      final messageText = text.isNotEmpty ? text : 'Image';
      await widget.onSend(messageText, imageUrl: _uploadedImageUrl);

      // Clear input
      _controller.clear();
      _removeImage();
      setState(() {
        _canSend = false;
      });
      widget.onTypingChanged?.call(false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isTraditionalChinese ? '發送失敗' : 'Failed to send message',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image preview
            if (_selectedImage != null)
              Container(
                padding: const EdgeInsets.all(8),
                child: Stack(
                  children: [
                    SquareImagePreview(
                      image: _selectedImage,
                      size: 80,
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: _removeImage,
                        style: IconButton.styleFrom(
                          backgroundColor: theme.colorScheme.errorContainer,
                          foregroundColor: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Input field
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  // Image button
                  if (widget.allowImages && widget.imageService != null)
                    IconButton(
                      icon: const Icon(Icons.image),
                      onPressed: _isSending ? null : _pickImage,
                      tooltip: widget.isTraditionalChinese ? '添加圖片' : 'Add image',
                    ),

                  // Text field
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      enabled: !_isSending,
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _canSend ? _sendMessage() : null,
                      decoration: InputDecoration(
                        hintText: widget.isTraditionalChinese ? '輸入訊息...' : 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Send button
                  IconButton(
                    icon: _isSending
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colorScheme.primary,
                            ),
                          )
                        : const Icon(Icons.send),
                    onPressed: _canSend && !_isSending ? _sendMessage : null,
                    tooltip: widget.isTraditionalChinese ? '發送' : 'Send',
                    style: IconButton.styleFrom(
                      backgroundColor: _canSend && !_isSending
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceContainerHighest,
                      foregroundColor: _canSend && !_isSending
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
