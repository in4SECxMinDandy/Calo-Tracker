# 🚀 Phase 3: Screens & Backend Integration Implementation Plan

**Date**: 2026-02-22
**Status**: Ready to implement
**Estimated Time**: 20-30 hours total

---

## 📋 Overview

Phase 3 focuses on:
1. **Backend Service Layer** - API integration foundation
2. **Screen Porting** - 5 main screens from React → Flutter
3. **State Management** - Provider/Riverpod setup
4. **Navigation** - Bottom navigation + routing
5. **Testing** - Integration tests

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                     Flutter App                          │
├─────────────────────────────────────────────────────────┤
│  Screens (UI Layer)                                      │
│  ├─ HomeScreen                                          │
│  ├─ CommunityHubScreen                                  │
│  ├─ HistoryScreen                                       │
│  ├─ ChatbotScreen                                       │
│  └─ ProfileScreen                                       │
├─────────────────────────────────────────────────────────┤
│  State Management (Provider/Riverpod)                    │
│  ├─ UserProvider                                        │
│  ├─ PostsProvider                                       │
│  ├─ MealsProvider                                       │
│  └─ SettingsProvider                                    │
├─────────────────────────────────────────────────────────┤
│  Services Layer (Business Logic)                         │
│  ├─ ApiService (base)                                  │
│  ├─ CommunityService                                    │
│  ├─ MealService                                         │
│  ├─ HistoryService                                      │
│  ├─ ChatbotService                                      │
│  └─ ProfileService                                      │
├─────────────────────────────────────────────────────────┤
│  Data Layer                                              │
│  ├─ Supabase Client                                    │
│  ├─ Local Storage (SharedPreferences)                  │
│  └─ Image Cache                                         │
└─────────────────────────────────────────────────────────┘
```

---

## 📦 Step 1: Backend Service Layer (4-6 hours)

### 1.1 Base API Service ✅ CREATED

**File**: `lib/services/api_service.dart`

Features:
- Generic HTTP methods (GET, POST, PUT, DELETE)
- Error handling
- Auth token management
- File upload
- Edge function calls

### 1.2 Community Service (2 hours)

**File**: `lib/services/community_service.dart`

**Methods**:
```dart
class CommunityService {
  // Posts
  Future<List<PostData>> getFeedPosts({int limit, int offset});
  Future<PostData> getPost(String postId);
  Future<PostData> createPost(CreatePostData data);
  Future<PostData> editPost(String postId, String content);
  Future<void> deletePost(String postId);

  // Interactions
  Future<void> toggleLike(String postId);
  Future<void> toggleBookmark(String postId);
  Future<void> reportPost(String postId, String reason);
  Future<void> hidePost(String postId);

  // Comments
  Future<List<Comment>> getComments(String postId);
  Future<Comment> addComment(String postId, String content);
  Future<void> deleteComment(String commentId);

  // Stories
  Future<List<Story>> getStories();
  Future<void> addStory(File imageFile);
  Future<void> viewStory(String storyId);
}
```

### 1.3 Meal Service (1 hour)

**File**: `lib/services/meal_service.dart`

**Methods**:
```dart
class MealService {
  Future<List<Meal>> getTodayMeals();
  Future<Meal> logMeal(MealData data);
  Future<void> deleteMeal(String mealId);
  Future<Meal> scanFood(File imageFile);  // AI recognition
  Future<List<Food>> searchFood(String query);
  Future<MacroSummary> getDailySummary(DateTime date);
}
```

### 1.4 History Service (1 hour)

**File**: `lib/services/history_service.dart`

**Methods**:
```dart
class HistoryService {
  Future<List<DailyLog>> getHistory({DateTime? startDate, DateTime? endDate});
  Future<WeeklyStats> getWeeklyStats();
  Future<MonthlyStats> getMonthlyStats();
  Future<List<Weight>> getWeightHistory();
  Future<void> logWeight(double weight);
  Future<List<Water>> getWaterHistory();
  Future<void> logWater(int ml);
}
```

### 1.5 Chatbot Service (1 hour)

**File**: `lib/services/chatbot_service.dart`

**Methods**:
```dart
class ChatbotService {
  Future<List<Message>> getChatHistory();
  Future<Message> sendMessage(String text);
  Stream<Message> streamResponse(String text);  // Real-time streaming
  Future<void> clearHistory();
  Future<List<Suggestion>> getSuggestions();
}
```

### 1.6 Profile Service (1 hour)

**File**: `lib/services/profile_service.dart`

**Methods**:
```dart
class ProfileService {
  Future<UserProfile> getProfile(String userId);
  Future<UserProfile> updateProfile(ProfileData data);
  Future<String> uploadAvatar(File imageFile);
  Future<List<Achievement>> getAchievements();
  Future<Stats> getUserStats();
  Future<List<PostData>> getUserPosts(String userId);
  Future<void> followUser(String userId);
  Future<void> unfollowUser(String userId);
}
```

---

## 🎨 Step 2: State Management Setup (2-3 hours)

### 2.1 Install Provider

**pubspec.yaml**:
```yaml
dependencies:
  provider: ^6.1.2  # Already installed ✅
