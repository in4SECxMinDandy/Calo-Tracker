# CaloTracker Redesign Migration Plan
## React/TypeScript → Flutter/Dart

**Date**: 2026-02-22
**Status**: In Progress
**Senior Developer**: Claude Code

---

## 🎯 Executive Summary

This document outlines the migration strategy for integrating the Figma-exported React/TypeScript UI into the existing CaloTracker Flutter application.

### Challenge
- **Source**: React 18 + TypeScript + Tailwind CSS v4 + Framer Motion
- **Target**: Flutter 3.x + Dart with existing design system
- **Approach**: Extract design patterns, rebuild components natively in Flutter

---

## 📊 Design System Mapping

### Color Palette (CSS Variables → Dart Constants)

| React (CSS Variable) | Flutter (AppColors) | Usage |
|----------------------|---------------------|--------|
| `--color-primary-blue: #2563EB` | `AppColors.primaryBlue` | ✅ Already exists |
| `--color-primary-indigo: #6366F1` | `AppColors.primaryIndigo` | ✅ Already exists |
| `--color-success-green: #10B981` | `AppColors.successGreen` | ✅ Already exists |
| `--color-warning-orange: #F59E0B` | `AppColors.warningOrange` | ✅ Already exists |
| `--color-error-red: #EF4444` | `AppColors.errorRed` | ✅ Already exists |
| `--color-accent-mint: #06D6A0` | ❌ **Need to add** | For accents |
| `--color-accent-cyan: #06B6D4` | ❌ **Need to add** | For water tracking |
| `--color-facebook-blue: #1877F2` | ❌ **Need to add** | Community tab |

### Typography Mapping

| React CSS | Flutter (AppTextStyles) | Status |
|-----------|-------------------------|--------|
| `h1` (2rem/32px, 700) | `heading1` (32px, w700) | ✅ Compatible |
| `h2` (1.5rem/24px, 600) | `heading2` (24px, w600) | ✅ Compatible |
| `p` (0.9375rem/15px) | `bodyMedium` (15px, w400) | ✅ Compatible |
| `label` (0.875rem/14px, 500) | `labelLarge` (14px, w500) | ✅ Compatible |

### Spacing & Radius

| React CSS | Flutter Equivalent | Notes |
|-----------|-------------------|-------|
| `rounded-2xl` (1rem) | `BorderRadius.circular(16)` | Standard card |
| `rounded-xl` (0.75rem) | `BorderRadius.circular(12)` | Buttons |
| `p-5` (1.25rem/20px) | `EdgeInsets.all(20)` | Card padding |
| `gap-3` (0.75rem/12px) | `SizedBox(height/width: 12)` | Spacing |

### Glassmorphism Effect

**React Implementation:**
```css
background: var(--glass-bg); /* rgba(255,255,255,0.85) */
backdrop-filter: blur(24px);
border: 1px solid var(--glass-border);
```

**Flutter Implementation:**
```dart
BackdropFilter(
  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
  child: Container(
    decoration: BoxDecoration(
      color: AppColors.glassLight, // Already exists!
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.glassBorder),
    ),
  ),
)
```

✅ **GlassCard widget already exists in Flutter project!**

---

## 🧩 Component Inventory & Porting Strategy

### ✅ Components Already Existing in Flutter

| Component | React Location | Flutter Location | Status |
|-----------|----------------|------------------|--------|
| GlassCard | `GlassCard.tsx` | `widgets/glass_card.dart` | ✅ Exists (may need enhancement) |
| SimpleCard | `SimpleCard.tsx` | `widgets/glass_card.dart` (SimpleCard class) | ✅ Exists |

### 🆕 New Components to Port

#### **Priority 1: Core UI Components**

1. **HealthRings** 🎯
   - **Source**: `HealthRings.tsx` (Canvas-based with animations)
   - **Target**: New `widgets/health_rings.dart`
   - **Tech**: `CustomPainter` with `AnimationController`
   - **Features**:
     - 3 concentric rings (consumed, burned, remaining)
     - Gradient strokes
     - Glow effects at ring endpoints
     - Center text (calories remaining)
     - Easing animation (cubic ease-out, 1200ms)

2. **MacroBar** 📊
   - **Source**: `MacroBar.tsx` (Animated progress bar)
   - **Target**: New `widgets/macro_bar.dart`
   - **Tech**: `AnimatedContainer` or `TweenAnimationBuilder`
   - **Features**:
     - Horizontal progress bar
     - Gradient or solid color fill
     - Animated width transition (800ms ease-out)
     - Label + value display

