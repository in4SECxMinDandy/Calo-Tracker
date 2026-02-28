// Chatbot Screen - AI Dinh dưỡng thông minh
// Tích hợp Gemini AI với intent recognition (INFO/LOG/CHAT)
// Hỗ trợ contextual memory và tự động ghi nhật ký
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../../models/meal.dart';
import '../../services/database_service.dart';
import '../../services/nutrition_ai_service.dart';
import '../../theme/colors.dart';

class ChatbotScreen extends StatefulWidget {
  final VoidCallback? onMealAdded;

  const ChatbotScreen({super.key, this.onMealAdded});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final NutritionAIService _aiService = NutritionAIService();
  final List<_ChatItem> _messages = [];
  bool _isLoading = false;

  late AnimationController _typingController;
  late Animation<double> _typingAnimation;

  @override
  void initState() {
    super.initState();
    _typingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _typingAnimation = CurvedAnimation(
      parent: _typingController,
      curve: Curves.easeInOut,
    );

    _addWelcomeMessage();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingController.dispose();
    super.dispose();
  }

  void _addWelcomeMessage() {
    _messages.add(
      _ChatItem.bot(
        '👋 Xin chào! Tôi là **Trợ lý Dinh dưỡng AI** của CaloTracker.\n\n'
        'Tôi có thể giúp bạn:\n'
        '• 🔍 **Tra cứu** calo và dinh dưỡng của món ăn\n'
        '• 📝 **Ghi nhật ký** bữa ăn tự động\n'
        '• 💬 **Tư vấn** chế độ ăn uống lành mạnh\n\n'
        'Hãy thử hỏi: _"1 bát phở bao nhiêu calo?"_ hoặc _"Tôi vừa ăn 2 quả trứng"_',
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage([String? text]) async {
    final message = (text ?? _messageController.text).trim();
    if (message.isEmpty || _isLoading) return;

    _messageController.clear();
    HapticFeedback.lightImpact();

    setState(() {
      _messages.add(_ChatItem.user(message));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final response = await _aiService.processMessage(message);

      if (mounted) {
        setState(() {
          _messages.add(_ChatItem.bot(response.reply, aiResponse: response));
          _isLoading = false;
        });
        _scrollToBottom();

        // Auto-log if action is LOG
        if (response.action == NutritionIntent.log &&
            response.logData != null) {
          await _autoLogMeal(response.logData!);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(
            _ChatItem.bot(
              '❌ Xin lỗi, đã xảy ra lỗi. Vui lòng thử lại sau.',
            ),
          );
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _autoLogMeal(LogData logData) async {
    try {
      final meal = Meal(
        dateTime: DateTime.now(),
        foodName: logData.foodName,
        calories: logData.calories.toDouble(),
        weight: logData.quantity,
        source: 'ai_chatbot',
      );
      await DatabaseService.insertMeal(meal);
      widget.onMealAdded?.call();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  CupertinoIcons.checkmark_circle_fill,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '✅ Đã ghi: ${logData.foodName} (${logData.calories} kcal)',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.successGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('Auto-log error: $e');
    }
  }

  void _clearChat() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa lịch sử chat'),
        content: const Text('Bạn có chắc muốn xóa toàn bộ lịch sử chat?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _messages.clear();
                _aiService.clearHistory();
              });
              _addWelcomeMessage();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.errorRed),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : const Color(0xFFF0F2F5),
      appBar: _buildAppBar(isDark),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isLoading && index == _messages.length) {
                  return _buildTypingIndicator(isDark);
                }
                return _buildMessageBubble(_messages[index], isDark);
              },
            ),
          ),

          // Quick suggestions
          _buildQuickSuggestions(isDark),

          // Input field
          _buildInputField(isDark),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          CupertinoIcons.back,
          color: isDark ? Colors.white : Colors.black87,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              CupertinoIcons.sparkles,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Dinh dưỡng',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.successGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Đang hoạt động',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.successGreen,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(
            CupertinoIcons.trash,
            color: isDark ? Colors.white70 : Colors.black54,
            size: 20,
          ),
          onPressed: _clearChat,
          tooltip: 'Xóa lịch sử',
        ),
      ],
    );
  }

  Widget _buildMessageBubble(_ChatItem item, bool isDark) {
    final isUser = item.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            // Bot avatar
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                CupertinoIcons.sparkles,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Message bubble
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isUser
                        ? AppColors.primaryBlue
                        : (isDark ? AppColors.darkCard : Colors.white),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _buildMessageContent(item, isUser, isDark),
                ),

                // Action badge for LOG
                if (!isUser &&
                    item.aiResponse?.action == NutritionIntent.log &&
                    item.aiResponse?.logData != null) ...[
                  const SizedBox(height: 4),
                  _buildLogBadge(item.aiResponse!.logData!, isDark),
                ],

                // Timestamp
                const SizedBox(height: 2),
                Text(
                  _formatTime(item.timestamp),
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary,
                  ),
                ),
              ],
            ),
          ),

          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildMessageContent(
    _ChatItem item,
    bool isUser,
    bool isDark,
  ) {
    // Parse markdown-like formatting
    final text = item.content;
    final spans = _parseMarkdown(text, isUser, isDark);

    return Text.rich(
      TextSpan(children: spans),
      style: TextStyle(
        fontSize: 14,
        height: 1.5,
        color: isUser
            ? Colors.white
            : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
      ),
    );
  }

  List<InlineSpan> _parseMarkdown(String text, bool isUser, bool isDark) {
    final spans = <InlineSpan>[];
    final baseColor = isUser
        ? Colors.white
        : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary);

    // Simple markdown parsing for **bold** and _italic_
    final regex = RegExp(r'\*\*(.*?)\*\*|_(.*?)_');
    int lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: TextStyle(color: baseColor),
        ));
      }

      if (match.group(1) != null) {
        // Bold
        spans.add(TextSpan(
          text: match.group(1),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: baseColor,
          ),
        ));
      } else if (match.group(2) != null) {
        // Italic
        spans.add(TextSpan(
          text: match.group(2),
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: baseColor.withValues(alpha: 0.8),
          ),
        ));
      }

      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: TextStyle(color: baseColor),
      ));
    }

    return spans.isEmpty
        ? [TextSpan(text: text, style: TextStyle(color: baseColor))]
        : spans;
  }

  Widget _buildLogBadge(LogData logData, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.successGreen.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.successGreen.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            CupertinoIcons.checkmark_circle_fill,
            size: 12,
            color: AppColors.successGreen,
          ),
          const SizedBox(width: 4),
          Text(
            '${logData.foodName} • ${logData.calories} kcal đã ghi',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.successGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              CupertinoIcons.sparkles,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return AnimatedBuilder(
                  animation: _typingAnimation,
                  builder: (_, __) {
                    final delay = i * 0.3;
                    final value = ((_typingAnimation.value - delay) % 1.0)
                        .clamp(0.0, 1.0);
                    final opacity = value < 0.5 ? value * 2 : (1 - value) * 2;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(
                          alpha: 0.3 + opacity * 0.7,
                        ),
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSuggestions(bool isDark) {
    final suggestions = [
      '🍜 Phở bò bao nhiêu calo?',
      '🍚 Tôi vừa ăn 1 bát cơm',
      '🥚 2 quả trứng luộc',
      '☕ Ghi cafe sữa đá',
      '🥗 Salad rau củ',
      '🍗 Gà nướng 200g',
    ];

    return Container(
      height: 44,
      color: isDark ? AppColors.darkCard : Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _sendMessage(suggestions[index]),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                suggestions[index],
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputField(bool isDark) {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Hỏi về calo hoặc ghi nhật ký...',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                maxLines: 3,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isLoading ? null : () => _sendMessage(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: _isLoading
                    ? null
                    : const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                      ),
                color: _isLoading
                    ? (isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.2))
                    : null,
                shape: BoxShape.circle,
                boxShadow: _isLoading
                    ? null
                    : [
                        BoxShadow(
                          color: AppColors.primaryBlue.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
              ),
              child: Icon(
                _isLoading
                    ? CupertinoIcons.hourglass
                    : CupertinoIcons.arrow_up,
                color: _isLoading
                    ? (isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary)
                    : Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

// ══════════════════════════════════════════════════════════════
// CHAT ITEM MODEL
// ══════════════════════════════════════════════════════════════
class _ChatItem {
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final NutritionAIResponse? aiResponse;

  _ChatItem({
    required this.content,
    required this.isUser,
    this.aiResponse,
  }) : timestamp = DateTime.now();

  factory _ChatItem.user(String content) =>
      _ChatItem(content: content, isUser: true);

  factory _ChatItem.bot(String content, {NutritionAIResponse? aiResponse}) =>
      _ChatItem(content: content, isUser: false, aiResponse: aiResponse);
}