```

### 2.2 Create Providers

#### UserProvider
**File**: `lib/providers/user_provider.dart`

```dart
class UserProvider extends ChangeNotifier {
  UserProfile? _profile;
  bool _loading = false;

  UserProfile? get profile => _profile;
  bool get loading => _loading;

  Future<void> loadProfile() async {
    _loading = true;
    notifyListeners();

    try {
      _profile = await ProfileService().getProfile(ApiService.instance.currentUserId!);
    } catch (e) {
      // Handle error
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile(ProfileData data) async {
    _profile = await ProfileService().updateProfile(data);
    notifyListeners();
  }
}
```

#### PostsProvider
**File**: `lib/providers/posts_provider.dart`

```dart
class PostsProvider extends ChangeNotifier {
  List<PostData> _posts = [];
  bool _loading = false;
  bool _hasMore = true;
  int _offset = 0;

  List<PostData> get posts => _posts;
  bool get loading => _loading;
  bool get hasMore => _hasMore;

  Future<void> loadPosts({bool refresh = false}) async {
    if (_loading) return;
    if (refresh) {
      _posts = [];
      _offset = 0;
      _hasMore = true;
    }

    _loading = true;
    notifyListeners();

    try {
      final newPosts = await CommunityService().getFeedPosts(
        limit: 20,
        offset: _offset,
      );

      if (newPosts.length < 20) _hasMore = false;
      _posts.addAll(newPosts);
      _offset += newPosts.length;
    } catch (e) {
      // Handle error
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> createPost(CreatePostData data) async {
    final newPost = await CommunityService().createPost(data);
    _posts.insert(0, newPost);
    notifyListeners();
  }

  Future<void> deletePost(String postId) async {
    await CommunityService().deletePost(postId);
    _posts.removeWhere((p) => p.id == postId);
    notifyListeners();
  }

  Future<void> toggleLike(String postId) async {
    await CommunityService().toggleLike(postId);
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index != -1) {
      _posts[index] = _posts[index].copyWith(
        liked: !_posts[index].liked,
        likes: _posts[index].liked ? _posts[index].likes - 1 : _posts[index].likes + 1,
      );
      notifyListeners();
    }
  }
}
```

#### MealsProvider
**File**: `lib/providers/meals_provider.dart`

```dart
class MealsProvider extends ChangeNotifier {
  List<Meal> _meals = [];
  MacroSummary? _dailySummary;
  bool _loading = false;

  List<Meal> get meals => _meals;
  MacroSummary? get dailySummary => _dailySummary;
  bool get loading => _loading;

  Future<void> loadTodayMeals() async {
    _loading = true;
    notifyListeners();

    try {
      _meals = await MealService().getTodayMeals();
      _dailySummary = await MealService().getDailySummary(DateTime.now());
    } catch (e) {
      // Handle error
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logMeal(MealData data) async {
    final meal = await MealService().logMeal(data);
    _meals.add(meal);
    await loadTodayMeals();  // Refresh summary
    notifyListeners();
  }
}
```

---

## 📱 Step 3: Screen Implementation (12-15 hours)

### 3.1 HomeScreen (4 hours)

**File**: `lib/screens/tabs/home_screen.dart`

**Sections**:
1. Header (greeting, notifications)
2. Health Rings (calories consumed/burned/target)
3. Quick Actions (Camera, Gym, AI Chat, Water)
4. Macros Summary (Protein/Carbs/Fat bars)
5. Today's Meals List
6. Friends Activity

**Key Components Used**:
- `HealthRings` ✅
- `MacroBar` ✅
- `StatBadge` ✅
- `NutritionPill` ✅

**State Management**:
- `UserProvider`
- `MealsProvider`

**Estimated Lines**: ~800 lines

### 3.2 CommunityHubScreen (3 hours)

**File**: `lib/screens/tabs/community_hub_screen.dart`

**Sections**:
1. Stories Row (horizontal scroll)
2. Challenges Cards (active challenges)
3. Posts Feed (infinite scroll)
4. Create Post FAB

**Key Components Used**:
- `PostCard` ✅
- `CreatePostModal` ✅

**State Management**:
- `PostsProvider`

**Estimated Lines**: ~600 lines

### 3.3 HistoryScreen (4 hours)

**File**: `lib/screens/tabs/history_screen.dart`

**Sections**:
1. Date Range Selector
2. Charts (line chart for calories/weight)
3. Weekly Stats Cards
4. Daily Logs List

**Key Components**:
- `fl_chart` package (already installed ✅)
- Custom chart widgets

**State Management**:
- `HistoryProvider`

**Estimated Lines**: ~700 lines

### 3.4 ChatbotScreen (3 hours)

**File**: `lib/screens/tabs/chatbot_screen.dart`

**Sections**:
1. Chat Messages List
2. Typing Indicator
3. Message Input
4. Quick Suggestions

**State Management**:
- `ChatbotProvider`

**Estimated Lines**: ~500 lines

### 3.5 ProfileScreen (3 hours)

**File**: `lib/screens/tabs/profile_screen.dart`

**Sections**:
1. Profile Header (avatar, stats)
2. Achievements Grid
3. User Posts Grid
4. Settings Button

**State Management**:
- `UserProvider`
- `PostsProvider`

**Estimated Lines**: ~600 lines

---

## 🧭 Step 4: Navigation Setup (2 hours)

### 4.1 Bottom Navigation

**File**: `lib/widgets/bottom_navigation.dart`

```dart
class MainBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, CupertinoIcons.home, 'Trang chủ'),
            _buildNavItem(1, CupertinoIcons.person_2, 'Cộng đồng'),
            _buildNavItem(2, CupertinoIcons.chart_bar, 'Lịch sử'),
            _buildNavItem(3, CupertinoIcons.chat_bubble, 'AI Chat'),
            _buildNavItem(4, CupertinoIcons.person, 'Cá nhân'),
          ],
        ),
      ),
    );
  }
}
```

### 4.2 Main Layout

**File**: `lib/layouts/main_layout.dart`

```dart
class MainLayout extends StatefulWidget {
  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    HomeScreen(),
    CommunityHubScreen(),
    HistoryScreen(),
    ChatbotScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: MainBottomNavigation(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
```

---

## 🧪 Step 5: Testing (3-4 hours)

### 5.1 Unit Tests

Test services:
```dart
// test/services/community_service_test.dart
void main() {
  group('CommunityService', () {
    test('getFeedPosts returns list of posts', () async {
      final posts = await CommunityService().getFeedPosts();
      expect(posts, isA<List<PostData>>());
    });

    test('createPost returns new post', () async {
      final data = CreatePostData(content: 'Test post');
      final post = await CommunityService().createPost(data);
      expect(post.content, 'Test post');
    });
  });
}
```

### 5.2 Widget Tests

Test screens:
```dart
// test/screens/home_screen_test.dart
void main() {
  testWidgets('HomeScreen shows health rings', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: HomeScreen()),
    );

    expect(find.byType(HealthRings), findsOneWidget);
  });
}
```

### 5.3 Integration Tests

Test user flows:
```dart
// integration_test/community_flow_test.dart
void main() {
  testWidgets('User can create and like a post', (tester) async {
    // Navigate to community tab
    await tester.tap(find.byIcon(CupertinoIcons.person_2));
    await tester.pumpAndSettle();

    // Tap create post button
    await tester.tap(find.byIcon(CupertinoIcons.plus));
    await tester.pumpAndSettle();

    // Enter content
    await tester.enterText(find.byType(TextField), 'Test post');
    await tester.tap(find.text('Đăng'));
    await tester.pumpAndSettle();

    // Like the post
    await tester.tap(find.byIcon(CupertinoIcons.heart));
    await tester.pumpAndSettle();

    expect(find.byIcon(CupertinoIcons.heart_fill), findsOneWidget);
  });
}
```

---

## 📊 Database Schema (Reference)

### Tables Needed

```sql
-- community_posts
CREATE TABLE community_posts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id),
  content TEXT NOT NULL,
  image_url TEXT,
  meal_name TEXT,
  location TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- meal_macros
