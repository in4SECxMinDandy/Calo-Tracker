# React → Flutter Component Mapping Reference

Quick reference for developers familiar with the React codebase who need to understand the Flutter equivalent.

---

## 🎨 Design Tokens

| React (CSS Variables) | Flutter (Dart Constants) | Usage |
|----------------------|-------------------------|--------|
| `var(--color-primary-blue)` | `AppColors.primaryBlue` | Primary actions, focus |
| `var(--color-success-green)` | `AppColors.successGreen` | Success, health metrics |
| `var(--color-accent-mint)` | `AppColors.accentMint` | Accents (dark mode) |
| `var(--foreground)` | `isDark ? darkTextPrimary : lightTextPrimary` | Main text |
| `var(--background)` | `isDark ? darkBackground : lightBackground` | Background |
| `var(--card)` | `isDark ? darkCard : lightCard` | Card background |

---

## 🧩 Component Mapping

### GlassCard
| React | Flutter |
|-------|---------|
| File: `GlassCard.tsx` | `glass_card.dart` (already existed) |
| Props: `children`, `className`, `animated` | Parameters: `child`, `padding`, `blur` |
| `bg-[var(--glass-bg)]` | `AppColors.glassLight / glassDark` |
| `backdrop-blur-2xl` | `BackdropFilter(blur: 20)` |

```jsx
// React
<GlassCard className="p-5">
  <h2>Title</h2>
</GlassCard>
```

```dart
// Flutter
GlassCard(
  padding: EdgeInsets.all(20),
  child: Text('Title', style: AppTextStyles.heading2),
)
```

---

### HealthRings
| React | Flutter |
|-------|---------|
| File: `HealthRings.tsx` | `health_rings.dart` ✅ NEW |
| Tech: `<canvas>` + `useEffect` | `CustomPainter` + `AnimationController` |
| Props: `consumed`, `burned`, `target` | Same parameters |
| Animation: `requestAnimationFrame` | `AnimatedBuilder` |

```jsx
// React
<HealthRings consumed={1500} burned={400} target={2000} />
```

```dart
// Flutter
HealthRings(consumed: 1500, burned: 400, target: 2000)
```

**Key Differences**:
- React: Canvas 2D API (`ctx.arc`, `ctx.stroke`)
- Flutter: CustomPainter (`canvas.drawArc`, `Paint`)
- Both use cubic easing (1200ms)

---

### MacroBar
| React | Flutter |
|-------|---------|
| File: `MacroBar.tsx` | `macro_bar.dart` ✅ NEW |
| Animation: `motion.div` | `AnimatedBuilder` + `FractionallySizedBox` |
| Props: `label`, `value`, `max`, `color` | Same parameters |
| Duration: 800ms ease-out | Same |

```jsx
// React
<MacroBar label="P" value={65} max={150} unit="g" color="#EF4444" />
```

```dart
// Flutter
MacroBar(
  label: 'P',
  value: 65,
  max: 150,
  unit: 'g',
  color: AppColors.errorRed,
)
```

---

### NutritionPill
| React | Flutter |
|-------|---------|
| File: `NutritionPill.tsx` | `nutrition_pill.dart` ✅ NEW |
| Props: `label`, `value`, `bgColor`, `textColor` | `label`, `value`, `color` |
| Layout: `div` with `flex` | `Row` with `Container` |

```jsx
// React
<NutritionPill
  label="Protein"
  value={30}
  unit="g"
  bgColor="rgba(239,68,68,0.08)"
  textColor="#DC2626"
/>
```

```dart
// Flutter
NutritionPill(
  label: 'Protein',
  value: '30g',
  color: AppColors.errorRed,
)
```

**Key Differences**:
- React: Explicit bgColor and textColor
- Flutter: Auto-generates theme-aware colors from single `color` parameter

---

### StatBadge
| React | Flutter |
|-------|---------|
| File: `StatBadge.tsx` | `stat_badge.dart` ✅ NEW |
| Props: `icon`, `value`, `label`, `gradient` | Same parameters + `emoji` support |
| Layout: Flexbox column | `Column` widget |

```jsx
// React
<StatBadge
  icon={<Droplet />}
  value="1500"
  unit="ml"
  label="Nước uống"
  gradient="from-blue-500 to-cyan-500"
/>
```

```dart
// Flutter
StatBadge(
  icon: CupertinoIcons.drop,
  value: '1500',
  unit: 'ml',
  label: 'Nước uống',
  gradient: LinearGradient(
    colors: [AppColors.primaryBlue, AppColors.accentCyan],
  ),
)
```

---

### PostCard
| React | Flutter |
|-------|---------|
| File: `PostCard.tsx` | `post_card.dart` ✅ NEW |
| Props: `post`, `index`, `onLike`, `onBookmark` | Same parameters |
| Animation: `motion.article` | `SlideTransition` + `FadeTransition` |
| Icons: `lucide-react` | `CupertinoIcons` |

```jsx
// React
<PostCard
  post={postData}
  index={0}
  onLike={(id) => console.log(id)}
  onBookmark={(id) => console.log(id)}
/>
```

```dart
// Flutter
PostCard(
  post: postData,
  index: 0,
  onLike: (id) => print(id),
  onBookmark: (id) => print(id),
)
```

