// Chatbot Screen - AI Dinh dưỡng thông minh
// Tích hợp Gemini AI với intent recognition (INFO/LOG/CHAT)
// Hỗ trợ contextual memory và tự động ghi nhật ký
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../models/meal.dart';
import '../../models/sleep_record.dart';
import '../../models/chat_message.dart';
import '../../models/conversation.dart';
import '../../services/database_service.dart';
import '../../services/nutrition_ai_service.dart';
import '../../services/water_service.dart';
import '../../services/meal_suggestion_service.dart';
import '../../theme/colors.dart';
import '../../utils/time_formatter.dart';
import 'package:uuid/uuid.dart';

class ChatbotScreen extends StatefulWidget {
  final VoidCallback? onMealAdded;
  final VoidCallback? onSleepAdded;
  final VoidCallback? onWaterAdded;

  const ChatbotScreen({
    super.key,
    this.onMealAdded,
    this.onSleepAdded,
    this.onWaterAdded,
  });

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
  bool _isLoadingHistory = true;

  // Current conversation ID
  String? _currentConversationId;

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

    _initConversation();
  }

  Future<void> _initConversation() async {
    // Get or create current conversation
    _currentConversationId =
        await DatabaseService.getOrCreateCurrentConversation();
    await _loadChatHistory();
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

  Future<void> _loadChatHistory() async {
    try {
      // Load messages for current conversation
      final conversationId = _currentConversationId ?? 'default';
      final history = await DatabaseService.getMessagesByConversation(
        conversationId,
      );

      if (!mounted) return;

      setState(() {
        _isLoadingHistory = false;
        if (history.isEmpty) {
          // No history, show welcome message
          _addWelcomeMessage();
        } else {
          // Load history into messages
          _messages.addAll(
            history.map(
              (msg) => _ChatItem(
                content: msg.message,
                isUser: msg.isUser,
                timestamp: msg.timestamp,
                nutritionData: msg.nutrition,
              ),
            ),
          );
          // Load into AI context for conversation continuity
          _aiService.loadConversationHistory(history);
        }
      });
    } catch (e) {
      debugPrint('Error loading chat history: $e');
      if (mounted) {
        setState(() {
          _isLoadingHistory = false;
          _addWelcomeMessage();
        });
      }
    }
  }

  Future<void> _startNewConversation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Cuộc trò chuyện mới'),
            content: const Text(
              'Bạn muốn bắt đầu cuộc trò chuyện mới? Cuộc trò chuyện hiện tại vẫn được lưu trong lịch sử.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Tạo mới'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        final newId = await _aiService.startNewConversation();

        setState(() {
          _currentConversationId = newId;
          _messages.clear();
        });

        _addWelcomeMessage();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    CupertinoIcons.sparkles,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  const Text('Đã bắt đầu cuộc trò chuyện mới'),
                ],
              ),
              backgroundColor: AppColors.primaryBlue,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        debugPrint('Error starting new conversation: $e');
      }
    }
  }

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Đang tải lịch sử...',
            style: TextStyle(
              color:
                  isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
            ),
          ),
        ],
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

    final userMessageId = const Uuid().v4();
    final botMessageId = const Uuid().v4();
    final now = DateTime.now();

    setState(() {
      _messages.add(_ChatItem(content: message, isUser: true, timestamp: now));
      _isLoading = true;
    });
    _scrollToBottom();

    // Save user message to database with conversation ID
    try {
      final conversationId = _currentConversationId ?? 'default';
      await DatabaseService.insertChatMessage(
        ChatMessage(
          id: userMessageId,
          conversationId: conversationId,
          timestamp: now,
          message: message,
          isUser: true,
        ),
      );
      // Update conversation timestamp
      await DatabaseService.updateConversationTimestamp(conversationId);
    } catch (e) {
      debugPrint('Error saving user message: $e');
    }

    try {
      final response = await _aiService.processMessage(message);

      // #region agent log
      debugPrint(
        '[AI-LOG-DBG] action=${response.action} hasLogData=${response.logData != null} '
        'willAutoLog=${response.action == NutritionIntent.log && response.logData != null}',
      );
      // #endregion

      if (mounted) {
        setState(() {
          _messages.add(_ChatItem.bot(response.reply, aiResponse: response));
          _isLoading = false;
        });
        _scrollToBottom();

        // Save bot response to database (with nutrition data if available)
        NutritionData? nutritionData;
        if (response.logData != null) {
          nutritionData = NutritionData(
            calories: response.logData!.calories,
            protein: response.logData!.protein,
            carbs: response.logData!.carbs,
            fat: response.logData!.fat,
            foods: [
              FoodItem(
                name: response.logData!.foodName,
                calories: response.logData!.calories,
                weight: response.logData!.quantity,
              ),
            ],
          );
        }

        try {
          final conversationId = _currentConversationId ?? 'default';
          await DatabaseService.insertChatMessage(
            ChatMessage(
              id: botMessageId,
              conversationId: conversationId,
              timestamp: DateTime.now(),
              message: response.reply,
              isUser: false,
              nutrition: nutritionData,
            ),
          );
          // Update conversation timestamp
          await DatabaseService.updateConversationTimestamp(conversationId);
        } catch (e) {
          debugPrint('Error saving bot message: $e');
        }

        // Auto-log if action is LOG
        if (response.action == NutritionIntent.log &&
            response.logData != null) {
          await _autoLogMeal(response.logData!);
        }

        // Auto-log if action is SLEEP
        if (response.action == NutritionIntent.sleep &&
            response.sleepLogData != null) {
          await _autoLogSleep(response.sleepLogData!);
        }

        // Auto-log if action is WATER
        if (response.action == NutritionIntent.water &&
            response.waterAmount != null) {
          await _autoLogWater(response.waterAmount!);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(
            _ChatItem.bot('❌ Xin lỗi, đã xảy ra lỗi. Vui lòng thử lại sau.'),
          );
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _autoLogWater(int amountMl) async {
    try {
      await WaterService.addWaterIntake(
        amountMl,
        note: 'Ghi nhận từ AI Chatbot',
      );

      // Refresh all screens (meals, sleep, water)
      widget.onMealAdded?.call();
      widget.onSleepAdded?.call();
      widget.onWaterAdded?.call();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  CupertinoIcons.drop_fill,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '✅ Đã ghi nhận: ${amountMl}ml nước',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.primaryBlue,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e, st) {
      debugPrint('[Chatbot] _autoLogWater failed: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  CupertinoIcons.exclamationmark_circle_fill,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '❌ Lỗi khi lưu nước uống: $e',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _autoLogSleep(SleepLogData logData) async {
    try {
      final now = DateTime.now();
      final wakeTime = logData.wakeTime ?? now;
      final bedTime =
          logData.bedTime ??
          wakeTime.subtract(Duration(minutes: (logData.hours * 60).toInt()));

      // For overnight sleep (bed after midnight), use the ACTUAL calendar date of bed_time.
      // For normal sleep, use the date of wake_time.
      // In most cases we associate sleep with the day you WOKE UP, so we use wake date.
      // But if bed_time's date is AFTER wake_time's date, it means the sleep started
      // yesterday — use the bed date so it shows in the correct day's history.
      DateTime sleepDate;
      if (bedTime.year > wakeTime.year ||
          (bedTime.year == wakeTime.year && bedTime.month > wakeTime.month) ||
          (bedTime.year == wakeTime.year &&
              bedTime.month == wakeTime.month &&
              bedTime.day > wakeTime.day)) {
        // Overnight sleep: started yesterday, wake up today
        // Associate with the date you went to bed
        sleepDate = DateTime(bedTime.year, bedTime.month, bedTime.day);
      } else {
        // Normal: went to bed and woke up on same calendar day
        sleepDate = DateTime(wakeTime.year, wakeTime.month, wakeTime.day);
      }

      final sleepRecord = SleepRecord(
        date: sleepDate,
        bedTime: bedTime,
        wakeTime: wakeTime,
        quality: SleepQuality.fromValue(logData.quality ?? 3),
        notes: 'Ghi nhận từ AI Chatbot',
      );

      await DatabaseService.insertSleepRecord(sleepRecord);

      // Refresh all screens (meals, sleep, water)
      widget.onMealAdded?.call();
      widget.onSleepAdded?.call();
      widget.onWaterAdded?.call();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  CupertinoIcons.moon_stars_fill,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '✅ Đã ghi giấc ngủ: ${logData.hours} giờ',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.primaryBlue,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e, st) {
      debugPrint('[Chatbot] _autoLogSleep failed: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  CupertinoIcons.exclamationmark_circle_fill,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '❌ Lỗi khi lưu giấc ngủ: $e',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _autoLogMeal(LogData logData) async {
    try {
      final meal = Meal(
        dateTime: DateTime.now(),
        foodName: logData.foodName,
        calories: logData.calories,
        weight: logData.quantity,
        protein: logData.protein,
        carbs: logData.carbs,
        fat: logData.fat,
        source: 'ai_chatbot',
      );
      await DatabaseService.insertMeal(meal);

      // Refresh all screens (meals, sleep, water)
      widget.onMealAdded?.call();
      widget.onSleepAdded?.call();
      widget.onWaterAdded?.call();

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
    } catch (e, st) {
      debugPrint('[Chatbot] _autoLogMeal failed: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  CupertinoIcons.exclamationmark_circle_fill,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '❌ Lỗi khi lưu bữa ăn: $e',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _clearChat() async {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Xóa cuộc trò chuyện'),
            content: const Text(
              'Bạn có chắc muốn xóa cuộc trò chuyện hiện tại?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    final conversationId = _currentConversationId ?? 'default';
                    await DatabaseService.deleteConversation(conversationId);
                    // Start a new conversation
                    final newId = await _aiService.startNewConversation();
                    setState(() {
                      _currentConversationId = newId;
                      _messages.clear();
                    });
                    _addWelcomeMessage();
                  } catch (e) {
                    debugPrint('Error clearing chat: $e');
                  }
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.errorRed,
                ),
                child: const Text('Xóa'),
              ),
            ],
          ),
    );
  }

  void _showHistoryBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            maxChildSize: 0.95,
            minChildSize: 0.5,
            builder:
                (context, scrollController) => _ChatHistorySheet(
                  scrollController: scrollController,
                  currentConversationId: _currentConversationId,
                  onSelectConversation: (conversationId, messages) {
                    Navigator.pop(context);
                    _loadConversation(conversationId, messages);
                  },
                ),
          ),
    );
  }

  void _loadConversation(String conversationId, List<ChatMessage> messages) {
    _aiService.clearHistory();
    setState(() {
      _currentConversationId = conversationId;
      _messages.clear();
      if (messages.isEmpty) {
        _addWelcomeMessage();
      } else {
        _messages.addAll(
          messages.map(
            (msg) => _ChatItem(
              content: msg.message,
              isUser: msg.isUser,
              timestamp: msg.timestamp,
              nutritionData: msg.nutrition,
            ),
          ),
        );
        _aiService.loadConversationHistory(messages);
      }
    });
    _scrollToBottom();
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
            child:
                _isLoadingHistory
                    ? _buildLoadingState(isDark)
                    : ListView.builder(
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
    final accent = isDark ? Colors.white : AppColors.primaryBlue;
    return AppBar(
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: IconButton(
        icon: Icon(CupertinoIcons.square_pencil, color: accent, size: 24),
        onPressed: _startNewConversation,
        tooltip: 'New Chat',
      ),
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              CupertinoIcons.sparkles,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Dinh dưỡng',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
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
                    Expanded(
                      child: Text(
                        'Đang hoạt động',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.successGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(
            CupertinoIcons.clock,
            color: isDark ? Colors.white70 : Colors.black54,
            size: 20,
          ),
          onPressed: _showHistoryBottomSheet,
          tooltip: 'Lịch sử chat',
        ),
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
                    color:
                        isUser
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

                // Meal suggestions for SUGGEST intent
                if (!isUser &&
                    item.aiResponse?.action == NutritionIntent.suggest &&
                    item.aiResponse?.suggestions != null &&
                    item.aiResponse!.suggestions!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildSuggestionCards(item.aiResponse!.suggestions!, isDark),
                ],

                // Timestamp
                const SizedBox(height: 2),
                Text(
                  formatHHmm(item.timestamp),
                  style: TextStyle(
                    fontSize: 10,
                    color:
                        isDark
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

  Widget _buildMessageContent(_ChatItem item, bool isUser, bool isDark) {
    final text = item.content;
    final baseColor =
        isUser
            ? Colors.white
            : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary);
    final secondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final divider =
        isDark ? Colors.white24 : Colors.black.withValues(alpha: 0.12);

    // Bot: tiêu đề #, bảng |, code fence — render Markdown đầy đủ
    if (!isUser && _looksLikeStructuredMarkdown(text)) {
      return MarkdownBody(
        data: text,
        shrinkWrap: true,
        selectable: true,
        styleSheet: MarkdownStyleSheet(
          p: TextStyle(fontSize: 14, height: 1.5, color: baseColor),
          h1: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: baseColor,
            height: 1.35,
          ),
          h2: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: baseColor,
            height: 1.35,
          ),
          h3: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: baseColor,
            height: 1.35,
          ),
          strong: TextStyle(fontWeight: FontWeight.w700, color: baseColor),
          em: TextStyle(
            fontStyle: FontStyle.italic,
            color: baseColor.withValues(alpha: 0.9),
          ),
          listBullet: TextStyle(color: baseColor, fontSize: 14),
          listIndent: 20,
          blockquote: TextStyle(color: secondary, fontSize: 14, height: 1.5),
          blockquoteDecoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: AppColors.primaryBlue, width: 3),
            ),
          ),
          code: TextStyle(
            fontSize: 13,
            fontFamily: 'monospace',
            color: baseColor,
            backgroundColor: isDark ? Colors.white10 : Colors.black12,
          ),
          codeblockDecoration: BoxDecoration(
            color: isDark ? Colors.white10 : Colors.black12,
            borderRadius: BorderRadius.circular(8),
          ),
          tableHead: TextStyle(
            fontWeight: FontWeight.w700,
            color: baseColor,
            fontSize: 13,
          ),
          tableBody: TextStyle(color: baseColor, fontSize: 13),
          tableBorder: TableBorder.all(color: divider, width: 0.5),
          horizontalRuleDecoration: BoxDecoration(
            border: Border(top: BorderSide(color: divider)),
          ),
        ),
      );
    }

    final spans = _parseMarkdown(text, isUser, isDark);
    return Text.rich(
      TextSpan(children: spans),
      style: TextStyle(fontSize: 14, height: 1.5, color: baseColor),
    );
  }

  /// Phát hiện markdown có cấu trúc (tiêu đề, bảng, fence) — khác với chỉ **đậm**
  bool _looksLikeStructuredMarkdown(String text) {
    final t = text.trimLeft();
    if (t.startsWith('#')) return true;
    if (RegExp(r'^[-*]\s', multiLine: true).hasMatch(text)) return true;
    if (RegExp(r'^\d+\.\s', multiLine: true).hasMatch(text)) return true;
    if (text.contains('|') && text.contains('\n')) {
      final lines = text.split('\n');
      final pipeLines = lines.where((l) => l.contains('|')).length;
      if (pipeLines >= 2) return true;
    }
    if (text.contains('```')) return true;
    return false;
  }

  List<InlineSpan> _parseMarkdown(String text, bool isUser, bool isDark) {
    final spans = <InlineSpan>[];
    final baseColor =
        isUser
            ? Colors.white
            : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary);

    // Simple markdown parsing for **bold** and _italic_
    final regex = RegExp(r'\*\*(.*?)\*\*|_(.*?)_');
    int lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(
          TextSpan(
            text: text.substring(lastEnd, match.start),
            style: TextStyle(color: baseColor),
          ),
        );
      }

      if (match.group(1) != null) {
        // Bold
        spans.add(
          TextSpan(
            text: match.group(1),
            style: TextStyle(fontWeight: FontWeight.w700, color: baseColor),
          ),
        );
      } else if (match.group(2) != null) {
        // Italic
        spans.add(
          TextSpan(
            text: match.group(2),
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: baseColor.withValues(alpha: 0.8),
            ),
          ),
        );
      }

      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(lastEnd),
          style: TextStyle(color: baseColor),
        ),
      );
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
            '${logData.foodName} • ${logData.calories.toInt()} kcal (P: ${logData.protein.toInt()}g, C: ${logData.carbs.toInt()}g, F: ${logData.fat.toInt()}g) đã ghi',
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

  Widget _buildSuggestionCards(List<MealSuggestion> suggestions, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.lightbulb_fill,
                size: 12,
                color: AppColors.primaryBlue,
              ),
              SizedBox(width: 4),
              Text(
                'Gợi ý món ăn',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryBlue,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: suggestions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final s = suggestions[index];
              return _buildSuggestionCard(s, isDark);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionCard(MealSuggestion s, bool isDark) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            s.description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color:
                  isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${s.calories.toInt()} kcal',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'P${s.protein.toInt()} C${s.carbs.toInt()} F${s.fat.toInt()}',
                style: TextStyle(
                  fontSize: 10,
                  color:
                      isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => _addMealFromSuggestion(s),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.successGreen,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.plus, size: 12, color: Colors.white),
                  SizedBox(width: 3),
                  Text(
                    'Thêm',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addMealFromSuggestion(MealSuggestion s) async {
    try {
      final meal = Meal(
        dateTime: DateTime.now(),
        foodName: s.name,
        calories: s.calories,
        protein: s.protein,
        carbs: s.carbs,
        fat: s.fat,
        source: 'chatbot_suggestion',
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
                    '✅ Đã thêm ${s.name} (${s.calories.toInt()} kcal)',
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
      debugPrint('Error adding meal from suggestion: $e');
    }
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
      '😴 Tôi đã ngủ 7.5 tiếng',
      '🌙 Đêm qua ngủ lúc 11h',
      '🥗 Salad rau củ',
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
                color:
                    isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                suggestions[index],
                style: TextStyle(
                  fontSize: 12,
                  color:
                      isDark
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
                color:
                    isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                style: TextStyle(
                  fontSize: 14,
                  color:
                      isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Hỏi về calo hoặc ghi nhật ký...',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color:
                        isDark
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
                gradient:
                    _isLoading
                        ? null
                        : const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                        ),
                color:
                    _isLoading
                        ? (isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.grey.withValues(alpha: 0.2))
                        : null,
                shape: BoxShape.circle,
                boxShadow:
                    _isLoading
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
                _isLoading ? CupertinoIcons.hourglass : CupertinoIcons.arrow_up,
                color:
                    _isLoading
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
}

// ══════════════════════════════════════════════════════════════
// CHAT ITEM MODEL
// ══════════════════════════════════════════════════════════════
class _ChatItem {
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final NutritionAIResponse? aiResponse;
  final NutritionData? nutritionData;

  _ChatItem({
    required this.content,
    required this.isUser,
    DateTime? timestamp,
    this.aiResponse,
    this.nutritionData,
  }) : timestamp = timestamp ?? DateTime.now();

  factory _ChatItem.bot(String content, {NutritionAIResponse? aiResponse}) =>
      _ChatItem(content: content, isUser: false, aiResponse: aiResponse);
}

// ══════════════════════════════════════════════════════════════
// CHAT HISTORY SHEET
// ══════════════════════════════════════════════════════════════
class _ChatHistorySheet extends StatefulWidget {
  final ScrollController scrollController;
  final String? currentConversationId;
  final Function(String conversationId, List<ChatMessage> messages)
  onSelectConversation;

  const _ChatHistorySheet({
    required this.scrollController,
    this.currentConversationId,
    required this.onSelectConversation,
  });

  @override
  State<_ChatHistorySheet> createState() => _ChatHistorySheetState();
}

class _ChatHistorySheetState extends State<_ChatHistorySheet> {
  List<Conversation> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    try {
      final conversations = await DatabaseService.getConversations();
      if (!mounted) return;
      setState(() {
        _conversations = conversations;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading conversations: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteConversation(String conversationId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Xóa cuộc trò chuyện'),
            content: const Text(
              'Bạn có chắc muốn xóa cuộc trò chuyện này? Hành động này không thể hoàn tác.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.errorRed,
                ),
                child: const Text('Xóa'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await DatabaseService.deleteConversation(conversationId);
        await _loadConversations();
      } catch (e) {
        debugPrint('Error deleting conversation: $e');
      }
    }
  }

  Future<void> _loadConversationMessages(Conversation conversation) async {
    try {
      final messages = await DatabaseService.getMessagesByConversation(
        conversation.id,
      );
      widget.onSelectConversation(conversation.id, messages);
    } catch (e) {
      debugPrint('Error loading conversation messages: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : const Color(0xFFF0F2F5),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black26,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Lịch sử chat',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    CupertinoIcons.refresh,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  onPressed: () {
                    setState(() => _isLoading = true);
                    _loadConversations();
                  },
                ),
                IconButton(
                  icon: Icon(
                    CupertinoIcons.xmark,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _conversations.isEmpty
                    ? _buildEmptyState(isDark)
                    : _buildConversationsList(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.chat_bubble_2,
            size: 64,
            color: isDark ? Colors.white24 : Colors.black12,
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có lịch sử chat',
            style: TextStyle(
              fontSize: 16,
              color:
                  isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bắt đầu trò chuyện với AI để lưu lại',
            style: TextStyle(
              fontSize: 13,
              color:
                  isDark
                      ? AppColors.darkTextTertiary
                      : AppColors.lightTextTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationsList(bool isDark) {
    return ListView.builder(
      controller: widget.scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _conversations.length,
      itemBuilder: (context, index) {
        final conversation = _conversations[index];
        final isCurrentConversation =
            conversation.id == widget.currentConversationId;
        return _buildConversationCard(
          conversation,
          isCurrentConversation,
          isDark,
        );
      },
    );
  }

  Widget _buildConversationCard(
    Conversation conversation,
    bool isCurrentConversation,
    bool isDark,
  ) {
    final isToday = conversation.formattedDate == 'Hôm nay';

    return GestureDetector(
      onTap: () => _loadConversationMessages(conversation),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color:
              isCurrentConversation
                  ? AppColors.primaryBlue.withValues(alpha: 0.1)
                  : (isDark ? AppColors.darkCard : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border:
              isCurrentConversation
                  ? Border.all(
                    color: AppColors.primaryBlue.withValues(alpha: 0.3),
                  )
                  : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with date
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Row(
                children: [
                  Icon(
                    isToday
                        ? CupertinoIcons.calendar_today
                        : CupertinoIcons.calendar,
                    size: 16,
                    color:
                        isCurrentConversation
                            ? AppColors.primaryBlue
                            : (isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    conversation.formattedDate,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color:
                          isCurrentConversation
                              ? AppColors.primaryBlue
                              : (isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                  if (isCurrentConversation) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Hiện tại',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    '${conversation.messageCount} tin nhắn',
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.lightTextTertiary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _deleteConversation(conversation.id),
                    icon: Icon(
                      CupertinoIcons.trash,
                      size: 18,
                      color: AppColors.errorRed.withValues(alpha: 0.7),
                    ),
                    tooltip: 'Xóa',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.sparkles,
                    size: 14,
                    color:
                        isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.lightTextTertiary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      conversation.title ?? 'Cuộc trò chuyện mới',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color:
                            isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Last message preview
            if (conversation.lastMessage != null &&
                conversation.lastMessage!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.text_bubble,
                      size: 14,
                      color:
                          isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.lightTextTertiary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        conversation.lastMessage!,
                        style: TextStyle(
                          fontSize: 13,
                          color:
                              isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

            // Time
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.clock,
                    size: 12,
                    color:
                        isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.lightTextTertiary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    conversation.timeStr,
                    style: TextStyle(
                      fontSize: 11,
                      color:
                          isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.lightTextTertiary,
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
