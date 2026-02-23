# Architecture & Flow Diagrams

## 📐 Component Architecture

```
calotracker/
├── lib/
│   ├── theme/
│   │   ├── colors.dart ✅ (Enhanced: +4 colors)
│   │   └── text_styles.dart
│   │
│   └── widgets/redesign/
│       ├── health_rings.dart ✅
│       ├── macro_bar.dart ✅
│       ├── nutrition_pill.dart ✅
│       ├── stat_badge.dart ✅ (Fixed: removed import)
│       │
│       └── community/
│           ├── create_post_modal.dart (OLD - has TODOs)
│           ├── create_post_modal_enhanced.dart ✅ NEW
│           ├── post_card.dart ✅ (Enhanced: +options menu)
│           └── post_options_menu.dart ✅ NEW
│
└── pubspec.yaml ✅ (Added: emoji_picker_flutter)
```

---

## 🔄 CreatePostModal Flow

### User Flow Diagram

```
┌─────────────────────────────────────────────────────────┐
│                   User taps "Create Post"               │
└─────────────────────┬───────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────┐
│          CreatePostModal.show() opens bottom sheet      │
│                  with slide-up animation                │
└─────────────────────┬───────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────┐
│                  User sees modal UI:                    │
│  • Text input field (multi-line)                        │
│  • Action bar with 5 buttons:                           │
│    [📷 Camera] [🖼️ Image] [🥗 Meal] [📍 Location] [😀 Emoji]│
│  • Post button (disabled until text entered)            │
└──┬────────┬────────┬────────┬────────┬─────────────────┘
   │        │        │        │        │
   │        │        │        │        │
   ▼        ▼        ▼        ▼        ▼
┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐
│Camera│ │Image │ │Meal  │ │Locat.│ │Emoji │
│      │ │Picker│ │Form  │ │Input │ │Picker│
└──┬───┘ └──┬───┘ └──┬───┘ └──┬───┘ └──┬───┘
   │        │        │        │        │
   ▼        ▼        ▼        ▼        ▼
┌──────────────────────────────────────────────────┐
│  1. Camera:                                      │
│     • Opens camera                               │
│     • User takes photo                           │
│     • Shows preview in modal                     │
│     • Can remove with X button                   │
│                                                  │
│  2. Image Picker:                                │
│     • Opens gallery                              │
│     • User selects image                         │
│     • Shows preview in modal                     │
│     • Can remove with X button                   │
│                                                  │
│  3. Meal Form:                                   │
│     • Toggles green meal form                    │
│     • Inputs: meal name, cals, P/C/F             │
│     • Form slides in/out                         │
│                                                  │
│  4. Location:                                    │
│     • Shows location input field                 │
│     • User types location                        │
│     • Shows badge in user info                   │
│                                                  │
│  5. Emoji Picker:                                │
│     • Replaces keyboard with emoji picker        │
│     • 1000+ emojis in categories                 │
│     • Tap emoji → inserts at cursor              │
│     • Tap again → closes, shows keyboard         │
└──────────────────┬───────────────────────────────┘
                   │
                   ▼
┌──────────────────────────────────────────────────┐
│  User types content (with emojis) + adds image   │
│  Post button turns green (enabled)               │
└──────────────────┬───────────────────────────────┘
                   │
                   ▼
┌──────────────────────────────────────────────────┐
│  User taps "Đăng" button                         │
└──────────────────┬───────────────────────────────┘
                   │
                   ▼
┌──────────────────────────────────────────────────┐
│  onPost callback fires with CreatePostData:      │
│  • content: String (text with emojis)            │
│  • imagePath: String? (from camera/gallery)      │
│  • mealName: String?                             │
│  • macros: MacroInput? (cals, P/C/F)             │
│  • location: String?                             │
└──────────────────┬───────────────────────────────┘
                   │
                   ▼
┌──────────────────────────────────────────────────┐
│  Modal closes with animation                     │
│  App uploads post to backend                     │
│  Shows success toast                             │
└──────────────────────────────────────────────────┘
```

---

## ⚙️ PostCard Options Menu Flow

### User Flow Diagram

