// Saved Posts Screen
// Display user's saved posts
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../services/community_service.dart';
import '../../models/post.dart';
import '../../theme/colors.dart';
import 'widgets/post_card.dart';

class SavedPostsScreen extends StatefulWidget {
  const SavedPostsScreen({super.key});

  @override
  State<SavedPostsScreen> createState() => _SavedPostsScreenState();
}

class _SavedPostsScreenState extends State<SavedPostsScreen> {
  final _communityService = CommunityService();

  List<Post> _savedPosts = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadSavedPosts();
  }

  Future<void> _loadSavedPosts() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final posts = await _communityService.getSavedPosts();

      if (mounted) {
        setState(() {
          _savedPosts = posts;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading saved posts: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  Future<void> _unsavePost(String postId) async {
    try {
      await _communityService.unsavePost(postId);

      if (mounted) {
        setState(() {
          _savedPosts.removeWhere((post) => post.id == postId);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã bỏ lưu bài viết'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error unsaving post: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể bỏ lưu bài viết'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            CupertinoIcons.back,
            color: isDark ? AppColors.darkText : AppColors.lightText,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Bài viết đã lưu',
          style: TextStyle(
            color: isDark ? AppColors.darkText : AppColors.lightText,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        CupertinoIcons.exclamationmark_triangle,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text('Không thể tải bài viết đã lưu'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadSavedPosts,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : _savedPosts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.bookmark,
                            size: 64,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Chưa có bài viết đã lưu',
                            style: TextStyle(
                              fontSize: 16,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Nhấn vào biểu tượng bookmark để lưu bài viết',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadSavedPosts,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(top: 8, bottom: 80),
                        itemCount: _savedPosts.length,
                        itemBuilder: (context, index) {
                          final post = _savedPosts[index];
                          return PostCard(
                            post: post,
                            onUnsave: () => _unsavePost(post.id),
                            isSaved: true,
                          );
                        },
                      ),
                    ),
    );
  }
}