CREATE TABLE meal_macros (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  post_id UUID REFERENCES community_posts(id) ON DELETE CASCADE,
  calories INT,
  protein INT,
  carbs INT,
  fat INT
);

-- post_likes
CREATE TABLE post_likes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  post_id UUID REFERENCES community_posts(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(post_id, user_id)
);

-- post_bookmarks
CREATE TABLE post_bookmarks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  post_id UUID REFERENCES community_posts(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(post_id, user_id)
);

-- post_comments
CREATE TABLE post_comments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  post_id UUID REFERENCES community_posts(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id),
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- post_reports
CREATE TABLE post_reports (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  post_id UUID REFERENCES community_posts(id) ON DELETE CASCADE,
  reporter_id UUID REFERENCES auth.users(id),
  reason TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- hidden_posts
CREATE TABLE hidden_posts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  post_id UUID REFERENCES community_posts(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(post_id, user_id)
);

-- meals
CREATE TABLE meals (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id),
  name TEXT NOT NULL,
  meal_type TEXT,  -- breakfast, lunch, dinner, snack
  calories INT,
  protein INT,
  carbs INT,
  fat INT,
  image_url TEXT,
  logged_at TIMESTAMPTZ DEFAULT NOW()
);

-- weight_logs
CREATE TABLE weight_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id),
  weight DECIMAL(5,2),
  logged_at TIMESTAMPTZ DEFAULT NOW()
);