```
┌─────────────────────────────────────────────────────────┐
│          User sees PostCard in community feed           │
│  • Author avatar, name, badge                           │
│  • Post content, image (if any)                         │
│  • Meal info (if any)                                   │
│  • Like, Comment, Share buttons                         │
│  • 3-dot menu button (top-right) ◦◦◦                    │
└─────────────────────┬───────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────┐
│            User taps 3-dot menu button (◦◦◦)            │
└─────────────────────┬───────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────┐
│      PostOptionsMenu.show() opens bottom sheet          │
│            (iOS-style with handle bar)                  │
└─────────────────────┬───────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────┐
│         Check: post.author == currentUserId?            │
└──────────────────┬──────────────────────────────────────┘
                   │
        ┌──────────┴──────────┐
        │                     │
        ▼                     ▼
    [YES: Own Post]      [NO: Others' Post]
        │                     │
        ▼                     ▼
┌───────────────────┐  ┌───────────────────┐
│  Own Post Menu:   │  │ Others' Post Menu:│
│  • ✏️ Edit        │  │  • 👁️‍🗨️ Hide      │
│  • 🗑️ Delete      │  │  • ⚠️ Report       │
│  ────────────     │  │  ────────────     │
│  • 🔖 Save/Unsave │  │  • 🔖 Save/Unsave │
│  • 🔗 Copy link   │  │  • 🔗 Copy link   │
└─────────┬─────────┘  └─────────┬─────────┘
          │                      │
          └──────────┬───────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│                 User selects option:                    │
└──┬───────┬───────┬───────┬───────┬───────┬──────────────┘
   │       │       │       │       │       │
   ▼       ▼       ▼       ▼       ▼       ▼
┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐
│Edit │ │Delete│ │Save │ │Copy │ │Hide │ │Report│
└──┬──┘ └──┬──┘ └──┬──┘ └──┬──┘ └──┬──┘ └──┬──┘
   │       │       │       │       │       │
   │       │       │       │       │       │
   ▼       ▼       ▼       ▼       ▼       ▼

1. EDIT:
   • Bottom sheet closes
   • onEdit(postId) callback
   • Opens edit modal
   • User edits content
   • Saves changes

2. DELETE:
   • Shows AlertDialog:
     "Xóa bài viết?"
     "Bài viết sẽ bị xóa vĩnh viễn"
     [Hủy] [Xóa]
   • If user confirms:
     - onDelete(postId) callback
     - Post removed from feed
     - Shows toast: "Đã xóa"

3. SAVE/UNSAVE:
   • Bottom sheet closes
   • onBookmark(postId) callback
   • Toggles bookmark state
   • Shows toast: "Đã lưu" / "Đã bỏ lưu"

4. COPY LINK:
   • Bottom sheet closes
   • Copies to clipboard:
     "https://calotracker.app/post/{postId}"
   • Shows toast: "Đã sao chép liên kết"

5. HIDE:
   • Bottom sheet closes
   • onHidePost(postId) callback
   • Post removed from feed
   • Shows toast: "Đã ẩn bài viết"

6. REPORT:
   • Shows AlertDialog with 6 reasons:
     ○ Spam hoặc lừa đảo
     ○ Nội dung không phù hợp
     ○ Thông tin sai lệch
     ○ Quấy rối hoặc bắt nạt
     ○ Bạo lực hoặc nguy hiểm
     ○ Khác
     [Hủy] [Gửi báo cáo]
   • User selects reason
   • If user confirms:
     - onReport(postId) callback
     - Shows toast: "Cảm ơn. Sẽ xem xét"
```

---

## 🎨 Component Hierarchy

### CreatePostModal Component Tree

