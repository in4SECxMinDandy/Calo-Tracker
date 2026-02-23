# Quick Start Guide - Using Redesigned Components

**For**: Flutter developers integrating the new UI components
**Date**: 2026-02-22

---

## 🚀 Quick Import Reference

```dart
// Core components
import 'package:calotracker/widgets/redesign/health_rings.dart';
import 'package:calotracker/widgets/redesign/macro_bar.dart';
import 'package:calotracker/widgets/redesign/nutrition_pill.dart';
import 'package:calotracker/widgets/redesign/stat_badge.dart';

// Community components
import 'package:calotracker/widgets/redesign/community/post_card.dart';
import 'package:calotracker/widgets/redesign/community/create_post_modal.dart';

// Theme
import 'package:calotracker/theme/colors.dart';
import 'package:calotracker/theme/text_styles.dart';
```

---

## 1️⃣ HealthRings - Circular Progress Display

**Use Case**: Show daily calorie summary with 3 rings

```dart
// Basic usage
HealthRings(
  consumed: 1500,  // kcal eaten
  burned: 400,     // kcal from exercise
  target: 2000,    // daily goal
)

// Custom size
HealthRings(
  consumed: userNutritionData.consumed,
  burned: userNutritionData.burned,
  target: userNutritionData.target,
  size: 250,  // Default: 220
)
```

**Visual Result**:
- Outer ring (green): 75% (1500/2000)
- Middle ring (orange): 40% (400/1000)
- Inner ring (indigo): 45% (900/2000 remaining)
- Center text: "900 kcal còn lại"

---

## 2️⃣ MacroBar - Animated Progress Bar

**Use Case**: Display macro nutrient progress

```dart
// Protein bar
MacroBar(
  label: 'P',
  value: 65.0,
  max: 150.0,
  unit: 'g',
  color: AppColors.errorRed,
  size: MacroBarSize.small,
)

// Multiple macros
Column(
  children: [
    MacroBar(
      label: 'P',
      value: proteinConsumed,
      max: proteinTarget,
      unit: 'g',
      color: AppColors.errorRed,
    ),
    MacroBar(
      label: 'C',
      value: carbsConsumed,
      max: carbsTarget,
      unit: 'g',
      color: AppColors.warningOrange,
    ),
    MacroBar(
      label: 'F',
      value: fatConsumed,
      max: fatTarget,
      unit: 'g',
      color: AppColors.primaryIndigo,
    ),
  ],
)
```

---

## 3️⃣ NutritionPill - Compact Stat

**Use Case**: Show nutrition facts in a compact format

```dart
// Single pill
NutritionPill(
  label: 'Protein',
  value: '65g',
  color: AppColors.errorRed,
)

// Row of pills
Wrap(
  spacing: 8,
  children: [
    NutritionPill(
      label: 'Cal',
      value: '500',
      color: AppColors.warningOrange,
    ),
    NutritionPill(
      label: 'Protein',
      value: '30g',
      color: AppColors.errorRed,
    ),
    NutritionPill(
      label: 'Carbs',
      value: '60g',
      color: AppColors.warningOrange,
    ),
  ],
)
```

---

## 4️⃣ StatBadge - Icon + Stat Card

**Use Case**: Dashboard stat cards with icons

```dart
// With gradient background
StatBadge(
  emoji: '💧',
  value: '1500',
  unit: 'ml',
  label: 'Nước uống',
  gradient: LinearGradient(
    colors: [AppColors.primaryBlue, AppColors.accentCyan],
  ),
)

// With icon and simple background
StatBadge(
  icon: CupertinoIcons.bed_double,
  value: '7.5',
  unit: 'giờ',
  label: 'Giấc ngủ',
  backgroundColor: AppColors.primaryIndigo.withOpacity(0.1),
)

// Grid of badges
GridView.count(
  crossAxisCount: 2,
  mainAxisSpacing: 12,
  crossAxisSpacing: 12,
  children: [
    StatBadge(
      emoji: '💧',
      value: '${waterIntake}',
      unit: 'ml',
      label: 'Nước',
      gradient: LinearGradient(
        colors: [AppColors.primaryBlue, AppColors.accentCyan],
      ),
    ),
    StatBadge(
      emoji: '😴',
      value: '${sleepHours}',
      unit: 'giờ',
      label: 'Ngủ',
      gradient: LinearGradient(
        colors: [AppColors.primaryIndigo, Color(0xFF8B5CF6)],
      ),
    ),
  ],
)
```

