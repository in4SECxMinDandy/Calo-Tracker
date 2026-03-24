---
description: AI integration patterns for Gemini, OpenAI, and custom AI service implementations
---

# AI Integration Skill

## Overview

This skill provides patterns for integrating AI services (Gemini, OpenAI, custom) into the Calo-Tracker application with proper error handling, caching, and reliability.

## Capabilities

### AI Service Clients
- Gemini Pro integration
- Custom model support
- Multi-provider fallback
- Connection pooling

### Error Handling
- Retry with exponential backoff
- Rate limiting
- Timeout handling
- Graceful degradation

### Caching
- Response caching
- Semantic caching
- Cache invalidation
- TTL management

## Implementation Patterns

### Base AI Service
```dart
abstract class BaseAIService {
  Future<AIResponse> generate(AIRequest request);
  void dispose();
}

class RetryableAIService implements BaseAIService {
  final BaseAIService _delegate;
  final int maxRetries;
  final Duration initialDelay;
  
  @override
  Future<AIResponse> generate(AIRequest request) async {
    int attempts = 0;
    Duration delay = initialDelay;
    
    while (true) {
      try {
        return await _delegate.generate(request);
      } on AIServiceException catch (e) {
        attempts++;
        if (!e.retriable || attempts >= maxRetries) rethrow;
        await Future.delayed(delay);
        delay *= 2;
      }
    }
  }
}
```

### Cache Layer
```dart
class AICache {
  final Map<String, CacheEntry> _cache = {};
  
  Future<AIResponse?> get(String key) async {
    final entry = _cache[key];
    if (entry == null || entry.isExpired) return null;
    return entry.response;
  }
  
  Future<void> set(String key, AIResponse response, Duration ttl) async {
    _cache[key] = CacheEntry(
      response: response,
      expiresAt: DateTime.now().add(ttl),
    );
  }
}
```

### Rate Limiter
```dart
class RateLimiter {
  final int maxRequests;
  final Duration window;
  final List<DateTime> _requests = [];
  
  Future<void> acquire() async {
    _cleanupOldRequests();
    if (_requests.length >= maxRequests) {
      await Future.delayed(_requests.first.add(window).difference(DateTime.now()));
      return acquire();
    }
    _requests.add(DateTime.now());
  }
}
```

## Error Codes
```dart
enum AIErrorCode {
  networkError,
  timeout,
  invalidResponse,
  rateLimit,
  authenticationError,
  serverError,
  modelNotFound,
}
```

## Best Practices

1. **Always implement retry** with exponential backoff
2. **Cache responses** for identical requests
3. **Rate limit requests** to avoid quota exhaustion
4. **Handle all error codes** explicitly
5. **Log for debugging** without exposing sensitive data
6. **Provide fallbacks** when AI is unavailable

## Security

- Never log API keys
- Use environment variables
- Implement request signing
- Validate all inputs
- Sanitize all outputs

## Monitoring

Track:
- Request latency
- Error rates by type
- Cache hit rate
- Rate limit hits
- Token usage
