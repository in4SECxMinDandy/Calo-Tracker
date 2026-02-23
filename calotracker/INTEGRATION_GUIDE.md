# 🔌 Quick Integration Guide

**How to integrate Phase 2 redesigned components into existing screens**

---

## 📋 Integration Checklist

### Step 1: Import Redesigned Components

```dart
// Add these imports at the top of your screen file
import 'package:calotracker/widgets/redesign/health_rings.dart';
import 'package:calotracker/widgets/redesign/macro_bar.dart';
import 'package:calotracker/widgets/redesign/nutrition_pill.dart';
import 'package:calotracker/widgets/redesign/stat_badge.dart';
import 'package:calotracker/widgets/redesign/glass_card.dart';
import 'package:calotracker/widgets/redesign/simple_card.dart';
import 'package:calotracker/widgets/redesign/community/post_card.dart';
import 'package:calotracker/widgets/redesign/community/create_post_modal_enhanced.dart';
import 'package:calotracker/widgets/redesign/community/post_options_menu.dart';
```

### Step 2: Replace Old Components

---

## 🏠 HomeScreen Integration

### Find & Replace: Health Rings

**❌ OLD CODE** (look for something like this):
```dart
// Old custom paint health rings
CustomPaint(
  size: Size(300, 300),
  painter: HealthRingsPainter(
    caloriesPercent: caloriesPercent,
    proteinPercent: proteinPercent,
    // ...
  ),
)
```

**✅ NEW CODE**:
```dart
// New HealthRings component
HealthRings(
  caloriesConsumed: _todayRecord?.totalCalories?.toDouble() ?? 0,
  caloriesGoal: _userProfile?.caloIntake?.toDouble() ?? 2000,
  protein: _todayRecord?.totalProtein?.toDouble() ?? 0,
  proteinGoal: _userProfile?.proteinIntake?.toDouble() ?? 150,
  carbs: _todayRecord?.totalCarbs?.toDouble() ?? 0,
  carbsGoal: _userProfile?.carbsIntake?.toDouble() ?? 250,
  fat: _todayRecord?.totalFat?.toDouble() ?? 0,
  fatGoal: _userProfile?.fatIntake?.toDouble() ?? 70,
  size: 280,
)
```

### Find & Replace: Macro Bars

**❌ OLD CODE**:
```dart
// Old LinearProgressIndicator
Column(
  children: [
    Text('Protein: ${protein}g / ${proteinGoal}g'),
    LinearProgressIndicator(
      value: protein / proteinGoal,
      backgroundColor: Colors.grey[300],
      valueColor: AlwaysStoppedAnimation(Colors.red),
    ),
    // Repeat for carbs and fat...
  ],
)
```

**✅ NEW CODE**:
```dart
// New MacroBar components
Column(
  children: [
    MacroBar(
      label: 'Protein',
      currentValue: _todayRecord?.totalProtein?.toDouble() ?? 0,
      goalValue: _userProfile?.proteinIntake?.toDouble() ?? 150,
      unit: 'g',
      color: AppColors.protein,
    ),
    SizedBox(height: 12),
    MacroBar(
      label: 'Carbs',
      currentValue: _todayRecord?.totalCarbs?.toDouble() ?? 0,
      goalValue: _userProfile?.carbsIntake?.toDouble() ?? 250,
      unit: 'g',
      color: AppColors.carbs,
    ),
    SizedBox(height: 12),
    MacroBar(
      label: 'Fat',
      currentValue: _todayRecord?.totalFat?.toDouble() ?? 0,
      goalValue: _userProfile?.fatIntake?.toDouble() ?? 70,
      unit: 'g',
      color: AppColors.fat,
    ),
  ],
)
```

### Find & Replace: Card Containers

**❌ OLD CODE**:
```dart
// Old Container with decoration
Container(
  padding: EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black12,
        blurRadius: 8,
      ),
    ],
  ),
  child: Column(...),
)
```

**✅ NEW CODE**:
```dart
// New GlassCard
GlassCard(
  child: Column(...),
)

// Or SimpleCard for non-glass effect
SimpleCard(
  child: Column(...),
)
```

---

## 👥 CommunityHubScreen Integration

### Check PostCard Import

**File**: `lib/screens/community/community_hub_screen.dart:28`

**Current import**:
```dart
import 'widgets/post_card.dart';
```

**Check if this is the OLD or NEW PostCard**:
1. Open `lib/screens/community/widgets/post_card.dart`
2. Look for these features:
   - Has `onEdit` callback?
   - Has `onDelete` callback?
   - Has `onReport` callback?
   - Has `onHidePost` callback?

