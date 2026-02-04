// OpenStreetMap Nominatim Location Service
// Free, accurate geocoding service for location detection
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

/// Location result from OSM
class LocationResult {
  final String id;
  final String name;
  final String fullAddress;
  final double latitude;
  final double longitude;
  final String? type;
  final String? category;
  final Map<String, String?> addressDetails;

  const LocationResult({
    required this.id,
    required this.name,
    required this.fullAddress,
    required this.latitude,
    required this.longitude,
    this.type,
    this.category,
    this.addressDetails = const {},
  });

  /// Format for display in UI
  String get displayName =>
      name.isNotEmpty ? name : fullAddress.split(',').first;

  /// Short address for compact display
  String get shortAddress {
    final parts = <String>[];
    if (addressDetails['road'] != null) parts.add(addressDetails['road']!);
    if (addressDetails['suburb'] != null) parts.add(addressDetails['suburb']!);
    if (addressDetails['city'] != null) parts.add(addressDetails['city']!);
    return parts.take(2).join(', ');
  }

  @override
  String toString() => 'LocationResult($name, $latitude, $longitude)';
}

/// OSM Location Service with caching and rate limiting
class OSMLocationService {
  static OSMLocationService? _instance;

  factory OSMLocationService() {
    _instance ??= OSMLocationService._();
    return _instance!;
  }

  OSMLocationService._();

  // Nominatim API base URL
  static const String _nominatimBaseUrl = 'https://nominatim.openstreetmap.org';

  // Required User-Agent per OSM policy
  static const String _userAgent = 'CaloTracker/1.0 (health-fitness-app)';

  // Cache for search results (1 hour TTL)
  final Map<String, _CacheEntry<List<LocationResult>>> _searchCache = {};
  final Map<String, _CacheEntry<LocationResult>> _reverseCache = {};
  static const Duration _cacheTTL = Duration(hours: 1);

  // Rate limiter: max 1 request per second
  DateTime? _lastRequestTime;
  static const Duration _minRequestInterval = Duration(milliseconds: 1100);

  /// Search for locations by text query
  Future<List<LocationResult>> searchLocation(
    String query, {
    String language = 'vi,en',
    int limit = 5,
    double? nearLat,
    double? nearLon,
  }) async {
    if (query.trim().length < 2) return [];

    final cacheKey = 'search_${query}_$language';

    // Check cache first
    final cached = _getFromCache(_searchCache, cacheKey);
    if (cached != null) {
      debugPrint('OSM: Cache hit for "$query"');
      return cached;
    }

    // Rate limiting
    await _enforceRateLimit();

    try {
      final params = {
        'q': query,
        'format': 'json',
        'addressdetails': '1',
        'limit': limit.toString(),
        'accept-language': language,
      };

      // Add location bias if provided
      if (nearLat != null && nearLon != null) {
        // Bias search towards user's location
        final delta = 0.5; // ~50km radius
        params['viewbox'] =
            '${nearLon - delta},${nearLat + delta},${nearLon + delta},${nearLat - delta}';
        params['bounded'] =
            '0'; // Allow results outside viewbox but prefer inside
      }

      final uri = Uri.parse(
        '$_nominatimBaseUrl/search',
      ).replace(queryParameters: params);

      final response = await http.get(uri, headers: {'User-Agent': _userAgent});

      if (response.statusCode != 200) {
        debugPrint('OSM Search failed: ${response.statusCode}');
        return [];
      }

      final List<dynamic> data = json.decode(response.body);
      final results = data.map((item) => _parseSearchResult(item)).toList();

      // Cache results
      _addToCache(_searchCache, cacheKey, results);

      debugPrint('OSM: Found ${results.length} results for "$query"');
      return results;
    } catch (e) {
      debugPrint('OSM Search error: $e');
      return [];
    }
  }

  /// Reverse geocode: get address from coordinates
  Future<LocationResult?> reverseGeocode(
    double latitude,
    double longitude, {
    String language = 'vi,en',
  }) async {
    final cacheKey =
        'reverse_${latitude.toStringAsFixed(4)}_${longitude.toStringAsFixed(4)}';

    // Check cache
    final cached = _getFromCache(_reverseCache, cacheKey);
    if (cached != null) {
      debugPrint('OSM: Cache hit for reverse geocode');
      return cached;
    }

    // Rate limiting
    await _enforceRateLimit();

    try {
      final params = {
        'lat': latitude.toString(),
        'lon': longitude.toString(),
        'format': 'json',
        'addressdetails': '1',
        'accept-language': language,
      };

      final uri = Uri.parse(
        '$_nominatimBaseUrl/reverse',
      ).replace(queryParameters: params);

      final response = await http.get(uri, headers: {'User-Agent': _userAgent});

      if (response.statusCode != 200) {
        debugPrint('OSM Reverse geocode failed: ${response.statusCode}');
        return null;
      }

      final data = json.decode(response.body);

      if (data['error'] != null) {
        debugPrint('OSM Reverse geocode error: ${data['error']}');
        return null;
      }

      final result = _parseReverseResult(data);

      // Cache result
      _addToCache(_reverseCache, cacheKey, result);

      return result;
    } catch (e) {
      debugPrint('OSM Reverse geocode error: $e');
      return null;
    }
  }

