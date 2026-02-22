// Search Service
// Handles global search across users, groups, posts, and foods
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SearchService {
  final _supabase = Supabase.instance.client;

  // Global search - all content types
  Future<GlobalSearchResults> globalSearch({
    required String query,
    SearchType type = SearchType.all,
    int limit = 10,
  }) async {
    try {
      if (query.trim().isEmpty) {
        return GlobalSearchResults.empty();
      }

      // Save to search history
      await _saveSearchHistory(query, type);

      final response = await _supabase.rpc('global_search', params: {
        'search_query': query.trim(),
        'search_type': type.dbValue,
        'result_limit': limit,
      });

      final results = (response as List).map((json) {
        return SearchResult.fromJson(json as Map<String, dynamic>);
      }).toList();

      // Group results by type
      final users = results.where((r) => r.type == 'user').toList();
      final groups = results.where((r) => r.type == 'group').toList();
      final posts = results.where((r) => r.type == 'post').toList();

      return GlobalSearchResults(
        users: users,
        groups: groups,
        posts: posts,
        query: query,
      );
    } catch (e) {
      debugPrint('❌ Error in global search: $e');
      return GlobalSearchResults.empty();
    }
  }

  // Search users only
  Future<List<UserSearchResult>> searchUsers(String query, {int limit = 20}) async {
    try {
      if (query.trim().isEmpty) return [];

      final response = await _supabase.rpc('search_profiles', params: {
        'search_query': query.trim(),
        'result_limit': limit,
      });

      return (response as List)
          .map((json) => UserSearchResult.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ Error searching users: $e');
      return [];
    }
  }

  // Search groups only
  Future<List<GroupSearchResult>> searchGroups(String query, {int limit = 20}) async {
    try {
      if (query.trim().isEmpty) return [];

      final response = await _supabase.rpc('search_groups', params: {
        'search_query': query.trim(),
        'result_limit': limit,
      });

      return (response as List)
          .map((json) => GroupSearchResult.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ Error searching groups: $e');
      return [];
    }
  }

  // Search posts only
  Future<List<PostSearchResult>> searchPosts(String query, {int limit = 20}) async {
    try {
      if (query.trim().isEmpty) return [];

      final response = await _supabase.rpc('search_posts', params: {
        'search_query': query.trim(),
        'result_limit': limit,
      });

      return (response as List)
          .map((json) => PostSearchResult.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ Error searching posts: $e');
      return [];
    }
  }

  // Get recent searches for current user
  Future<List<String>> getRecentSearches({int limit = 10}) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return [];

      final response = await _supabase
          .from('search_history')
          .select('search_query')
          .eq('user_id', currentUserId)
          .order('created_at', ascending: false)
          .limit(limit);

      final queries = <String>{};
      for (final row in response) {
        queries.add(row['search_query'] as String);
      }
      return queries.toList();
    } catch (e) {
      debugPrint('❌ Error getting recent searches: $e');
      return [];
    }
  }

  // Get trending searches
  Future<List<TrendingSearch>> getTrendingSearches({int limit = 10}) async {
    try {
      final response = await _supabase.rpc('get_trending_searches', params: {
        'result_limit': limit,
      });

      return (response as List)
          .map((json) => TrendingSearch.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting trending searches: $e');
      return [];
    }
  }

  // Clear search history
  Future<void> clearSearchHistory() async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return;

      await _supabase
          .from('search_history')
          .delete()
          .eq('user_id', currentUserId);

      debugPrint('✅ Search history cleared');
    } catch (e) {
      debugPrint('❌ Error clearing search history: $e');
    }
  }

  // Track search result click (for analytics)
  Future<void> trackSearchClick({
    required String query,
    required String resultId,
    required String resultType,
  }) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return;

      // Find the most recent search history entry for this query
      final recent = await _supabase
          .from('search_history')
          .select('id')
          .eq('user_id', currentUserId)
          .eq('search_query', query)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (recent != null) {
        await _supabase.from('search_history').update({
          'clicked_result_id': resultId,
          'clicked_result_type': resultType,
        }).eq('id', recent['id']);
      }
    } catch (e) {
      debugPrint('❌ Error tracking search click: $e');
    }
  }

  // Private: Save search to history
  Future<void> _saveSearchHistory(String query, SearchType type) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return;

      await _supabase.from('search_history').insert({
        'user_id': currentUserId,
        'search_query': query.trim(),
        'search_type': type.dbValue,
      });
    } catch (e) {
      // Silently fail - search history is not critical
      debugPrint('⚠️ Could not save search history: $e');
    }
  }
}