**If OLD** (missing above callbacks):
```dart
// Replace import
import '../../widgets/redesign/community/post_card.dart';
import '../../widgets/redesign/community/post_options_menu.dart';

// Update PostCard usage
PostCard(
  post: post,
  currentUserId: _authService.currentUser?.id ?? '',
  onLike: (postId) => _communityService.likePost(postId),
  onBookmark: (postId) => _toggleBookmark(postId),
  onComment: (postId) => _showComments(postId),
  onShare: (postId) => _sharePost(postId),
  // NEW callbacks:
  onEdit: (postId) => _editPost(postId),
  onDelete: (postId) => _deletePost(postId),
  onReport: (postId) => _reportPost(postId),
  onHidePost: (postId) => _hidePost(postId),
)
```

### Add Callback Implementations

```dart
void _editPost(String postId) async {
  // Find the post
  final post = _feedPosts.firstWhere((p) => p.id == postId);

  // Open edit modal
  final result = await CreatePostModal.show(
    context,
    userName: _authService.currentUser?.userMetadata?['full_name'] ?? 'You',
    userAvatar: _authService.currentUser?.userMetadata?['avatar_url'],
    initialContent: post.content,
    initialImagePath: post.imageUrls.isNotEmpty ? post.imageUrls.first : null,
    onPost: (data) async {
      // Update post via API
      await _communityService.updatePost(postId, data.content);
      _loadData(); // Refresh feed
    },
  );
}

void _deletePost(String postId) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Xóa bài viết?'),
      content: Text('Bài viết sẽ bị xóa vĩnh viễn'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Hủy'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: Text('Xóa'),
        ),
      ],
    ),
  );

  if (confirm == true) {
    await _communityService.deletePost(postId);
    setState(() {
      _feedPosts.removeWhere((p) => p.id == postId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã xóa bài viết')),
    );
  }
}

void _reportPost(String postId) {
  PostOptionsMenu.showReportDialog(context, (reason) async {
    await _communityService.reportPost(postId, reason);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Cảm ơn. Chúng tôi sẽ xem xét báo cáo')),
    );
  });
}

void _hidePost(String postId) async {
  await _communityService.hidePost(postId);
  setState(() {
    _feedPosts.removeWhere((p) => p.id == postId);
  });
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Đã ẩn bài viết')),
  );
}

void _toggleBookmark(String postId) async {
  final post = _feedPosts.firstWhere((p) => p.id == postId);

  if (post.isBookmarked) {
    await _communityService.unsavePost(postId);
  } else {
    await _communityService.savePost(postId);
  }

  setState(() {
    post.isBookmarked = !post.isBookmarked;
  });

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(post.isBookmarked ? 'Đã lưu' : 'Đã bỏ lưu'),
    ),
  );
}
```

### Check CreatePostModal Import

**Current**:
```dart
import 'widgets/create_post_sheet.dart';
```

**NEW** (if you want camera/emoji features):
```dart
import '../../widgets/redesign/community/create_post_modal_enhanced.dart';

// Usage
CreatePostModal.show(
  context,
  userName: _authService.currentUser?.userMetadata?['full_name'] ?? 'You',
  userAvatar: _authService.currentUser?.userMetadata?['avatar_url'],
  onPost: (data) async {
    // Create post
    await _communityService.createPost(
      content: data.content,
      imageUrls: data.imagePath != null ? [data.imagePath!] : [],
      linkedData: data.mealName != null ? {
        'meal_name': data.mealName,
        'calories': data.macros?.calories,
        'protein': data.macros?.protein,
        'carbs': data.macros?.carbs,
        'fat': data.macros?.fat,
      } : null,
    );

    _loadData(); // Refresh feed
  },
)
```

---

## 📊 HistoryScreen Integration

### Find & Replace: Progress Bars

**❌ OLD CODE**:
```dart
// Old custom progress indicator
Row(
  children: [
    Text('P: ${protein}g'),
    Expanded(
      child: Container(
        height: 4,
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    ),
  ],
)
```

**✅ NEW CODE**:
```dart
// New MacroBar
MacroBar(
  label: 'Protein',
  currentValue: protein.toDouble(),
  goalValue: proteinGoal.toDouble(),
  unit: 'g',
  color: AppColors.protein,
  height: 24,
)
```

### Add Nutrition Pills for Daily Summary

**NEW CODE** (add to daily summary section):
```dart
Row(
  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  children: [
    NutritionPill(
      icon: CupertinoIcons.flame_fill,
      label: 'Calories',
      value: '${_selectedDayRecord?.totalCalories ?? 0}',
      color: AppColors.primaryBlue,
    ),
    NutritionPill(
      icon: CupertinoIcons.drop_fill,
      label: 'Water',
      value: '${_selectedDayRecord?.waterIntake ?? 0}ml',
      color: AppColors.secondaryBlue,
    ),
    NutritionPill(
      icon: CupertinoIcons.moon_fill,
      label: 'Sleep',
      value: '${_selectedDayRecord?.sleepHours ?? 0}h',
      color: Colors.purple,
    ),
  ],
)
```