```
CreatePostModal (StatefulWidget)
│
├── ScaleTransition (animation wrapper)
│   └── Container (rounded corners, theme color)
│       └── Column
│           ├── _buildHeader()
│           │   ├── Close button (X icon)
│           │   ├── Title ("Tạo bài viết")
│           │   └── Post button (green when enabled)
│           │
│           ├── Flexible
│           │   └── SingleChildScrollView
│           │       └── Column
│           │           ├── _buildUserInfo()
│           │           │   ├── Avatar (circle)
│           │           │   ├── Name
│           │           │   └── Location badge (if set)
│           │           │
│           │           ├── _buildTextInput()
│           │           │   └── TextField (multi-line)
│           │           │
│           │           ├── _buildImagePreview() (if image)
│           │           │   ├── Image (rounded)
│           │           │   └── Remove button (X)
│           │           │
│           │           ├── _buildMealForm() (if visible)
│           │           │   └── Container (green theme)
│           │           │       ├── Meal name input
│           │           │       └── Row × 2 (P/C/F inputs)
│           │           │
│           │           └── _buildLocationInput() (if visible)
│           │               └── TextField
│           │
│           ├── if (_showEmojiPicker)
│           │   └── EmojiPicker (250px height)
│           │       ├── Categories (Recent, Smileys, etc.)
│           │       └── Emoji grid (7 columns)
│           │
│           └── if (!_showEmojiPicker)
│               └── _buildActionBar()
│                   └── Row (5 buttons)
│                       ├── Camera button
│                       ├── Image button
│                       ├── Meal button
│                       ├── Location button
│                       └── Emoji button
```

---

### PostCard Component Tree

```
PostCard (StatefulWidget)
│
├── Container (card with shadow)
│   └── Column
│       ├── _buildHeader()
│       │   ├── Avatar (with online indicator)
│       │   ├── Column
│       │   │   ├── Row (username + badge + verified)
│       │   │   ├── Location (if any)
│       │   │   └── Timestamp
│       │   └── More button (◦◦◦) ← triggers PostOptionsMenu
│       │
│       ├── _buildContent()
│       │   └── Text (content with emojis)
│       │
│       ├── _buildImage() (if image)
│       │   └── Image (rounded corners)
│       │
│       ├── _buildMealInfo() (if meal data)
│       │   └── Container (green theme)
│       │       ├── Meal name + emoji
│       │       └── Macro bars (P/C/F)
│       │
│       ├── _buildStats()
│       │   └── Row (likes, comments, shares counts)
│       │
│       └── _buildActions()
│           └── Row (4 buttons)
│               ├── Like button (heart)
│               ├── Comment button
│               ├── Share button
│               └── Bookmark button
```

---

### PostOptionsMenu Component Tree

```
PostOptionsMenu.show() (Static method)
│
└── ModalBottomSheet
    └── Container (rounded top corners)
        └── SafeArea
            └── Column
                ├── Handle bar (drag indicator)
                │
                ├── Title ("Tùy chọn bài viết")
                │
                ├── if (isOwnPost) ───────┐
                │   ├── Edit option       │
                │   ├── Delete option     │ Own Post Options
                │   └── Divider           │
                │                         ┘
                ├── Save/Unsave option ───┐
                ├── Copy link option      │ All Posts
                │                         ┘
                └── if (!isOwnPost) ──────┐
                    ├── Hide option       │
                    ├── Divider           │ Others' Options
                    └── Report option     │
                                          ┘
```

---

## 🔌 Data Flow

### CreatePostModal Data Flow

```
┌──────────────┐
│  User Input  │
└──────┬───────┘
       │
       ├─ Text: TextField → _contentController
       ├─ Image: Camera/Gallery → _imagePath
       ├─ Emoji: EmojiPicker → inserts into _contentController
       ├─ Meal: MealForm → _mealNameController, _caloriesController, etc.
       └─ Location: LocationInput → _locationController
       │
       ▼
┌──────────────────────┐
│  User taps "Đăng"    │
└──────┬───────────────┘
       │
       ▼
┌──────────────────────┐
│  _handlePost()       │
│  • Reads all inputs  │
│  • Creates MacroInput│
│  • Creates PostData  │
└──────┬───────────────┘
       │
       ▼
┌──────────────────────────────┐
│  widget.onPost(CreatePostData)│
│  • content: String            │
│  • imagePath: String?         │
│  • mealName: String?          │
│  • macros: MacroInput?        │
│  • location: String?          │
└──────┬───────────────────────┘
       │
       ▼
┌──────────────────────┐
│  Parent Widget       │
│  • Uploads to API    │
│  • Shows success     │
│  • Updates feed      │
└──────────────────────┘
```

---

### PostOptionsMenu Data Flow