-- water_logs
CREATE TABLE water_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id),
  amount_ml INT,
  logged_at TIMESTAMPTZ DEFAULT NOW()
);

-- chat_messages
CREATE TABLE chat_messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id),
  message TEXT NOT NULL,
  response TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- user_achievements
CREATE TABLE user_achievements (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id),
  achievement_type TEXT NOT NULL,
  unlocked_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## 🎯 Implementation Priority

### Week 1: Foundation
1. ✅ Complete Service Layer (6 hours)
   - ApiService
   - CommunityService
   - MealService
   - HistoryService
   - ChatbotService
   - ProfileService

2. ✅ Setup State Management (3 hours)
   - UserProvider
   - PostsProvider
   - MealsProvider
   - HistoryProvider
   - ChatbotProvider

### Week 2: Core Screens
3. ✅ HomeScreen (4 hours)
4. ✅ CommunityHubScreen (3 hours)
5. ✅ Navigation Setup (2 hours)

### Week 3: Remaining Screens
6. ✅ HistoryScreen (4 hours)
7. ✅ ChatbotScreen (3 hours)
8. ✅ ProfileScreen (3 hours)

### Week 4: Polish & Test
9. ✅ Testing (4 hours)
10. ✅ Bug fixes (3 hours)
11. ✅ Performance optimization (2 hours)

**Total**: 37 hours

---

## 📝 Code Generation Templates

### Service Template