  /// Get current GPS location and reverse geocode it
  Future<LocationResult?> getCurrentLocation() async {
    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permission denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permission permanently denied');
        return null;
      }

      // Check if location service is enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services disabled');
        return null;
      }

      // Get current position using LocationSettings
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      debugPrint('GPS: ${position.latitude}, ${position.longitude}');

      // Reverse geocode to get address
      return await reverseGeocode(position.latitude, position.longitude);
    } catch (e) {
      debugPrint('Get current location error: $e');
      return null;
    }
  }

  /// Quick suggestions for common places (no API call)
  List<String> getQuickSuggestions() {
    return [
      'Phòng gym',
      'Nhà',
      'Công viên',
      'Quán cafe',
      'Văn phòng',
      'Trường học',
      'Bệnh viện',
      'Siêu thị',
    ];
  }

  // ============================================
  // PRIVATE HELPERS
  // ============================================

  LocationResult _parseSearchResult(Map<String, dynamic> item) {
    final address = item['address'] as Map<String, dynamic>? ?? {};

    // Get best name for the place
    String name = item['name'] as String? ?? '';
    if (name.isEmpty) {
      name =
          address['amenity'] as String? ??
          address['shop'] as String? ??
          address['building'] as String? ??
          address['road'] as String? ??
          'Địa điểm';
    }

    return LocationResult(
      id: item['place_id'].toString(),
      name: name,
      fullAddress: item['display_name'] as String? ?? '',
      latitude: double.tryParse(item['lat'].toString()) ?? 0,
      longitude: double.tryParse(item['lon'].toString()) ?? 0,
      type: item['type'] as String?,
      category: item['category'] as String?,
      addressDetails: {
        'houseNumber': address['house_number'] as String?,
        'road': address['road'] as String?,
        'suburb': address['suburb'] as String?,
        'city':
            (address['city'] ?? address['town'] ?? address['village'])
                as String?,
        'state': address['state'] as String?,
        'country': address['country'] as String?,
        'postcode': address['postcode'] as String?,
      },
    );
  }

  LocationResult _parseReverseResult(Map<String, dynamic> data) {
    final address = data['address'] as Map<String, dynamic>? ?? {};

    // Get best name for the place
    String name =
        address['amenity'] as String? ??
        address['shop'] as String? ??
        address['building'] as String? ??
        address['road'] as String? ??
        'Vị trí hiện tại';

    return LocationResult(
      id: data['place_id'].toString(),
      name: name,
      fullAddress: data['display_name'] as String? ?? '',
      latitude: double.tryParse(data['lat'].toString()) ?? 0,
      longitude: double.tryParse(data['lon'].toString()) ?? 0,
      type: data['type'] as String?,
      category: data['category'] as String?,
      addressDetails: {
        'houseNumber': address['house_number'] as String?,
        'road': address['road'] as String?,
        'suburb': address['suburb'] as String?,
        'city':
            (address['city'] ?? address['town'] ?? address['village'])
                as String?,
        'state': address['state'] as String?,
        'country': address['country'] as String?,
        'postcode': address['postcode'] as String?,
      },
    );
  }

  /// Enforce rate limit (max 1 request per second)
  Future<void> _enforceRateLimit() async {
    if (_lastRequestTime != null) {
      final elapsed = DateTime.now().difference(_lastRequestTime!);
      if (elapsed < _minRequestInterval) {
        final waitTime = _minRequestInterval - elapsed;
        debugPrint('OSM: Rate limiting, waiting ${waitTime.inMilliseconds}ms');
        await Future.delayed(waitTime);
      }
    }
    _lastRequestTime = DateTime.now();
  }

  /// Get from cache if not expired
  T? _getFromCache<T>(Map<String, _CacheEntry<T>> cache, String key) {
    final entry = cache[key];
    if (entry == null) return null;

    if (DateTime.now().difference(entry.timestamp) > _cacheTTL) {
      cache.remove(key);
      return null;
    }

    return entry.data;
  }

  /// Add to cache
  void _addToCache<T>(Map<String, _CacheEntry<T>> cache, String key, T data) {
    cache[key] = _CacheEntry(data: data, timestamp: DateTime.now());

    // Clean old entries if cache too large
    if (cache.length > 100) {
      final oldKeys =
          cache.entries
              .where(
                (e) => DateTime.now().difference(e.value.timestamp) > _cacheTTL,
              )
              .map((e) => e.key)
              .toList();
      for (final key in oldKeys) {
        cache.remove(key);
      }
    }
  }

  /// Clear all caches
  void clearCache() {
    _searchCache.clear();
    _reverseCache.clear();
    debugPrint('OSM: Cache cleared');
  }
}

/// Cache entry with timestamp
class _CacheEntry<T> {
  final T data;
  final DateTime timestamp;

  _CacheEntry({required this.data, required this.timestamp});
}