---

## 👤 ProfileScreen Integration

### Add Stat Badges

**NEW CODE** (add to profile stats section):
```dart
Row(
  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  children: [
    StatBadge(
      icon: CupertinoIcons.flame_fill,
      value: '${_userProfile?.streakDays ?? 0}',
      label: 'Day Streak',
      color: AppColors.primaryOrange,
    ),
    StatBadge(
      icon: CupertinoIcons.star_fill,
      value: '${_userProfile?.totalPoints ?? 0}',
      label: 'Points',
      color: AppColors.primaryYellow,
    ),
    StatBadge(
      icon: CupertinoIcons.trophy_fill,
      value: '${_userProfile?.level ?? 1}',
      label: 'Level',
      color: AppColors.primaryPurple,
    ),
  ],
)
```

### Add Health Rings for Progress

**NEW CODE** (add to profile progress section):
```dart
Center(
  child: HealthRings(
    caloriesConsumed: weeklyCalories,
    caloriesGoal: weeklyGoal,
    protein: weeklyProtein,
    proteinGoal: weeklyProteinGoal,
    carbs: weeklyCarbs,
    carbsGoal: weeklyCarbsGoal,
    fat: weeklyFat,
    fatGoal: weeklyFatGoal,
    size: 240,
    showLabels: true,
  ),
)
```

---

## ✅ Verification Checklist

After integration, verify:

### HomeScreen
- [ ] HealthRings animates on load
- [ ] MacroBar shows correct percentages
- [ ] GlassCard has glassmorphism effect
- [ ] Dark mode works
- [ ] Values update when data changes

### CommunityHubScreen
- [ ] PostCard shows 3-dot menu
- [ ] Own posts show Edit/Delete options
- [ ] Others' posts show Report/Hide options
- [ ] CreatePostModal has camera button
- [ ] CreatePostModal has emoji button
- [ ] Image picker works
- [ ] Post creation works

### HistoryScreen
- [ ] MacroBar shows daily macros
- [ ] NutritionPill shows daily stats
- [ ] Charts update when date changes
- [ ] Dark mode works

### ProfileScreen
- [ ] StatBadge shows user stats
- [ ] HealthRings shows weekly progress
- [ ] Values are accurate

---

## 🐛 Common Issues

### Issue 1: Component not found
```
Error: 'HealthRings' isn't defined
```

**Fix**: Check import path
```dart
import 'package:calotracker/widgets/redesign/health_rings.dart';
```

### Issue 2: Dark mode not working
```
Colors don't change in dark mode
```

**Fix**: Use AppColors instead of hardcoded colors
```dart
// ❌ Wrong
color: Colors.blue

// ✅ Correct
color: AppColors.primaryBlue
```

### Issue 3: Animation not playing
```
HealthRings doesn't animate
```

**Fix**: Ensure parent widget is StatefulWidget with TickerProviderStateMixin
```dart
class _MyScreenState extends State<MyScreen> with TickerProviderStateMixin {
  // ...
}
```

### Issue 4: PostCard callbacks not firing
```
onEdit/onDelete not working
```

**Fix**: Ensure currentUserId is passed correctly
```dart
PostCard(
  post: post,
  currentUserId: _authService.currentUser?.id ?? '', // Must not be empty
  onEdit: (id) => print('Edit $id'), // Test with print first
  // ...
)
```

---

## 📚 Resources

- **Component API**: [API_REFERENCE.md](API_REFERENCE.md)
- **Quick Reference**: [QUICK_REFERENCE.md](QUICK_REFERENCE.md)
- **Architecture**: [ARCHITECTURE_DIAGRAMS.md](ARCHITECTURE_DIAGRAMS.md)
- **Troubleshooting**: [TROUBLESHOOTING_GUIDE.md](TROUBLESHOOTING_GUIDE.md)

---

## 🎯 Next Steps

1. ✅ Read this guide
2. ⏳ Pick a screen (start with HomeScreen)
3. ⏳ Find old components
4. ⏳ Replace with new components
5. ⏳ Test in app
6. ⏳ Move to next screen
7. ⏳ Repeat until all screens updated

---

**Estimated Time Per Screen**: 30-60 minutes

**Total Integration Time**: 3-5 hours for all main screens

**Difficulty**: Easy 🟢

---

**Last Updated**: 2026-02-22 Evening

**Status**: Ready to integrate! 🚀