**Key Differences**:
- React: Uses `<img>` with `ImageWithFallback`
- Flutter: Uses `Image.network` with `errorBuilder`
- Both support: verified badge, online indicator, macro pills, engagement stats

---

### CreatePostModal
| React | Flutter |
|-------|---------|
| File: `CreatePostModal.tsx` | `create_post_modal.dart` ✅ NEW |
| Display: `fixed` overlay + `AnimatePresence` | `showModalBottomSheet` |
| Props: `isOpen`, `onClose`, `onPost` | `onPost` (isOpen/onClose handled by modal) |
| State: `useState` for form fields | `TextEditingController` |

```jsx
// React
<CreatePostModal
  isOpen={showModal}
  onClose={() => setShowModal(false)}
  onPost={(data) => console.log(data)}
/>
```

```dart
// Flutter
CreatePostModal.show(
  context,
  userName: 'User Name',
  userAvatar: 'https://...',
  onPost: (data) => print(data),
)
```

**Key Differences**:
- React: Controlled component (isOpen prop)
- Flutter: Imperative API (show() method)
- Both: Collapsible meal form, location input, action buttons

---

## 🎭 Animation Equivalents

| React (Framer Motion) | Flutter | Duration |
|----------------------|---------|----------|
| `initial={{ opacity: 0, y: 12 }}` | `Tween<Offset>(begin: Offset(0, 0.05))` | - |
| `animate={{ opacity: 1, y: 0 }}` | `Tween<Offset>(end: Offset.zero)` | - |
| `transition={{ duration: 0.4 }}` | `AnimationController(duration: 400ms)` | 400ms |
| `whileTap={{ scale: 0.9 }}` | `InkWell` with tap effect | 150ms |
| `motion.div` | `AnimatedBuilder` or `AnimatedContainer` | Varies |

---

## 📐 Layout Equivalents

| React (Tailwind) | Flutter | Notes |
|-----------------|---------|-------|
| `flex items-center gap-3` | `Row(children: [...], mainAxisAlignment: MainAxisAlignment.center)` | Horizontal |
| `flex flex-col gap-2` | `Column(children: [...])` | Vertical |
| `p-5` | `padding: EdgeInsets.all(20)` | 5 × 4 = 20 |
| `rounded-2xl` | `BorderRadius.circular(16)` | 2xl = 16px |
| `bg-white dark:bg-card` | `isDark ? darkCard : Colors.white` | Theme-aware |
| `text-[14px]` | `fontSize: 14` | Direct mapping |
| `font-semibold` (600) | `fontWeight: FontWeight.w600` | Same weight |

---

## 🔧 State Management

### React (useState)
```jsx
const [liked, setLiked] = useState(false);
const [content, setContent] = useState('');

<button onClick={() => setLiked(!liked)}>
  {liked ? '❤️' : '🤍'}
</button>
```

### Flutter (StatefulWidget)
```dart
bool _liked = false;
final _contentController = TextEditingController();

IconButton(
  icon: Icon(_liked ? CupertinoIcons.heart_fill : CupertinoIcons.heart),
  onPressed: () {
    setState(() {
      _liked = !_liked;
    });
  },
)
```

---

## 🎨 Styling Patterns

### React (Tailwind)
```jsx
<div className="
  bg-white dark:bg-[var(--card)]
  rounded-2xl
  shadow-md
  p-5
  hover:shadow-lg
  transition-all duration-200
">
  Content
</div>
```

### Flutter
```dart
Container(
  padding: EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: isDark ? AppColors.darkCard : Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 10,
        offset: Offset(0, 2),
      ),
    ],
  ),
  child: Text('Content'),
)
```

---

## 🔗 Event Handling

| React | Flutter | Notes |
|-------|---------|-------|
| `onClick={() => handleClick()}` | `onTap: () => _handleTap()` | GestureDetector |
| `onChange={(e) => setText(e.target.value)}` | `onChanged: (value) => setState(...)` | TextField |
| `onSubmit={handleSubmit}` | `onPressed: _handleSubmit` | Button |
| `whileTap={{ scale: 0.9 }}` | `InkWell` ripple effect | Visual feedback |

---

## 📦 Import Patterns

### React
```jsx
import { useState } from "react";
import { motion } from "motion/react";
import { Heart, Share2 } from "lucide-react";
```

### Flutter
```dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
```

---

## 🎯 Key Takeaways

1. **Widgets = Components**: Every React component maps to a Flutter Widget
2. **Props = Parameters**: Props become constructor parameters
3. **State = StatefulWidget**: useState → setState with StatefulWidget
4. **CSS-in-JS = BoxDecoration**: Tailwind classes → BoxDecoration properties
5. **Framer Motion = AnimationController**: motion.div → AnimatedBuilder
6. **Hooks = Mixins**: useEffect → initState/didUpdateWidget
7. **Context = BuildContext**: Access theme via Theme.of(context)

---

## 📚 Further Reading

- [REDESIGN_MIGRATION_PLAN.md](REDESIGN_MIGRATION_PLAN.md) - Full migration strategy
- [REDESIGN_IMPLEMENTATION_SUMMARY.md](REDESIGN_IMPLEMENTATION_SUMMARY.md) - Implementation details
- [REDESIGN_QUICK_START.md](REDESIGN_QUICK_START.md) - Usage examples

---

**Last Updated**: 2026-02-22