---

## 5️⃣ PostCard - Social Media Post

**Use Case**: Community feed posts

```dart
// Single post
PostCard(
  post: PostData(
    id: '1',
    author: 'Nguyễn Văn A',
    username: 'nguyenvana',
    avatar: 'https://example.com/avatar.jpg',
    verified: true,
    badge: 'Top 10',
    location: 'Hà Nội',
    content: 'Hôm nay tôi đã hoàn thành mục tiêu calories! 💪',
    image: 'https://example.com/meal.jpg',
    mealName: 'Bữa trưa healthy',
    macros: MacroData(
      calories: 500,
      protein: 35,
      carbs: 60,
      fat: 15,
    ),
    likes: 42,
    comments: 8,
    shares: 3,
    timeAgo: '2 giờ',
    liked: false,
    bookmarked: false,
    isOnline: true,
  ),
  index: 0,
  onLike: (postId) {
    print('Liked post: $postId');
    // TODO: Call API
  },
  onBookmark: (postId) {
    print('Bookmarked post: $postId');
    // TODO: Call API
  },
  onComment: (postId) {
    // Navigate to comments screen
  },
  onShare: (postId) {
    // Show share options
  },
  onUserTap: (username) {
    // Navigate to user profile
  },
)

// List of posts
ListView.builder(
  itemCount: posts.length,
  itemBuilder: (context, index) {
    return PostCard(
      post: posts[index],
      index: index,  // For staggered animation
      onLike: handleLike,
      onBookmark: handleBookmark,
    );
  },
)
```

---

## 6️⃣ CreatePostModal - Post Creation

**Use Case**: Create new community post

```dart
// Show modal
void _showCreatePost() {
  CreatePostModal.show(
    context,
    userName: 'Nguyễn Văn A',
    userAvatar: 'https://example.com/avatar.jpg',
    onPost: (postData) {
      print('Content: ${postData.content}');
      print('Meal: ${postData.mealName}');
      print('Macros: ${postData.macros?.calories} kcal');
      print('Location: ${postData.location}');

      // TODO: Send to API
      // await api.createPost(postData);

      // Refresh feed
      _refreshFeed();
    },
  );
}

// Trigger from FAB
FloatingActionButton(
  onPressed: _showCreatePost,
  child: Icon(CupertinoIcons.add),
)
```

**Modal Features**:
- Text input (auto-focus)
- Meal form (collapsible)
- Location input (collapsible)
- Action buttons (Camera, Photo, Meal, Location, Emoji)
- Post button (enabled when content is not empty)

---

## 🎨 Color Reference

```dart
// Primary
AppColors.primaryBlue      // #2563EB
AppColors.primaryIndigo    // #6366F1

// Accents
AppColors.accentMint       // #06D6A0
AppColors.accentCyan       // #06B6D4
AppColors.accentLime       // #84CC16

// Status
AppColors.successGreen     // #10B981
AppColors.warningOrange    // #F59E0B
AppColors.errorRed         // #EF4444

// Community
AppColors.facebookBlue     // #1877F2

// Theme-aware (use in build method)
final isDark = Theme.of(context).brightness == Brightness.dark;
final bgColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;
final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
```

---

## 🎯 Common Patterns

### Pattern 1: Loading State
```dart
class MyScreen extends StatefulWidget {
  @override
  _MyScreenState createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  bool _isLoading = true;
  List<PostData> _posts = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    // TODO: Fetch from API
    await Future.delayed(Duration(seconds: 1)); // Mock
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        return PostCard(
          post: _posts[index],
          index: index,
          onLike: _handleLike,
          onBookmark: _handleBookmark,
        );
      },
    );
  }

  void _handleLike(String postId) async {
    // TODO: Call API
    // Optimistic update
    setState(() {
      final index = _posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        _posts[index] = PostData(
          /* ... copy all fields, toggle liked */
        );
      }
    });
  }
}
```

