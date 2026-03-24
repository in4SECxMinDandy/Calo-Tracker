---
description: Specialized skill for nutrition analysis, food recognition, and meal planning with AI assistance
---

# Nutrition & Food Analysis Skill

## Overview

This skill provides specialized knowledge for nutrition analysis, food recognition, and meal planning in the Calo-Tracker application.

## Capabilities

### Food Recognition
- Analyze food images for calorie estimation
- Identify food items from descriptions
- Handle ambiguous food inputs
- Confidence scoring for predictions

### Nutrition Analysis
- Calculate macronutrients (protein, carbs, fat)
- Estimate micronutrients
- Handle serving sizes
- Consider cooking methods

### Meal Planning
- Generate balanced meal suggestions
- Optimize for calorie targets
- Respect dietary preferences
- Consider nutritional goals

## Implementation Patterns

### Food Recognition Pipeline
```dart
class FoodRecognitionPipeline {
  Future<FoodResult> recognize(String input) async {
    // 1. Preprocess input
    final processed = await _preprocessor.process(input);
    
    // 2. AI analysis
    final analysis = await _aiService.analyze(processed);
    
    // 3. Validate results
    return _validator.validate(analysis);
  }
}
```

### Nutrition Calculation
```dart
class NutritionCalculator {
  NutritionFacts calculate(String food, double servings) {
    final baseNutrition = _database.lookup(food);
    return baseNutrition.scale(servings);
  }
}
```

### Meal Suggestions
```dart
class MealSuggester {
  Future<List<Meal>> suggest({
    required double targetCalories,
    required List<String> preferences,
  }) async {
    final prompt = _buildPrompt(targetCalories, preferences);
    final response = await _aiService.generate(prompt);
    return _parser.parse(response);
  }
}
```

## Best Practices

1. **Always validate AI outputs** before using for calculations
2. **Cache common foods** for faster lookup
3. **Provide confidence intervals** for estimates
4. **Allow user corrections** to improve future accuracy
5. **Log ambiguous cases** for manual review

## Data Sources

- USDA FoodData Central
- Custom food database
- AI-generated estimates (with disclaimer)

## Quality Guidelines

- Accuracy over speed
- Clear uncertainty communication
- User privacy protection
- Dietary restriction awareness