```dart
// lib/services/[name]_service.dart
import '../services/api_service.dart';

class [Name]Service {
  final ApiService _api = ApiService.instance;

  Future<List<T>> getAll() async {
    try {
      final response = await _api._client
          .from('[table_name]')
          .select()
          .order('created_at', ascending: false);
      return (response as List).map((json) => T.fromJson(json)).toList();
    } catch (e) {
      throw _api.handleError(e);
    }
  }

  Future<T> getById(String id) async {
    try {
      final response = await _api._client
          .from('[table_name]')
          .select()
          .eq('id', id)
          .single();
      return T.fromJson(response);
    } catch (e) {
      throw _api.handleError(e);
    }
  }

  Future<T> create(Map<String, dynamic> data) async {
    try {
      final response = await _api._client
          .from('[table_name]')
          .insert(data)
          .select()
          .single();
      return T.fromJson(response);
    } catch (e) {
      throw _api.handleError(e);
    }
  }
}
```

### Provider Template

```dart
// lib/providers/[name]_provider.dart
import 'package:flutter/foundation.dart';
import '../services/[name]_service.dart';

class [Name]Provider extends ChangeNotifier {
  final [Name]Service _service = [Name]Service();

  List<T> _items = [];
  bool _loading = false;
  String? _error;

  List<T> get items => _items;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadItems() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _items = await _service.getAll();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> addItem(Map<String, dynamic> data) async {
    try {
      final item = await _service.create(data);
      _items.insert(0, item);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
```

### Screen Template

```dart
// lib/screens/tabs/[name]_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../theme/colors.dart';
import '../../providers/[name]_provider.dart';

class [Name]Screen extends StatefulWidget {
  @override
  State<[Name]Screen> createState() => _[Name]ScreenState();
}

class _[Name]ScreenState extends State<[Name]Screen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<[Name]Provider>(context, listen: false).loadItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = Provider.of<[Name]Provider>(context);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: _buildAppBar(context, isDark),
      body: provider.loading
          ? Center(child: CircularProgressIndicator())
          : _buildContent(context, isDark, provider),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDark) {
    return AppBar(
      title: Text('[Screen Name]'),
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
    );
  }

  Widget _buildContent(BuildContext context, bool isDark, [Name]Provider provider) {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: provider.items.length,
      itemBuilder: (context, index) {
        final item = provider.items[index];
        return _buildItem(context, isDark, item);
      },
    );
  }

  Widget _buildItem(BuildContext context, bool isDark, T item) {
    return Container(
      // Item UI
    );
  }
}
```

---

## 🚀 Quick Start Commands

```bash
# Install dependencies
flutter pub get

# Generate code (if using build_runner)
flutter pub run build_runner build

# Run app
flutter run

# Run tests
flutter test

# Run integration tests
flutter test integration_test/
```

---

## 📚 Resources

- **Flutter Docs**: https://docs.flutter.dev
- **Provider**: https://pub.dev/packages/provider
- **Supabase Flutter**: https://supabase.com/docs/reference/dart/introduction
- **fl_chart**: https://pub.dev/packages/fl_chart

---

## ✅ Phase 3 Checklist

### Foundation
- [ ] Create ApiService ✅ DONE
- [ ] Create CommunityService
- [ ] Create MealService
- [ ] Create HistoryService
- [ ] Create ChatbotService
- [ ] Create ProfileService
- [ ] Setup Providers (5 providers)
- [ ] Create database schema

### Screens
- [ ] HomeScreen (800 lines)
- [ ] CommunityHubScreen (600 lines)
- [ ] HistoryScreen (700 lines)
- [ ] ChatbotScreen (500 lines)
- [ ] ProfileScreen (600 lines)
- [ ] Navigation (200 lines)

### Testing
- [ ] Unit tests for services
- [ ] Widget tests for screens
- [ ] Integration tests for flows

### Polish
- [ ] Error handling
- [ ] Loading states
- [ ] Empty states
- [ ] Pull to refresh
- [ ] Infinite scroll
- [ ] Performance optimization

---

**Total Estimated Lines**: ~5,000 lines of new code

**Completion Status**: 5% (ApiService created)

**Next Action**: Create remaining services or implement one complete screen

**Last Updated**: 2026-02-22 23:59
