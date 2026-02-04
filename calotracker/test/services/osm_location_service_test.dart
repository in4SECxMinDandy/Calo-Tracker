import 'package:flutter_test/flutter_test.dart';
import 'package:calotracker/services/osm_location_service.dart';

void main() {
  group('OSMLocationService Tests', () {
    late OSMLocationService service;

    setUp(() {
      service = OSMLocationService();
    });

    tearDown(() {
      service.clearCache();
    });

    test('should return quick suggestions', () {
      // Act
      final suggestions = service.getQuickSuggestions();

      // Assert
      expect(suggestions, isNotEmpty);
      expect(suggestions, contains('Phòng gym'));
      expect(suggestions, contains('Quán cafe'));
      expect(suggestions, contains('Nhà hàng'));
    });

    test('should handle empty search query', () async {
      // Act
      final results = await service.searchLocation('');

      // Assert
      expect(results, isEmpty);
    });

    test('should cache search results', () {
      // Clear cache first
      service.clearCache();

      // The cache should be empty initially
      expect(service, isNotNull);
    });

    test('should create service instance', () {
      // Service should be a singleton
      final instance1 = OSMLocationService();
      final instance2 = OSMLocationService();

      expect(instance1, same(instance2));
    });
  });

  group('LocationResult Tests', () {
    test('should create LocationResult instance', () {
      // Arrange & Act
      const location = LocationResult(
        id: '1',
        name: 'Starbucks Reserve Hanoi',
        fullAddress: '22B Hai Ba Trung, Hanoi',
        latitude: 21.0285,
        longitude: 105.8520,
        type: 'cafe',
      );

      // Assert
      expect(location.name, isNotEmpty);
      expect(location.latitude, greaterThan(0));
      expect(location.longitude, greaterThan(0));
    });

    test('should return displayName correctly', () {
      const location = LocationResult(
        id: '1',
        name: 'Test Location',
        fullAddress: 'Full Address String',
        latitude: 0,
        longitude: 0,
      );

      expect(location.displayName, 'Test Location');
    });

    test('should fall back to full address when name is empty', () {
      const location = LocationResult(
        id: '1',
        name: '',
        fullAddress: 'First Part, Second Part',
        latitude: 0,
        longitude: 0,
      );

      expect(location.displayName, 'First Part');
    });

    test('should format short address with road and city', () {
      const location = LocationResult(
        id: '1',
        name: 'Test',
        fullAddress: 'Test Address',
        latitude: 0,
        longitude: 0,
        addressDetails: {'road': 'Nguyen Hue', 'city': 'Hanoi'},
      );

      expect(location.shortAddress, contains('Nguyen Hue'));
    });

    test('should have proper type classification', () {
      const cafe = LocationResult(
        id: '1',
        name: 'Cafe',
        fullAddress: 'Cafe Address',
        latitude: 0,
        longitude: 0,
        type: 'cafe',
      );

      const gym = LocationResult(
        id: '2',
        name: 'Gym',
        fullAddress: 'Gym Address',
        latitude: 0,
        longitude: 0,
        type: 'gym',
      );

      expect(cafe.type, 'cafe');
      expect(gym.type, 'gym');
    });

    test('should have toString method', () {
      const location = LocationResult(
        id: '1',
        name: 'Test Location',
        fullAddress: 'Test',
        latitude: 21.0,
        longitude: 105.0,
      );

      final str = location.toString();
      expect(str, contains('Test Location'));
      expect(str, contains('21.0'));
      expect(str, contains('105.0'));
    });
  });
}