3. **NutritionPill** 💊
   - **Source**: `NutritionPill.tsx` (Compact stat display)
   - **Target**: New `widgets/nutrition_pill.dart`
   - **Tech**: Simple `Container` with rounded edges
   - **Features**:
     - Colored dot indicator
     - Label + value
     - Small, compact design

4. **StatBadge** 🏅
   - **Source**: `StatBadge.tsx` (Icon + value card)
   - **Target**: New `widgets/stat_badge.dart`
   - **Tech**: `Container` with gradient
   - **Features**:
     - Icon or emoji
     - Value + unit
     - Label text
     - Gradient background

#### **Priority 2: Social Features**

5. **PostCard** 📱
   - **Source**: `PostCard.tsx` (Social media post)
   - **Target**: New `widgets/community/post_card.dart`
   - **Tech**: Column layout with interactive buttons
   - **Features**:
     - Avatar + username + timestamp
     - Post content (text + optional image)
     - Like/Comment/Share buttons
     - Like count, comment count

6. **CreatePostModal** ✍️
   - **Source**: `CreatePostModal.tsx` (Bottom sheet)
   - **Target**: New `widgets/community/create_post_modal.dart`
   - **Tech**: `showModalBottomSheet` with `TextField`
   - **Features**:
     - Text input
     - Image picker button
     - Post button (gradient)
     - Character counter (optional)

---

## 📱 Screen Migration Plan

### Screens to Port

1. **HomeScreen** 🏠
   - **Source**: `HomeScreen.tsx`
   - **Target**: New `screens/tabs/home_screen_v2.dart`
   - **Components Used**:
     - Header with avatar + greeting + notifications
     - Stories bar (horizontal scroll with emoji circles)
     - HealthRings card
     - Quick actions (4 gradient cards)
     - Water intake card
     - Sleep tracking card
     - Social activity feed
   - **State**: Water intake counter, user profile data

2. **CommunityHubScreen** 👥
   - **Source**: `CommunityHubScreen.tsx`
   - **Target**: New `screens/tabs/community_hub_screen_v2.dart`
   - **Components Used**:
     - Tab bar (Posts, Groups, Challenges, Stories)
     - PostCard list
     - CreatePostModal
   - **State**: Selected tab, posts list, like/comment counts

3. **HistoryScreen** 📈
   - **Source**: `HistoryScreen.tsx`
   - **Target**: New `screens/tabs/history_screen_v2.dart`
   - **Components Used**:
     - Date range selector
     - Charts (line/bar charts for calories)
     - Meal list
   - **State**: Selected date range, chart data

4. **ChatbotScreen** 🤖
   - **Source**: `ChatbotScreen.tsx`
   - **Target**: New `screens/tabs/chatbot_screen_v2.dart`
   - **Components Used**:
     - Chat message bubbles
     - Input field with send button
   - **State**: Message list, input text

5. **ProfileScreen** 👤
   - **Source**: `ProfileScreen.tsx`
   - **Target**: New `screens/tabs/profile_screen_v2.dart`
   - **Components Used**:
     - Avatar + user info
     - BMR display
     - Goal selector
     - Stats cards
   - **State**: User profile, BMR, goal

---

## 🔧 Technical Implementation Strategy

### Phase 1: Enhanced Theme System ✅
- **File**: `lib/theme/colors.dart`
- **Action**: Add missing colors (mint, cyan, Facebook blue)
- **File**: `lib/theme/app_theme.dart`
- **Action**: Verify theme consistency

### Phase 2: Core Components 🎨
1. Create `lib/widgets/redesign/` folder
2. Port components in dependency order:
   - `health_rings.dart` (no dependencies)
   - `macro_bar.dart` (no dependencies)
   - `nutrition_pill.dart` (no dependencies)
   - `stat_badge.dart` (no dependencies)
3. Use existing design patterns:
   - Access theme via `Theme.of(context).brightness`
   - Use `AppColors` constants
   - Use `AppTextStyles` constants
   - Follow parameter naming: `isDark` for theme checks

### Phase 3: Community Components 👥
1. Create `lib/widgets/redesign/community/` folder
2. Port:
   - `post_card.dart`
   - `create_post_modal.dart`

