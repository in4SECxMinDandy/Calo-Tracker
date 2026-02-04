// Create Post Sheet
// Bottom sheet for creating new posts
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/community_service.dart';
import '../../../services/supabase_auth_service.dart';
import '../../../services/osm_location_service.dart';
import '../../../models/post.dart';
import '../../../theme/colors.dart';
import '../../../theme/text_styles.dart';
import '../../../core/config/supabase_config.dart';
import '../../../models/community_profile.dart';

class CreatePostSheet extends StatefulWidget {
  final Function(Post) onPostCreated;
  final String? groupId;
  final String? challengeId;

  const CreatePostSheet({
    super.key,
    required this.onPostCreated,
    this.groupId,
    this.challengeId,
  });

  @override
  State<CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<CreatePostSheet> {
  final _contentController = TextEditingController();
  final _communityService = CommunityService();
  final _authService = SupabaseAuthService();
  final _imagePicker = ImagePicker();

  List<File> _selectedImages = [];
  PostType _postType = PostType.general;
  PostVisibility _visibility = PostVisibility.public;
  bool _isLoading = false;
  Map<String, dynamic>? _linkedData;
  String? _locationName;
  List<CommunityProfile> _taggedUsers = [];

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final images = await _imagePicker.pickMultiImage(
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (images.isNotEmpty) {
      setState(() {
        _selectedImages = images.map((i) => File(i.path)).toList();
        if (_selectedImages.length > 4) {
          _selectedImages = _selectedImages.sublist(0, 4);
        }
      });
    }
  }

  Future<void> _takePhoto() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _selectedImages.add(File(image.path));
        if (_selectedImages.length > 4) {
          _selectedImages = _selectedImages.sublist(0, 4);
        }
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  // Build linked data with location and tags
  Map<String, dynamic>? _buildLinkedData() {
    final data = <String, dynamic>{};

    if (_linkedData != null) {
      data.addAll(_linkedData!);
    }

    if (_locationName != null) {
      data['location'] = _locationName;
    }

    if (_taggedUsers.isNotEmpty) {
      data['tagged_users'] =
          _taggedUsers
              .map(
                (u) => {
                  'id': u.id,
                  'username': u.username,
                  'display_name': u.displayName,
                },
              )
              .toList();
    }

    return data.isEmpty ? null : data;
  }

  // Add location dialog with OpenStreetMap Nominatim
  Future<void> _addLocation() async {
    final locationController = TextEditingController(text: _locationName);
    final osmService = OSMLocationService();
    bool isLoading = false;
    bool isSearching = false;
    List<LocationResult> searchResults = [];
    LocationResult? selectedLocation;
    Timer? debounceTimer;

    final result = await showDialog<String>(
      context: context,
      builder:
          (dialogContext) => StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              // Debounced search function
              void performSearch(String query) {
                debounceTimer?.cancel();
                if (query.trim().length < 2) {
                  setDialogState(() => searchResults = []);
                  return;
                }
                debounceTimer = Timer(
                  const Duration(milliseconds: 500),
                  () async {
                    setDialogState(() => isSearching = true);
                    final results = await osmService.searchLocation(query);
                    if (dialogContext.mounted) {
                      setDialogState(() {
                        searchResults = results;
                        isSearching = false;
                      });
                    }
                  },
                );
              }

              return AlertDialog(
                title: const Text('Thêm vị trí'),
                content: SizedBox(
                  width: double.maxFinite,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // GPS Auto-detect button
                        ElevatedButton.icon(
                          onPressed:
                              isLoading
                                  ? null
                                  : () async {
                                    setDialogState(() => isLoading = true);
                                    final location =
                                        await osmService.getCurrentLocation();
                                    if (dialogContext.mounted) {
                                      if (location != null) {
                                        setDialogState(() {
                                          selectedLocation = location;
                                          locationController.text =
                                              location.displayName;
                                          isLoading = false;
                                        });
                                      } else {
                                        setDialogState(() => isLoading = false);
                                        ScaffoldMessenger.of(
                                          dialogContext,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Không thể lấy vị trí GPS. Kiểm tra quyền truy cập.',
                                            ),
                                            backgroundColor: Colors.orange,
                                          ),
                                        );
                                      }
                                    }
                                  },
                          icon:
                              isLoading
                                  ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                  : const Icon(CupertinoIcons.location_fill),
                          label: Text(
                            isLoading
                                ? 'Đang xác định GPS...'
                                : '📍 Vị trí hiện tại (GPS)',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Search input
                        TextField(
                          controller: locationController,
                          decoration: InputDecoration(
                            hintText:
                                'Tìm địa điểm (quán cafe, nhà hàng, địa chỉ...)',
                            prefixIcon: const Icon(CupertinoIcons.search),
                            suffixIcon:
                                isSearching
                                    ? const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    )
                                    : null,
                            border: const OutlineInputBorder(),
                          ),
                          textCapitalization: TextCapitalization.sentences,
                          onChanged: performSearch,
                        ),

                        // Search results
                        if (searchResults.isNotEmpty)
                          Container(
                            constraints: const BoxConstraints(maxHeight: 150),
                            margin: const EdgeInsets.only(top: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: searchResults.length,
                              itemBuilder: (context, index) {
                                final loc = searchResults[index];
                                return ListTile(
                                  dense: true,
                                  leading: const Icon(
                                    CupertinoIcons.location,
                                    size: 18,
                                  ),
                                  title: Text(
                                    loc.displayName,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    loc.shortAddress,
                                    style: const TextStyle(fontSize: 11),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onTap: () {
                                    setDialogState(() {
                                      selectedLocation = loc;
                                      locationController.text = loc.displayName;
                                      searchResults = [];
                                    });
                                  },
                                );
                              },
                            ),
                          ),

                        const SizedBox(height: 12),
                        const Text(
                          'Gợi ý nhanh:',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),

                        // Quick suggestions
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              osmService
                                  .getQuickSuggestions()
                                  .take(5)
                                  .map(
                                    (loc) => ActionChip(
                                      avatar: const Icon(
                                        CupertinoIcons.location,
                                        size: 14,
                                      ),
                                      label: Text(
                                        loc,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      onPressed: () {
                                        setDialogState(() {
                                          locationController.text = loc;
                                          searchResults = [];
                                        });
                                      },
                                    ),
                                  )
                                  .toList(),
                        ),

                        // Selected location preview
                        if (selectedLocation != null)
                          Container(
                            margin: const EdgeInsets.only(top: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.primaryBlue.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  CupertinoIcons.checkmark_circle_fill,
                                  color: AppColors.primaryBlue,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        selectedLocation!.displayName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      if (selectedLocation!
                                          .shortAddress
                                          .isNotEmpty)
                                        Text(
                                          selectedLocation!.shortAddress,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, ''),
                    child: const Text('Xóa vị trí'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Hủy'),
                  ),
                  ElevatedButton(
                    onPressed:
                        () => Navigator.pop(
                          dialogContext,
                          locationController.text,
                        ),
                    child: const Text('Xác nhận'),
                  ),
                ],
              );
            },
          ),
    );

    if (result != null) {
      setState(() {
        _locationName = result.isEmpty ? null : result;
      });
    }
  }

  // Tag users dialog
  Future<void> _tagUsers() async {
    final followers = await _communityService.getFollowers(
      _authService.currentUser?.id ?? '',
    );
    final following = await _communityService.getFollowing(
      _authService.currentUser?.id ?? '',
    );

    // Extract user info from followers (contains profiles sub-object)
    final allUsers = <String, Map<String, dynamic>>{};

    for (var item in followers) {
      final profile = item['profiles'] as Map<String, dynamic>?;
      final userId = item['follower_id'] as String?;
      if (userId != null && profile != null) {
        allUsers[userId] = {
          'id': userId,
          'username': profile['username'],
          'display_name': profile['display_name'],
          'avatar_url': profile['avatar_url'],
        };
      }
    }

    for (var item in following) {
      final profile = item['profiles'] as Map<String, dynamic>?;
      final userId = item['following_id'] as String?;
      if (userId != null && profile != null) {
        allUsers[userId] = {
          'id': userId,
          'username': profile['username'],
          'display_name': profile['display_name'],
          'avatar_url': profile['avatar_url'],
        };
      }
    }

    if (!mounted) return;

    final selectedIds = _taggedUsers.map((u) => u.id).toSet();

    await showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: const Text('Gắn thẻ người dùng'),
                  content: SizedBox(
                    width: double.maxFinite,
                    height: 300,
                    child:
                        allUsers.isEmpty
                            ? const Center(
                              child: Text('Chưa có bạn bè để gắn thẻ'),
                            )
                            : ListView.builder(
                              itemCount: allUsers.length,
                              itemBuilder: (context, index) {
                                final user = allUsers.values.elementAt(index);
                                final userId = user['id'] as String;
                                final username = user['username'] as String?;
                                final displayName =
                                    user['display_name'] as String?;
                                final isSelected = selectedIds.contains(userId);

                                return CheckboxListTile(
                                  value: isSelected,
                                  title: Text(
                                    displayName ?? username ?? 'User',
                                  ),
                                  subtitle:
                                      username != null
                                          ? Text('@$username')
                                          : null,
                                  secondary: CircleAvatar(
                                    backgroundColor: AppColors.primaryBlue
                                        .withValues(alpha: 0.2),
                                    child: Text(
                                      (displayName ?? username ?? 'U')[0]
                                          .toUpperCase(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryBlue,
                                      ),
                                    ),
                                  ),
                                  onChanged: (value) {
                                    setDialogState(() {
                                      if (value == true) {
                                        selectedIds.add(userId);
                                      } else {
                                        selectedIds.remove(userId);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        setDialogState(() => selectedIds.clear());
                      },
                      child: const Text('Xóa tất cả'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Hủy'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _taggedUsers =
                              allUsers.entries
                                  .where((e) => selectedIds.contains(e.key))
                                  .map(
                                    (e) => CommunityProfile.fromJson(e.value),
                                  )
                                  .toList();
                        });
                        Navigator.pop(context);
                      },
                      child: Text('Xác nhận (${selectedIds.length})'),
                    ),
                  ],
                ),
          ),
    );
  }

  Future<List<String>> _uploadImages() async {
    if (_selectedImages.isEmpty) return [];

    final urls = <String>[];
    final client = SupabaseConfig.client;
    final userId = _authService.currentUser?.id;

    for (int i = 0; i < _selectedImages.length; i++) {
      final file = _selectedImages[i];
      final ext = file.path.split('.').last;
      final fileName =
          '$userId/${DateTime.now().millisecondsSinceEpoch}_$i.$ext';

      await client.storage.from('post-images').upload(fileName, file);
      final url = client.storage.from('post-images').getPublicUrl(fileName);
      urls.add(url);
    }

    return urls;
  }

  Future<void> _createPost() async {
    if (_contentController.text.trim().isEmpty && _selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập nội dung hoặc thêm ảnh'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Upload images first
      final imageUrls = await _uploadImages();

      // Create post
      final post = await _communityService.createPost(
        content: _contentController.text.trim(),
        imageUrls: imageUrls,
        postType: _postType,
        linkedData: _buildLinkedData(),
        visibility: _visibility,
        groupId: widget.groupId,
        challengeId: widget.challengeId,
      );

      widget.onPostCreated(post);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã đăng bài viết!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Hủy'),
                    ),
                    Text('Tạo bài viết', style: AppTextStyles.heading3),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _createPost,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      child:
                          _isLoading
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    Colors.white,
                                  ),
                                ),
                              )
                              : const Text('Đăng'),
                    ),
                  ],
                ),
              ),

              Divider(
                color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Post type selector
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children:
                              PostType.values.map((type) {
                                final isSelected = _postType == type;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    label: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          type.icon,
                                          size: 16,
                                          color:
                                              isSelected
                                                  ? Colors.white
                                                  : type.color,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(type.label),
                                      ],
                                    ),
                                    selected: isSelected,
                                    onSelected:
                                        (_) => setState(() => _postType = type),
                                    selectedColor: type.color,
                                    labelStyle: TextStyle(
                                      color: isSelected ? Colors.white : null,
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Content input
                      TextField(
                        controller: _contentController,
                        maxLines: null,
                        minLines: 5,
                        decoration: InputDecoration(
                          hintText: _getHintText(),
                          border: InputBorder.none,
                          hintStyle: TextStyle(
                            color:
                                isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                          ),
                        ),
                        style: const TextStyle(fontSize: 16),
                      ),

                      // Selected images preview
                      if (_selectedImages.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _selectedImages.length,
                            itemBuilder: (context, index) {
                              return Stack(
                                children: [
                                  Container(
                                    width: 120,
                                    height: 120,
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      image: DecorationImage(
                                        image: FileImage(
                                          _selectedImages[index],
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 12,
                                    child: GestureDetector(
                                      onTap: () => _removeImage(index),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          CupertinoIcons.xmark,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Visibility selector
                      Text(
                        'Ai có thể xem?',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color:
                              isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children:
                            PostVisibility.values.map((v) {
                              final isSelected = _visibility == v;
                              return ChoiceChip(
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(v.icon, size: 16),
                                    const SizedBox(width: 4),
                                    Text(v.label),
                                  ],
                                ),
                                selected: isSelected,
                                onSelected:
                                    (_) => setState(() => _visibility = v),
                              );
                            }).toList(),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom action bar
              Container(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                  top: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  border: Border(
                    top: BorderSide(
                      color:
                          isDark
                              ? AppColors.darkDivider
                              : AppColors.lightDivider,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        CupertinoIcons.photo,
                        color: Colors.green,
                      ),
                      onPressed: _pickImages,
                      tooltip: 'Thêm ảnh',
                    ),
                    IconButton(
                      icon: const Icon(
                        CupertinoIcons.camera,
                        color: Colors.blue,
                      ),
                      onPressed: _takePhoto,
                      tooltip: 'Chụp ảnh',
                    ),
                    IconButton(
                      icon: Icon(
                        CupertinoIcons.location,
                        color:
                            _locationName != null ? Colors.green : Colors.red,
                      ),
                      onPressed: _addLocation,
                      tooltip: _locationName ?? 'Thêm vị trí',
                    ),
                    IconButton(
                      icon: Icon(
                        CupertinoIcons.tag,
                        color:
                            _taggedUsers.isNotEmpty
                                ? Colors.green
                                : Colors.orange,
                      ),
                      onPressed: _tagUsers,
                      tooltip:
                          _taggedUsers.isEmpty
                              ? 'Gắn thẻ'
                              : 'Đã gắn ${_taggedUsers.length} người',
                    ),
                    const Spacer(),
                    Text(
                      '${_selectedImages.length}/4 ảnh',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _getHintText() {
    switch (_postType) {
      case PostType.meal:
        return 'Chia sẻ về bữa ăn của bạn...';
      case PostType.workout:
        return 'Kể về buổi tập hôm nay...';
      case PostType.achievement:
        return 'Chia sẻ thành tựu của bạn...';
      case PostType.milestone:
        return 'Bạn đã đạt được cột mốc gì?';
      case PostType.question:
        return 'Đặt câu hỏi cho cộng đồng...';
      case PostType.challengeProgress:
        return 'Cập nhật tiến độ thử thách...';
      default:
        return 'Bạn đang nghĩ gì?';
    }
  }
}
