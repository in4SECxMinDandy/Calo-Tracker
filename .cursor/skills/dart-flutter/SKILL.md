---
description: Flutter/Dart development patterns and best practices for mobile applications
---

# Flutter Development Skill

## Overview

This skill provides specialized knowledge for Flutter/Dart mobile development, architecture, and best practices for Calo-Tracker.

## Capabilities

### Architecture
- Clean Architecture implementation
- Layer separation (UI/Domain/Data)
- Repository pattern
- Dependency injection

### State Management
- Riverpod provider setup
- AsyncValue handling
- Computed providers
- State notifiers

### UI Development
- Widget composition
- Custom widget patterns
- Responsive design
- Animation patterns

### Performance
- Const constructors
- Selective rebuilds
- Lazy loading
- Memory optimization

## Implementation Patterns

### Riverpod Provider
```dart
@riverpod
class MealNotifier extends _$MealNotifier {
  @override
  Future<List<Meal>> build() async {
    return repository.getMeals();
  }
  
  Future<void> addMeal(Meal meal) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => repository.addMeal(meal));
  }
}
```

### Error Handling
```dart
class MealWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meals = ref.watch(mealsProvider);
    
    return meals.when(
      data: (data) => MealList(meals: data),
      loading: () => const CircularProgressIndicator(),
      error: (e, _) => ErrorView(error: e),
    );
  }
}
```

### Secure Storage
```dart
class SecureService {
  Future<void> store(String key, String value) async {
    await FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    ).write(key: key, value: value);
  }
}
```

## Best Practices

1. **Use const constructors** everywhere possible
2. **Select specific data** in providers to minimize rebuilds
3. **Handle all states** - loading, error, empty, data
4. **Follow naming conventions** - files lowercase with underscores
5. **Keep widgets small** - single responsibility principle
6. **Test providers** not widgets directly

## File Structure
```
lib/
├── core/
│   ├── constants/
│   ├── theme/
│   └── utils/
├── data/
│   ├── models/
│   ├── repositories/
│   └── services/
├── domain/
│   ├── entities/
│   └── repositories/
├── presentation/
│   ├── screens/
│   ├── widgets/
│   └── providers/
└── main.dart
```

## Platform Channels

When integrating native code:
```dart
class HealthKitService {
  static const _channel = MethodChannel('com.calotracker/healthkit');
  
  Future<List<HealthData>> getData(DateTime start, DateTime end) async {
    final result = await _channel.invokeMethod('getHealthData', {
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
    });
    return (result as List).map((e) => HealthData.fromJson(e)).toList();
  }
}
```

## Testing

```dart
@GenerateMocks([MealRepository])
void main() {
  test('addMeal should call repository', () async {
    when(mock.addMeal(any)).thenAnswer((_) async {});
    
    final notifier = MealNotifier(repository: mock);
    await notifier.addMeal(TestFixtures.meal);
    
    verify(mock.addMeal(any)).called(1);
  });
}
```