### Pattern 2: Error Handling
```dart
try {
  final response = await http.post('/api/community/posts', body: {...});
  if (response.statusCode == 200) {
    // Success
  } else {
    // Show error
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đăng bài thất bại')),
    );
  }
} catch (e) {
  print('Error: $e');
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Lỗi kết nối')),
  );
}
```

### Pattern 3: Pull to Refresh
```dart
RefreshIndicator(
  onRefresh: _refreshData,
  child: ListView.builder(
    itemCount: posts.length,
    itemBuilder: (context, index) {
      return PostCard(
        post: posts[index],
        index: index,
        onLike: _handleLike,
        onBookmark: _handleBookmark,
      );
    },
  ),
)
```

---

## 📦 Sample Data for Testing

```dart
// Mock posts for testing
final mockPosts = [
  PostData(
    id: '1',
    author: 'Nguyễn Văn A',
    username: 'nguyenvana',
    avatar: 'https://i.pravatar.cc/150?img=1',
    verified: true,
    badge: 'Top 10',
    location: 'Hà Nội',
    content: 'Hôm nay tôi đã hoàn thành mục tiêu calories! 💪',
    image: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c',
    mealName: 'Bữa trưa healthy',
    macros: MacroData(calories: 500, protein: 35, carbs: 60, fat: 15),
    likes: 42,
    comments: 8,
    shares: 3,
    timeAgo: '2 giờ',
    liked: false,
    bookmarked: false,
    isOnline: true,
  ),
  PostData(
    id: '2',
    author: 'Trần Thị B',
    username: 'tranthib',
    avatar: 'https://i.pravatar.cc/150?img=2',
    verified: false,
    content: 'Chạy bộ 5km sáng nay! Cảm thấy rất tuyệt vời 🏃‍♀️',
    likes: 28,
    comments: 5,
    shares: 1,
    timeAgo: '4 giờ',
    liked: true,
    bookmarked: false,
    isOnline: true,
  ),
];

// Mock nutrition data
final mockNutrition = {
  'consumed': 1500.0,
  'burned': 400.0,
  'target': 2000.0,
  'protein': 65.0,
  'proteinTarget': 150.0,
  'carbs': 180.0,
  'carbsTarget': 250.0,
  'fat': 50.0,
  'fatTarget': 70.0,
};
```

---

## 🐛 Common Issues & Solutions

### Issue 1: Images not loading
**Solution**: Add error handling
```dart
Image.network(
  imageUrl,
  errorBuilder: (context, error, stackTrace) {
    return Container(
      color: AppColors.lightMuted,
      child: Icon(CupertinoIcons.photo, size: 48),
    );
  },
)
```

### Issue 2: Dark mode not working
**Solution**: Wrap app in MaterialApp with theme
```dart
MaterialApp(
  theme: ThemeData.light(),
  darkTheme: ThemeData.dark(),
  themeMode: ThemeMode.system,
  home: MyHomePage(),
)
```

### Issue 3: Animations not smooth
**Solution**: Check vsync and dispose
```dart
class _MyWidgetState extends State<MyWidget>
    with SingleTickerProviderStateMixin {  // ← Add this

  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,  // ← Use this
      duration: Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _controller.dispose();  // ← Don't forget
    super.dispose();
  }
}
```

---

## 📚 Next Steps

1. **Try the components**: Copy examples above and test in your screen
2. **Connect to API**: Replace mock data with real API calls
3. **Add state management**: Integrate Provider/Riverpod/Bloc
4. **Customize**: Adjust colors, sizes to match your needs

---

**Need Help?**
- Check [`REDESIGN_IMPLEMENTATION_SUMMARY.md`](REDESIGN_IMPLEMENTATION_SUMMARY.md) for details
- Review component source code for all available parameters
- Test components in isolation using Flutter DevTools

**Last Updated**: 2026-02-22