// Enums
enum SearchType {
  all,
  users,
  groups,
  posts;

  String get dbValue => name;

  String get label {
    switch (this) {
      case SearchType.all:
        return 'Tất cả';
      case SearchType.users:
        return 'Người dùng';
      case SearchType.groups:
        return 'Nhóm';
      case SearchType.posts:
        return 'Bài viết';
    }
  }
}

// Models
class GlobalSearchResults {
  final List<SearchResult> users;
  final List<SearchResult> groups;
  final List<SearchResult> posts;
  final String query;

  const GlobalSearchResults({
    required this.users,
    required this.groups,
    required this.posts,
    required this.query,
  });

  factory GlobalSearchResults.empty() {
    return const GlobalSearchResults(
      users: [],
      groups: [],
      posts: [],
      query: '',
    );
  }

  bool get isEmpty => users.isEmpty && groups.isEmpty && posts.isEmpty;
  bool get isNotEmpty => !isEmpty;

  int get totalCount => users.length + groups.length + posts.length;
}

class SearchResult {
  final String type; // 'user', 'group', 'post'
  final String id;
  final String title;
  final String subtitle;
  final String? imageUrl;
  final double rank;

  const SearchResult({
    required this.type,
    required this.id,
    required this.title,
    required this.subtitle,
    this.imageUrl,
    required this.rank,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      type: json['result_type'] as String,
      id: json['result_id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      imageUrl: json['image_url'] as String?,
      rank: (json['rank'] as num).toDouble(),
    );
  }
}

class UserSearchResult {
  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final String? bio;
  final double rank;

  const UserSearchResult({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    this.bio,
    required this.rank,
  });

  factory UserSearchResult.fromJson(Map<String, dynamic> json) {
    return UserSearchResult(
      id: json['id'] as String,
      username: json['username'] as String,
      displayName: json['display_name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      rank: (json['rank'] as num).toDouble(),
    );
  }
}

class GroupSearchResult {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? coverImageUrl;
  final String? category;
  final int memberCount;
  final double rank;

  const GroupSearchResult({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.coverImageUrl,
    this.category,
    required this.memberCount,
    required this.rank,
  });

  factory GroupSearchResult.fromJson(Map<String, dynamic> json) {
    return GroupSearchResult(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      category: json['category'] as String?,
      memberCount: json['member_count'] as int,
      rank: (json['rank'] as num).toDouble(),
    );
  }
}

class PostSearchResult {
  final String id;
  final String userId;
  final String content;
  final List<String> imageUrls;
  final int likeCount;
  final int commentCount;
  final DateTime createdAt;
  final String? authorUsername;
  final String? authorDisplayName;
  final String? authorAvatarUrl;
  final double rank;

  const PostSearchResult({
    required this.id,
    required this.userId,
    required this.content,
    required this.imageUrls,
    required this.likeCount,
    required this.commentCount,
    required this.createdAt,
    this.authorUsername,
    this.authorDisplayName,
    this.authorAvatarUrl,
    required this.rank,
  });

  factory PostSearchResult.fromJson(Map<String, dynamic> json) {
    return PostSearchResult(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String,
      imageUrls: (json['image_urls'] as List?)?.cast<String>() ?? [],
      likeCount: json['like_count'] as int? ?? 0,
      commentCount: json['comment_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      authorUsername: json['author_username'] as String?,
      authorDisplayName: json['author_display_name'] as String?,
      authorAvatarUrl: json['author_avatar_url'] as String?,
      rank: (json['rank'] as num).toDouble(),
    );
  }
}

class TrendingSearch {
  final String query;
  final int searchCount;

  const TrendingSearch({
    required this.query,
    required this.searchCount,
  });

  factory TrendingSearch.fromJson(Map<String, dynamic> json) {
    return TrendingSearch(
      query: json['search_query'] as String,
      searchCount: json['search_count'] as int,
    );
  }
}