### Phase 4: Screens 📱
1. Create `lib/screens/tabs_redesign/` folder
2. Port screens one by one
3. For each screen:
   - Create mock data at top of file (like React's `useState`)
   - Add TODO comments for API integration points
   - Use callbacks for user interactions (onTap, onPressed)
   - Prepare for state management (Provider/Riverpod/Bloc)

### Phase 5: State Management Preparation 🔌
1. Identify state requirements:
   - User profile (name, avatar, BMR)
   - Nutrition data (consumed, burned, target)
   - Water intake
   - Sleep hours
   - Community posts
   - Friends list
2. Create placeholder controller/provider files:
   - `lib/controllers/nutrition_controller.dart`
   - `lib/controllers/community_controller.dart`
   - `lib/controllers/profile_controller.dart`

---

## 🎨 Animation Strategy

### React (Framer Motion) → Flutter

| React Animation | Flutter Equivalent | Duration |
|-----------------|-------------------|----------|
| `initial: {opacity: 0, y: 12}` | `AnimatedOpacity` + `AnimatedPosition` | 400ms |
| `whileTap: {scale: 0.9}` | `GestureDetector` + `AnimatedScale` | 200ms |
| `motion.div` with spring | `AnimatedContainer` with `Curves.easeOut` | 300-800ms |

**Implementation Pattern:**
```dart
class AnimatedWidget extends StatefulWidget {
  @override
  _AnimatedWidgetState createState() => _AnimatedWidgetState();
}

class _AnimatedWidgetState extends State<AnimatedWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ... build method
}
```

---

## 🔗 API Integration Points

For each screen, document where data should come from:

### HomeScreen
- **User Profile**: `GET /api/user/profile` → name, avatar
- **Nutrition Data**: `GET /api/nutrition/today` → consumed, burned, target
- **Water Intake**: `GET /api/water/today` → current, target
- **Sleep Data**: `GET /api/sleep/today` → hours, quality
- **Social Feed**: `GET /api/social/feed` → friend activities

### CommunityHubScreen
- **Posts**: `GET /api/community/posts` → list of posts
- **Create Post**: `POST /api/community/posts` → submit new post
- **Like Post**: `POST /api/community/posts/{id}/like`
- **Comment**: `POST /api/community/posts/{id}/comments`

### HistoryScreen
- **Chart Data**: `GET /api/nutrition/history?start=X&end=Y`
- **Meal List**: `GET /api/meals?date=X`

### ChatbotScreen
- **Send Message**: `POST /api/ai/chat` → user message
- **Get Response**: Stream or polling for AI response

### ProfileScreen
- **User Data**: `GET /api/user/profile`
- **Update Goal**: `PATCH /api/user/goal` → lose/maintain/gain
- **Calculate BMR**: `POST /api/user/calculate-bmr`

---

## 📝 Code Conventions (Flutter)

### File Naming
- Widget files: `snake_case.dart` (e.g., `health_rings.dart`)
- Class names: `PascalCase` (e.g., `HealthRings`)

### Widget Parameters
- Required: Use `required` keyword
- Optional: Provide defaults or nullable types
- Theme-aware: Accept `isDark` or retrieve from `Theme.of(context)`

### State Management Preparation
- Keep state local in screens for now (using `StatefulWidget`)
- Add `// TODO: Connect to [Controller/Provider]` comments
- Design methods to accept callbacks:
  ```dart
  class MacroBar extends StatelessWidget {
    final String label;
    final double value;
    final VoidCallback? onTap;

    const MacroBar({
      required this.label,
      required this.value,
      this.onTap,
    });
  }
  ```

### Vietnamese Language
- All UI text in Vietnamese
- Follow existing patterns: "Tiêu thụ", "Đốt cháy", "Còn lại", etc.

---

## 🚀 Deployment Checklist

- [ ] Add new colors to `colors.dart`
- [ ] Port HealthRings component
- [ ] Port MacroBar component
- [ ] Port NutritionPill component
- [ ] Port StatBadge component
- [ ] Port PostCard component
- [ ] Port CreatePostModal component
- [ ] Port HomeScreen
- [ ] Port CommunityHubScreen
- [ ] Port HistoryScreen
- [ ] Port ChatbotScreen
- [ ] Port ProfileScreen
- [ ] Create controller/provider templates
- [ ] Document API endpoints for each screen
- [ ] Test on iOS simulator
- [ ] Test on Android emulator
- [ ] Verify dark mode support
- [ ] Verify animations performance

---

## 📖 Reference Links

- **React Source**: `Redesign CaloTracker Interface/src/`
- **Flutter Target**: `calotracker/lib/`
- **Design Tokens**: `Redesign CaloTracker Interface/src/styles/theme.css`
- **Flutter Theme**: `calotracker/lib/theme/`

---

## 🎯 Success Criteria

1. ✅ All components render correctly in both light and dark modes
2. ✅ Animations are smooth (60fps)
3. ✅ No hardcoded colors or sizes (all use theme system)
4. ✅ All text in Vietnamese
5. ✅ API integration points clearly documented
6. ✅ Code follows existing Flutter project conventions
7. ✅ State management structure prepared (controllers/providers)

---

**Last Updated**: 2026-02-22
**Next Review**: After Phase 2 completion