```
┌──────────────────┐
│  User taps ◦◦◦   │
└──────┬───────────┘
       │
       ▼
┌────────────────────────────┐
│  PostOptionsMenu.show()    │
│  Parameters:               │
│  • postId                  │
│  • postAuthorId            │
│  • currentUserId           │
│  • isBookmarked            │
│  • callbacks (6 functions) │
└──────┬─────────────────────┘
       │
       ▼
┌────────────────────────────┐
│  Check ownership           │
│  postAuthorId == currentId?│
└──┬──────────────────────┬──┘
   │ YES               NO │
   ▼                      ▼
┌──────────┐      ┌──────────┐
│ Own Menu │      │ Others   │
└──────┬───┘      └───┬──────┘
       │              │
       └──────┬───────┘
              │
              ▼
┌──────────────────────────┐
│  User selects option     │
└──────┬───────────────────┘
       │
       ├─ Edit → Navigator.pop() → onEdit(postId)
       ├─ Delete → showDialog() → onDelete(postId)
       ├─ Save → Navigator.pop() → onBookmark(postId)
       ├─ Copy → Navigator.pop() → Clipboard.setData()
       ├─ Hide → Navigator.pop() → onHidePost(postId)
       └─ Report → showDialog() → onReport(postId)
              │
              ▼
┌──────────────────────────┐
│  Parent Widget           │
│  • Updates backend       │
│  • Updates UI state      │
│  • Shows feedback        │
└──────────────────────────┘
```

---

## 📊 State Management

### CreatePostModal State

```dart
class _CreatePostModalState {
  // Controllers
  - _contentController: TextEditingController
  - _mealNameController: TextEditingController
  - _caloriesController: TextEditingController
  - _proteinController: TextEditingController
  - _carbsController: TextEditingController
  - _fatController: TextEditingController
  - _locationController: TextEditingController
  - _contentFocusNode: FocusNode

  // UI State
  - _showMealForm: bool
  - _showLocation: bool
  - _showEmojiPicker: bool
  - _imagePath: String?

  // Animations
  - _animController: AnimationController
  - _scaleAnimation: Animation<double>

  // Image Picker
  - _picker: ImagePicker
}
```

### PostCard State

```dart
class _PostCardState {
  // Animation
  - _animController: AnimationController
  - _slideAnimation: Animation<Offset>

  // No other state needed - all data from widget.post
}
```

---

## 🎯 Callback Chain

```
User Action
    │
    ▼
UI Component (CreatePostModal / PostCard)
    │
    ▼
Callback (onPost / onEdit / onDelete / etc.)
    │
    ▼
Parent Widget (CommunityScreen / HomeScreen)
    │
    ▼
Service Layer (PostService)
    │
    ▼
Backend API (Supabase / Custom API)
    │
    ▼
Database (PostgreSQL / etc.)
    │
    ▼
Response
    │
    ▼
Update UI State (Provider / setState)
    │
    ▼
Show Feedback (Toast / SnackBar)
```

---

## 🔐 Permission Flow

### Camera Permission

```
User taps Camera button
    │
    ▼
_pickImageFromCamera() calls ImagePicker
    │
    ▼
Plugin checks permission
    │
    ├─ Granted? → Opens camera
    │
    └─ Denied? → Shows system dialog
           │
           ├─ User grants → Opens camera
           │
           └─ User denies → Shows error toast
```

### Gallery Permission

```
User taps Image button
    │
    ▼
_pickImageFromGallery() calls ImagePicker
    │
    ▼
Plugin checks permission
    │
    ├─ Granted? → Opens gallery
    │
    └─ Denied? → Shows system dialog
           │
           ├─ User grants → Opens gallery
           │
           └─ User denies → Shows error toast
```

---

## 📱 Platform Differences

| Feature | Android | iOS |
|---------|---------|-----|
| **Camera** | Needs CAMERA permission | Needs NSCameraUsageDescription |
| **Gallery** | Needs READ_MEDIA_IMAGES | Needs NSPhotoLibraryUsageDescription |
| **Emoji Picker** | Same | Same |
| **Bottom Sheet** | Material style | Cupertino style (iOS) |
| **Dialogs** | AlertDialog | CupertinoAlertDialog (both work) |

---

**Last Updated**: 2026-02-22 23:59
