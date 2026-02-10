// Chatbot Screen
// AI-powered nutrition query with chat interface
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../models/chat_message.dart';
import '../../models/meal.dart';
import '../../services/database_service.dart';
import '../../services/nutrition_service.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/nutrition_pie_chart.dart';

class ChatbotScreen extends StatefulWidget {
  final VoidCallback? onMealAdded;

  const ChatbotScreen({super.key, this.onMealAdded});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
    _addWelcomeMessage();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadChatHistory() async {
    final history = await DatabaseService.getTodayChatHistory();
    if (history.isNotEmpty) {
      setState(() {
        _messages.addAll(history);
      });
      _scrollToBottom();
    }
  }

  void _addWelcomeMessage() {
    if (_messages.isEmpty) {
      _messages.add(
        ChatMessage.bot(
          'Xin chào! 👋\n\nTôi là trợ lý dinh dưỡng của bạn. Hãy nhập món ăn để tôi tính toán calo và dinh dưỡng.\n\nVí dụ: "200g phở bò" hoặc "cơm trắng + gà nướng"',
        ),
      );
    }
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

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoading) return;

    _messageController.clear();

    // Add user message
    final userMessage = ChatMessage.user(text);
    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });
    _scrollToBottom();

    // Save user message to database
    await DatabaseService.insertChatMessage(userMessage);

    // Query Nutritionix API
    final result = await NutritionService.queryNutrition(text);

    // Create bot response
    ChatMessage botMessage;
    if (result.isSuccess && result.data != null) {
      botMessage = ChatMessage.bot(
        _formatNutritionResponse(result.data!),
        nutrition: result.data,
      );
    } else {
      botMessage = ChatMessage.bot(
        '❌ ${result.error ?? "Không thể phân tích món ăn"}\n\nVui lòng thử lại với mô tả khác.',
      );
    }

    setState(() {
      _messages.add(botMessage);
      _isLoading = false;
    });
    _scrollToBottom();

    // Save bot message to database
    await DatabaseService.insertChatMessage(botMessage);
  }

  String _formatNutritionResponse(NutritionData data) {
    final buffer = StringBuffer();
    buffer.writeln('🍽️ **Kết quả phân tích:**');
    buffer.writeln('');

    for (final food in data.foods) {
      buffer.writeln('• **${food.name}**');
      if (food.weight != null) {
        buffer.writeln('  📦 Khẩu phần: ${food.weight?.toInt()}g');
      }
      buffer.writeln('  🔥 Năng lượng: ${food.calories.toInt()} kcal');
    }

    buffer.writeln('');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('📊 **Tổng dinh dưỡng:**');
    buffer.writeln('');
    buffer.writeln('🔥 Calo: **${data.calories.toInt()}** kcal');
    buffer.writeln(
      '🥩 Protein: **${(data.protein ?? 0).toStringAsFixed(1)}**g',
    );
    buffer.writeln('🍞 Carbs: **${(data.carbs ?? 0).toStringAsFixed(1)}**g');
    buffer.writeln('🧈 Chất béo: **${(data.fat ?? 0).toStringAsFixed(1)}**g');
    buffer.writeln('');

    // Add helpful tip based on meal
    final caloriePercent = (data.calories / 2000 * 100).round();
    buffer.writeln(
      '💡 Chiếm khoảng **$caloriePercent%** khẩu phần calo hàng ngày (2000 kcal)',
    );

    return buffer.toString();
  }

  Future<void> _addMealToDiary(NutritionData data) async {
    final meals = NutritionService.toMeals(
      NutritionResult.success(data, {
        'foods':
            data.foods
                .map(
                  (f) => {
                    'food_name': f.name,
                    'nf_calories': f.calories,
                    'serving_weight_grams': f.weight,
                    'nf_protein': data.protein,
                    'nf_total_carbohydrate': data.carbs,
                    'nf_total_fat': data.fat,
                  },
                )
                .toList(),
      }),
      'chatbot',
    );

    // If no meals from API response, create one from nutrition data
    if (meals.isEmpty && data.foods.isNotEmpty) {
      for (final food in data.foods) {
        final meal = Meal(
          dateTime: DateTime.now(),
          foodName: food.name,
          weight: food.weight,
          calories: food.calories,
          protein:
              data.protein != null ? data.protein! / data.foods.length : null,
          carbs: data.carbs != null ? data.carbs! / data.foods.length : null,
          fat: data.fat != null ? data.fat! / data.foods.length : null,
          source: 'chatbot',
        );
        await DatabaseService.insertMeal(meal);
      }
    } else {
      for (final meal in meals) {
        await DatabaseService.insertMeal(meal);
      }
    }

    widget.onMealAdded?.call();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(CupertinoIcons.checkmark_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text('Đã thêm ${data.calories.toInt()} kcal vào nhật ký!'),
            ],
          ),
          backgroundColor: AppColors.successGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chatbot Dinh Dưỡng'),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.arrow_left),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.trash),
            onPressed: _clearChat,
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child:
                _messages.isEmpty
                    ? _buildWelcomeState()
                    : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length + (_isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (_isLoading && index == _messages.length) {
                          return _buildLoadingBubble();
                        }
                        return _buildMessageBubble(_messages[index]);
                      },
                    ),
          ),

          // Quick suggestions
          _buildQuickSuggestions(),

          // Input field
          _buildInputField(),
        ],
      ),
    );
  }

  Widget _buildWelcomeState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          // Bot avatar
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: AppColors.chatbotCardGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              CupertinoIcons.chat_bubble_2_fill,
              color: Colors.white,
              size: 50,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Xin chào! 👋',
            style: AppTextStyles.heading2.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tôi là trợ lý dinh dưỡng của bạn.\nHãy nhập món ăn để tôi phân tích dinh dưỡng!',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),

          // Tips
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '💡 Mẹo sử dụng:',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildTip('🍜', 'Nhập tên món: "Phở bò"'),
                _buildTip('📦', 'Thêm khẩu phần: "200g cơm gà"'),
                _buildTip('🍱', 'Nhiều món: "Bánh mì + cà phê sữa"'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTip(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSuggestions() {
    final suggestions = [
      '🍜 Phở bò',
      '🍚 Cơm tấm',
      '🥖 Bánh mì',
      '🍗 Gà rán',
      '🥗 Salad',
      '☕ Cà phê',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children:
              suggestions.map((suggestion) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(suggestion),
                    backgroundColor: Theme.of(context).cardColor,
                    onPressed: () {
                      // Remove emoji and trim
                      final text =
                          suggestion
                              .replaceAll(
                                RegExp(
                                  r'[^\w\sàáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ]',
                                ),
                                '',
                              )
                              .trim();
                      _messageController.text = text;
                      _sendMessage();
                    },
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        margin: EdgeInsets.only(
          bottom: 12,
          left: isUser ? 50 : 0,
          right: isUser ? 0 : 50,
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Message bubble
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:
                    isUser
                        ? AppColors.primaryBlue
                        : Theme.of(context).cardColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.message,
                    style: AppTextStyles.chatMessage.copyWith(
                      color: isUser ? Colors.white : null,
                    ),
                  ),

                  // Nutrition chart for bot messages with data
                  if (!isUser && message.nutrition != null) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    NutritionPieChart(
                      protein: message.nutrition!.protein ?? 0,
                      carbs: message.nutrition!.carbs ?? 0,
                      fat: message.nutrition!.fat ?? 0,
                      totalCalories: message.nutrition!.calories,
                      size: 100,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _addMealToDiary(message.nutrition!),
                        icon: const Icon(CupertinoIcons.plus, size: 18),
                        label: const Text('Thêm vào nhật ký'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.successGreen,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Time
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 8, right: 8),
              child: Text(
                message.timeStr,
                style: AppTextStyles.labelSmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, right: 50),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CupertinoActivityIndicator(),
            const SizedBox(width: 12),
            Text(
              'Đang phân tích...',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Nhập món ăn (VD: 200g phở bò)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: AppColors.chatbotCardGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryBlue.withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  CupertinoIcons.paperplane_fill,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _clearChat() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Xóa lịch sử chat?'),
            content: const Text('Bạn có chắc muốn xóa toàn bộ lịch sử chat?'),
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

    if (confirm == true) {
      await DatabaseService.clearChatHistory();
      setState(() {
        _messages.clear();
        _addWelcomeMessage();
      });
    }
  }
}
