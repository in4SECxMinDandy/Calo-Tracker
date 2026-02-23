# 🚀 Quick Reference Card

**One-page cheat sheet for Component Enhancement**

---

## ⚡ TL;DR

```bash
# Install
cd calotracker && flutter pub get

# Files created:
# ✅ create_post_modal_enhanced.dart (850 lines)
# ✅ post_options_menu.dart (350 lines)
# ✅ Updated: post_card.dart, colors.dart, pubspec.yaml

# Features: Camera, Gallery, Emoji, Edit, Delete, Report, Hide, Save, Copy
# Status: 100% Complete ✅
```

---

## 📦 Quick Import

```dart
// Enhanced CreatePostModal
import 'package:calotracker/widgets/redesign/community/create_post_modal_enhanced.dart';

// PostCard with options menu
import 'package:calotracker/widgets/redesign/community/post_card.dart';

// Options menu (auto-imported by post_card.dart)
import 'package:calotracker/widgets/redesign/community/post_options_menu.dart';
```

---

## 🎯 Usage (Copy-Paste Ready)

### Create Post Modal

```dart
// Open modal
CreatePostModal.show(
  context,
  userName: 'User Name',
  userAvatar: 'https://example.com/avatar.jpg',
  onPost: (data) {
    print('Content: ${data.content}');
    print('Image: ${data.imagePath}');
    print('Meal: ${data.mealName}');
    print('Macros: ${data.macros?.calories} kcal');
    print('Location: ${data.location}');
    // TODO: Upload to API
  },
);
```

### Post Card with Options

```dart
PostCard(
  post: myPost,
  currentUserId: 'user_123',
  onLike: (id) => print('Like: $id'),
  onBookmark: (id) => print('Bookmark: $id'),
  onComment: (id) => print('Comment: $id'),
  onShare: (id) => print('Share: $id'),
  onEdit: (id) => print('Edit: $id'),
  onDelete: (id) => print('Delete: $id'),
  onReport: (id) => print('Report: $id'),
  onHidePost: (id) => print('Hide: $id'),
)
```

---

## 🔧 Setup (5 Minutes)

### 1. Install Package

```bash
flutter pub get
```

### 2. Android Permissions (`AndroidManifest.xml`)

```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
```

### 3. iOS Permissions (`Info.plist`)

```xml
<key>NSCameraUsageDescription</key>
<string>Cần camera để chụp ảnh</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Cần thư viện ảnh</string>
```

---

## 🎨 Features Summary

| Feature | Status | File |
|---------|--------|------|
| 📷 Camera | ✅ | create_post_modal_enhanced.dart |
| 🖼️ Image Picker | ✅ | create_post_modal_enhanced.dart |
| 😀 Emoji Picker | ✅ | create_post_modal_enhanced.dart |
| ✏️ Edit Post | ✅ | post_options_menu.dart |
| 🗑️ Delete Post | ✅ | post_options_menu.dart |
| ⚠️ Report Post | ✅ | post_options_menu.dart |
| 👁️‍🗨️ Hide Post | ✅ | post_options_menu.dart |
| 🔖 Save/Unsave | ✅ | post_options_menu.dart |
| 🔗 Copy Link | ✅ | post_options_menu.dart |

---

## 🐛 Common Issues

