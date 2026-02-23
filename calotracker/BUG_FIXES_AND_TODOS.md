# Bug Fixes & TODOs Summary

**Date**: 2026-02-22 23:55
**Issue Reporter**: User code review
**Status**: ✅ All bugs fixed

---

## 🐛 Issues Fixed

### Issue #1: Missing Color Definitions ✅ FIXED
**Files Affected**:
- `create_post_modal.dart`
- `post_card.dart`
- `macro_bar.dart`

**Missing Colors**:
- `AppColors.darkMuted`
- `AppColors.lightMuted`
- `AppColors.darkTextTertiary`
- `AppColors.lightTextTertiary`

**Solution**: Added to [`colors.dart:38-46`](calotracker/lib/theme/colors.dart#L38-L46)
```dart
// Light Theme Colors
static const Color lightTextTertiary = Color(0xFF9CA3AF);
static const Color lightMuted = Color(0xFFF3F4F6);

// Dark Theme Colors
static const Color darkTextTertiary = Color(0xFF6B7280);
static const Color darkMuted = Color(0xFF1E1E36);
```

**Color Usage**:
- `lightMuted` / `darkMuted`: Background for inactive buttons, input fields
- `lightTextTertiary` / `darkTextTertiary`: Tertiary text (least important, timestamps, metadata)

---

### Issue #2: Redundant Import ✅ FIXED
**File**: `stat_badge.dart:4`

**Problem**: Imported `package:flutter/cupertino.dart` but all needed widgets available in `material.dart`

**Solution**: Removed cupertino import

**Before**:
```dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';  // ← Removed
```

**After**:
```dart
import 'package:flutter/material.dart';
```

---

## 📝 TODOs Documented

These are intentional placeholders for future implementation:

### CreatePostModal TODOs

#### 1. Camera Integration (Line 592)
```dart
// TODO: Implement camera
// Suggested implementation:
onTap: () async {
  final ImagePicker picker = ImagePicker();
  final XFile? photo = await picker.pickImage(
    source: ImageSource.camera,
  );
  if (photo != null) {
    setState(() {
      _imagePath = photo.path;
    });
  }
}
```

**Required Package**:
```yaml
dependencies:
  image_picker: ^1.0.0
```

---

#### 2. Image Picker (Line 601)
```dart
// TODO: Implement image picker
// Suggested implementation:
onTap: () async {
  final ImagePicker picker = ImagePicker();
  final XFile? image = await picker.pickImage(
    source: ImageSource.gallery,
  );
  if (image != null) {
    setState(() {
      _imagePath = image.path;
    });
  }
}
```

**Same Package**: `image_picker: ^1.0.0`

---

#### 3. Emoji Picker (Line 634)
```dart
// TODO: Implement emoji picker
// Suggested implementation:
onTap: () {
  showModalBottomSheet(
    context: context,
    builder: (context) => EmojiPicker(
      onEmojiSelected: (category, emoji) {
        final text = _contentController.text;
        final selection = _contentController.selection;
        final newText = text.replaceRange(
          selection.start,
          selection.end,
          emoji.emoji,
        );
        _contentController.text = newText;
        Navigator.pop(context);
      },
    ),
  );
}
```

**Required Package**:
```yaml
dependencies:
  emoji_picker_flutter: ^2.0.0
```

---

### PostCard TODO

#### 4. Options Menu (Line 339)
```dart
// TODO: Show options menu
// Suggested implementation:
onPressed: () {
  showModalBottomSheet(
    context: context,
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: Icon(Icons.bookmark),
          title: Text('Lưu bài viết'),
          onTap: () {
            Navigator.pop(context);
            widget.onBookmark(widget.post.id);
          },
        ),
        ListTile(
          leading: Icon(Icons.link),
          title: Text('Sao chép liên kết'),
          onTap: () {
            Clipboard.setData(
              ClipboardData(text: 'https://app.com/post/${widget.post.id}'),
            );
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Đã sao chép liên kết')),
            );
          },
        ),
        ListTile(
          leading: Icon(Icons.report, color: Colors.red),
          title: Text('Báo cáo', style: TextStyle(color: Colors.red)),
          onTap: () {
            Navigator.pop(context);
            // Show report dialog
          },
        ),
      ],
    ),
  );
}
```

---

## 📦 Recommended Packages for TODOs

Add these to `pubspec.yaml`:

```yaml
dependencies:
  # Image handling
  image_picker: ^1.0.0

  # Emoji support
  emoji_picker_flutter: ^2.0.0

  # Optional: Crop images
  image_cropper: ^5.0.0

  # Optional: Compress images
  flutter_image_compress: ^2.0.0
```

---

## ✅ Verification Checklist

After fixes:
- ✅ All color references resolved
- ✅ No import warnings
- ✅ All components compile without errors
- ✅ Dark mode colors properly defined
- ✅ Muted colors added for backgrounds
- ✅ Tertiary text color added for metadata
- ✅ TODOs documented for future work

---

## 🎯 Next Steps for Complete Feature Implementation

### Phase A: Image Handling (Priority: High)
1. Add `image_picker` package
2. Implement camera capture in CreatePostModal
3. Implement gallery picker in CreatePostModal
4. Add image preview in modal
5. Implement image upload to backend

**Estimated Time**: 2-3 hours

### Phase B: Emoji Support (Priority: Medium)
1. Add `emoji_picker_flutter` package
2. Integrate emoji picker in CreatePostModal
3. Add emoji reaction support in PostCard (like Facebook reactions)

**Estimated Time**: 1-2 hours

### Phase C: Post Options (Priority: Medium)
1. Implement 3-dot menu in PostCard
2. Add "Report", "Copy link", "Save post" options
3. Add "Edit post" (if user is author)
4. Add "Delete post" (if user is author)

**Estimated Time**: 2-3 hours

---

## 📚 Resources

- Image Picker: https://pub.dev/packages/image_picker
- Emoji Picker: https://pub.dev/packages/emoji_picker_flutter
- Material Design Bottom Sheets: https://material.io/components/sheets-bottom

---

**All critical bugs fixed! ✅**
**Components are production-ready for use with existing functionality.**
**TODOs are optional enhancements for full feature parity.**

**Last Updated**: 2026-02-22 23:55
