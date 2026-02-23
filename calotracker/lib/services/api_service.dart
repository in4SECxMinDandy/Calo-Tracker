// API Service - Central service for all backend API calls
// Handles authentication, error handling, and response formatting
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;

  ApiException(this.message, {this.statusCode, this.code});

  @override
  String toString() =>
      'ApiException: $message (code: $code, status: $statusCode)';
}

class ApiService {
  final SupabaseClient _client;

  ApiService(this._client);

  // Singleton pattern
  static ApiService? _instance;
  static ApiService get instance {
    _instance ??= ApiService(Supabase.instance.client);
    return _instance!;
  }

  // Get current user ID
  String? get currentUserId => _client.auth.currentUser?.id;

  // Generic GET request
  Future<T> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final response = await _client
          .from(endpoint)
          .select()
          .then((data) => data as T);
      return response;
    } catch (e) {
      throw ApiException('GET $endpoint failed: $e');
    }
  }

  // Generic POST request
  Future<T> post<T>(
    String endpoint,
    Map<String, dynamic> data, {
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final response = await _client
          .from(endpoint)
          .insert(data)
          .select()
          .single()
          .then((data) => data as T);
      return response;
    } catch (e) {
      throw ApiException('POST $endpoint failed: $e');
    }
  }

  // Generic PUT request
  Future<T> put<T>(
    String endpoint,
    String id,
    Map<String, dynamic> data, {
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final response = await _client
          .from(endpoint)
          .update(data)
          .eq('id', id)
          .select()
          .single()
          .then((data) => data as T);
      return response;
    } catch (e) {
      throw ApiException('PUT $endpoint/$id failed: $e');
    }
  }

  // Generic DELETE request
  Future<void> delete(String endpoint, String id) async {
    try {
      await _client.from(endpoint).delete().eq('id', id);
    } catch (e) {
      throw ApiException('DELETE $endpoint/$id failed: $e');
    }
  }

  // Call Edge Function
  Future<Map<String, dynamic>> callFunction(
    String functionName, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final response = await _client.functions.invoke(functionName, body: body);

      if (response.status != 200) {
        throw ApiException(
          'Function $functionName failed',
          statusCode: response.status,
        );
      }

      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw ApiException('Function $functionName failed: $e');
    }
  }

  // Upload file to Supabase Storage
  Future<String> uploadFile(String bucket, String path, File file) async {
    try {
      await _client.storage.from(bucket).upload(path, file);
      return _client.storage.from(bucket).getPublicUrl(path);
    } catch (e) {
      throw ApiException('Upload to $bucket/$path failed: $e');
    }
  }

  // Handle errors uniformly
  ApiException handleError(dynamic error) {
    if (error is ApiException) return error;

    if (error is PostgrestException) {
      return ApiException(
        error.message,
        statusCode: int.tryParse(error.code ?? ''),
        code: error.code,
      );
    }

    if (error is AuthException) {
      return ApiException(
        error.message,
        statusCode:
            error.statusCode != null ? int.tryParse(error.statusCode!) : null,
      );
    }

    return ApiException('Unknown error: $error');
  }
}