### Camera not working
- ⚠️ Must test on **real device** (emulator doesn't support camera)
- ✅ Check permissions in AndroidManifest.xml and Info.plist

### Permission denied
```bash
# Android: Reset permissions
adb shell pm reset-permissions com.example.calotracker
```

### Emoji picker not showing
```bash
flutter clean && flutter pub get
```

---

## 📊 API Integration

```dart
class PostService {
  Future<void> createPost(CreatePostData data) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/posts'));

    request.fields['content'] = data.content;
    if (data.imagePath != null) {
      request.files.add(await http.MultipartFile.fromPath('image', data.imagePath!));
    }

    var response = await request.send();
    if (response.statusCode == 201) {
      print('✅ Post created');
    }
  }
}
```

---

## 🎯 Callbacks Reference

### CreatePostModal Callbacks

```dart
onPost: (CreatePostData data) {
  // data.content: String
  // data.imagePath: String?
  // data.mealName: String?
  // data.macros: MacroInput?
  // data.location: String?
}
```

### PostCard Callbacks

```dart
onLike: (String postId) {}      // Required
onBookmark: (String postId) {}  // Required
onComment: (String postId) {}   // Optional
onShare: (String postId) {}     // Optional
onEdit: (String postId) {}      // Optional
onDelete: (String postId) {}    // Optional
onReport: (String postId) {}    // Optional
onHidePost: (String postId) {}  // Optional
```

---

## 🔍 File Locations

```
calotracker/lib/widgets/redesign/community/
├── create_post_modal_enhanced.dart  ← NEW (850 lines)
├── post_options_menu.dart           ← NEW (350 lines)
└── post_card.dart                   ← UPDATED

calotracker/lib/theme/
└── colors.dart                      ← UPDATED (+4 colors)

calotracker/
└── pubspec.yaml                     ← UPDATED (+emoji_picker_flutter)
```

---

## 📚 Documentation Links

| Doc | Purpose | Time |
|-----|---------|------|
| [FINAL_SUMMARY](FINAL_SUMMARY.md) | Overview | 5 min |
| [INSTALLATION_TESTING_GUIDE](INSTALLATION_TESTING_GUIDE.md) | Setup | 10 min |
| [COMPONENT_ENHANCEMENT](COMPONENT_ENHANCEMENT_COMPLETE.md) | Features | 12 min |
| [BEFORE_AFTER_COMPARISON](BEFORE_AFTER_COMPARISON.md) | Changes | 8 min |
| [ARCHITECTURE_DIAGRAMS](ARCHITECTURE_DIAGRAMS.md) | Architecture | 10 min |

---

## ✅ Pre-Deploy Checklist

- [ ] `flutter pub get` completed
- [ ] Permissions added to AndroidManifest.xml
- [ ] Permissions added to Info.plist
- [ ] Tested camera on real Android device
- [ ] Tested camera on real iOS device
- [ ] Tested image picker
- [ ] Tested emoji picker
- [ ] Tested options menu (own post)
- [ ] Tested options menu (others' post)
- [ ] Backend API ready
- [ ] Error handling tested

---

## 🚦 Status

| Component | Status | Notes |
|-----------|--------|-------|
| Code | ✅ 100% | All features implemented |
| Tests | ⚠️ Manual | Automated tests TODO |
| Docs | ✅ 100% | 10 comprehensive docs |
| Backend | ⚠️ TODO | API integration needed |

---

## 💡 Quick Tips

1. **Camera**: Only works on real device
2. **Image Quality**: Auto-optimized to ~500KB
3. **Emoji Picker**: 250px height, toggles keyboard
4. **Options Menu**: Context-aware (own vs others)
5. **Dark Mode**: All components support it
6. **Type Safety**: Null-safe throughout

---

## 🎓 Learning Resources

- **Flutter Docs**: https://docs.flutter.dev
- **Image Picker**: https://pub.dev/packages/image_picker
- **Emoji Picker**: https://pub.dev/packages/emoji_picker_flutter

---

## 📞 Need Help?

1. **Troubleshooting** → [INSTALLATION_TESTING_GUIDE.md](INSTALLATION_TESTING_GUIDE.md)
2. **Examples** → [COMPONENT_ENHANCEMENT_COMPLETE.md](COMPONENT_ENHANCEMENT_COMPLETE.md)
3. **Architecture** → [ARCHITECTURE_DIAGRAMS.md](ARCHITECTURE_DIAGRAMS.md)

---

**Print this card and keep it handy! 📄**

**Last Updated**: 2026-02-22 23:59
