// Global Search Screen
// Search across users, groups, posts
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/search_service.dart';
import '../../theme/colors.dart';
import '../community/user_profile_screen.dart';
import '../community/group_detail_screen.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen>
    with SingleTickerProviderStateMixin {
  final _searchService = SearchService();
  final _searchController = TextEditingController();

  late TabController _tabController;
  Timer? _debounce;

  SearchType _currentType = SearchType.all;
  GlobalSearchResults? _searchResults;
  List<String> _recentSearches = [];
  List<TrendingSearch> _trendingSearches = [];

  bool _isSearching = false;
  bool _isLoadingRecent = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _currentType = SearchType.values[_tabController.index];
        });
        if (_searchController.text.trim().isNotEmpty) {
          _performSearch(_searchController.text.trim());
        }
      }
    });
    _loadRecentAndTrending();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadRecentAndTrending() async {
    setState(() => _isLoadingRecent = true);

    try {
      final recent = await _searchService.getRecentSearches();
      final trending = await _searchService.getTrendingSearches();

      if (mounted) {
        setState(() {
          _recentSearches = recent;
          _trendingSearches = trending;
          _isLoadingRecent = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingRecent = false);
      }
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    setState(() => _isSearching = true);

    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.trim().isNotEmpty) {
        _performSearch(query.trim());
      } else {
        setState(() {
          _searchResults = null;
          _isSearching = false;
        });
      }
    });
  }

  Future<void> _performSearch(String query) async {
    try {
      final results = await _searchService.globalSearch(
        query: query,
        type: _currentType,
        limit: 20,
      );

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Search error: $e');
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  void _onRecentSearchTap(String query) {
    _searchController.text = query;
    _performSearch(query);
  }

  Future<void> _clearSearchHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Xóa lịch sử tìm kiếm'),
            content: const Text(
              'Bạn có chắc muốn xóa toàn bộ lịch sử tìm kiếm?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Xóa'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await _searchService.clearSearchHistory();
      setState(() => _recentSearches = []);
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
        title: TextField(
          controller: _searchController,
          autofocus: true,
          onChanged: _onSearchChanged,
          style: TextStyle(
            color: isDark ? AppColors.darkText : AppColors.lightText,
          ),
          decoration: InputDecoration(
            hintText: 'Tìm kiếm người dùng, nhóm, bài viết...',
            hintStyle: TextStyle(
              color:
                  isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
            ),
            border: InputBorder.none,
            suffixIcon:
                _searchController.text.isNotEmpty
                    ? IconButton(
                      icon: const Icon(CupertinoIcons.clear_circled_solid),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchResults = null);
                      },
                    )
                    : null,
          ),
        ),
        bottom:
            _searchResults != null
                ? TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primaryBlue,
                  unselectedLabelColor:
                      isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                  indicatorColor: AppColors.primaryBlue,
                  tabs: [
                    Tab(text: 'Tất cả (${_searchResults!.totalCount})'),
                    Tab(text: 'Người dùng (${_searchResults!.users.length})'),
                    Tab(text: 'Nhóm (${_searchResults!.groups.length})'),
                    Tab(text: 'Bài viết (${_searchResults!.posts.length})'),
                  ],
                )
                : null,
      ),
      body:
          _isSearching
              ? const Center(child: CircularProgressIndicator())
              : _searchResults == null
              ? _buildRecentAndTrending(isDark)
              : _buildSearchResults(isDark),
    );
  }

  Widget _buildRecentAndTrending(bool isDark) {
    if (_isLoadingRecent) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent searches
          if (_recentSearches.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tìm kiếm gần đây',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
                TextButton(
                  onPressed: _clearSearchHistory,
                  child: const Text('Xóa tất cả'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._recentSearches.map((query) {
              return ListTile(
                leading: Icon(
                  CupertinoIcons.clock,
                  color:
                      isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                ),
                title: Text(query),
                onTap: () => _onRecentSearchTap(query),
                trailing: IconButton(
                  icon: const Icon(CupertinoIcons.xmark),
                  onPressed: () {
                    setState(() {
                      _recentSearches.remove(query);
                    });
                  },
                ),
              );
            }),
            const SizedBox(height: 24),
          ],

          // Trending searches
          if (_trendingSearches.isNotEmpty) ...[
            Text(
              'Xu hướng tìm kiếm',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
            ),
            const SizedBox(height: 8),
            ..._trendingSearches.map((trending) {
              return ListTile(
                leading: const Icon(
                  CupertinoIcons.chart_bar,
                  color: AppColors.primaryBlue,
                ),
                title: Text(trending.query),
                subtitle: Text('${trending.searchCount} lượt tìm'),
                onTap: () => _onRecentSearchTap(trending.query),
              );
            }),
          ],

          // Empty state
          if (_recentSearches.isEmpty && _trendingSearches.isEmpty) ...[
            const SizedBox(height: 100),
            Center(
              child: Column(
                children: [
                  Icon(
                    CupertinoIcons.search,
                    size: 64,
                    color:
                        isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tìm kiếm người dùng, nhóm, bài viết',
                    style: TextStyle(
                      fontSize: 16,
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
        ],
      ),
    );
  }

  Widget _buildSearchResults(bool isDark) {
    if (_searchResults!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.search,
              size: 64,
              color:
                  isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Không tìm thấy kết quả',
              style: TextStyle(
                fontSize: 16,
                color:
                    isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildAllResults(isDark),
        _buildUserResults(isDark),
        _buildGroupResults(isDark),
        _buildPostResults(isDark),
      ],
    );
  }

  Widget _buildAllResults(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_searchResults!.users.isNotEmpty) ...[
          _buildSectionHeader('Người dùng', isDark),
          ..._searchResults!.users.take(3).map((result) {
            return _buildResultCard(result, isDark);
          }),
        ],
        if (_searchResults!.groups.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildSectionHeader('Nhóm', isDark),
          ..._searchResults!.groups.take(3).map((result) {
            return _buildResultCard(result, isDark);
          }),
        ],
        if (_searchResults!.posts.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildSectionHeader('Bài viết', isDark),
          ..._searchResults!.posts.take(3).map((result) {
            return _buildResultCard(result, isDark);
          }),
        ],
      ],
    );
  }

  Widget _buildUserResults(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults!.users.length,
      itemBuilder: (context, index) {
        return _buildResultCard(_searchResults!.users[index], isDark);
      },
    );
  }

  Widget _buildGroupResults(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults!.groups.length,
      itemBuilder: (context, index) {
        return _buildResultCard(_searchResults!.groups[index], isDark);
      },
    );
  }

  Widget _buildPostResults(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults!.posts.length,
      itemBuilder: (context, index) {
        return _buildResultCard(_searchResults!.posts[index], isDark);
      },
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.darkText : AppColors.lightText,
        ),
      ),
    );
  }

  Widget _buildResultCard(SearchResult result, bool isDark) {
    return Card(
      color: isDark ? AppColors.darkCard : AppColors.lightCard,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
          backgroundImage:
              result.imageUrl != null
                  ? CachedNetworkImageProvider(result.imageUrl!)
                  : null,
          child:
              result.imageUrl == null
                  ? Icon(
                    result.type == 'user'
                        ? CupertinoIcons.person
                        : result.type == 'group'
                        ? CupertinoIcons.group
                        : CupertinoIcons.doc_text,
                    color: AppColors.primaryBlue,
                  )
                  : null,
        ),
        title: Text(
          result.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          result.subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () {
          // Track click
          _searchService.trackSearchClick(
            query: _searchResults!.query,
            resultId: result.id,
            resultType: result.type,
          );

          // Navigate to detail screen based on type
          switch (result.type) {
            case 'user':
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UserProfileScreen(userId: result.id),
                ),
              );
              break;
            case 'group':
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GroupDetailScreen(groupId: result.id),
                ),
              );
              break;
            case 'post':
              // Quay lại Community Hub và có thể scroll đến bài viết
              Navigator.pop(context, {'type': 'post', 'postId': result.id});
              break;
          }
        },
      ),
    );
  }
}
