import 'package:flutter/foundation.dart';

@immutable
class Recipe {
  const Recipe({
    required this.id,
    required this.title,
    required this.cuisine,
    required this.difficulty,
    required this.prepMinutes,
    required this.cookMinutes,
    required this.servingsBase,
    required this.calories,
    required this.likes,
    required this.comments,
    required this.chef,
    required this.reelSeconds,
    required this.tags,
    required this.ingredients,
    required this.steps,
    this.heroImageUrl,
    this.isSaved = false,
  });

  final String id;
  final String title;
  final String cuisine;
  final String difficulty;
  final int prepMinutes;
  final int cookMinutes;
  final int servingsBase;
  final int calories;
  final String likes;
  final int comments;
  final String chef;
  final int reelSeconds;
  final List<String> tags;
  final List<String> ingredients;
  final List<String> steps;
  final String? heroImageUrl;
  final bool isSaved;

  Recipe copyWith({bool? isSaved}) => Recipe(
        id: id,
        title: title,
        cuisine: cuisine,
        difficulty: difficulty,
        prepMinutes: prepMinutes,
        cookMinutes: cookMinutes,
        servingsBase: servingsBase,
        calories: calories,
        likes: likes,
        comments: comments,
        chef: chef,
        reelSeconds: reelSeconds,
        tags: tags,
        ingredients: ingredients,
        steps: steps,
        heroImageUrl: heroImageUrl,
        isSaved: isSaved ?? this.isSaved,
      );

  factory Recipe.fromJson(Map<String, dynamic> json) {
    List<String> list(dynamic value) =>
        (value as List?)?.map((e) => e.toString()).toList() ?? const [];

    return Recipe(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      cuisine: json['cuisine'] as String? ?? '',
      difficulty: json['difficulty'] as String? ?? 'Easy',
      prepMinutes: (json['prep_minutes'] as num?)?.toInt() ?? 0,
      cookMinutes: (json['cook_minutes'] as num?)?.toInt() ?? 0,
      servingsBase: (json['servings'] as num?)?.toInt() ?? 4,
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      likes: json['likes']?.toString() ?? '0',
      comments: (json['comments'] as num?)?.toInt() ?? 0,
      chef: json['chef'] as String? ?? '',
      reelSeconds: (json['reel_seconds'] as num?)?.toInt() ?? 0,
      tags: list(json['tags']),
      ingredients: list(json['ingredients']),
      steps: list(json['steps']),
      heroImageUrl: json['hero_image_url'] as String?,
      isSaved: json['is_saved'] as bool? ?? false,
    );
  }

  /// Scales any leading quantity in an ingredient line to [servings].
  /// "1kg beef shank" at base 6 → "1.5kg beef shank" at 9.
  String scaledIngredient(String line, int servings) {
    if (servings == servingsBase) return line;
    final factor = servings / servingsBase;

    final fraction = RegExp(r'^(\d+)\s*/\s*(\d+)\s*(.*)$').firstMatch(line);
    if (fraction != null) {
      final value = int.parse(fraction.group(1)!) / int.parse(fraction.group(2)!);
      return '${_format(value * factor)} ${fraction.group(3)}'.trim();
    }

    final decimal = RegExp(r'^(\d+(?:\.\d+)?)\s*(.*)$').firstMatch(line);
    if (decimal != null) {
      final value = double.parse(decimal.group(1)!);
      return '${_format(value * factor)}${_spacer(decimal.group(2)!)}${decimal.group(2)}';
    }

    return line;
  }

  static String _spacer(String rest) => rest.startsWith(RegExp(r'[a-zA-Z]')) ? '' : ' ';

  static String _format(double value) {
    if ((value - value.roundToDouble()).abs() < 0.01) {
      return value.round().toString();
    }
    return value.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }
}

/// Seed content matching the prototype. Replaced by API data once the
/// recipes endpoint is wired in.
const List<Recipe> kSeedRecipes = [
  Recipe(
    id: 'nihari',
    title: 'Karachi Beef Nihari',
    cuisine: 'Pakistani',
    difficulty: 'Medium',
    prepMinutes: 20,
    cookMinutes: 180,
    servingsBase: 6,
    calories: 420,
    likes: '1.2K',
    comments: 86,
    chef: 'Rabia Nasar',
    reelSeconds: 45,
    tags: ['Pakistani', 'Comfort Food', 'Spicy'],
    ingredients: [
      '1kg beef shank, bone-in',
      '1/2 cup Nihari masala',
      '4 tbsp ghee',
      '2 onions, sliced',
      '1/4 cup flour, for gravy',
      'Ginger, chili, lime to garnish',
    ],
    steps: [
      'Sear beef shank in ghee until browned on all sides.',
      'Add sliced onions and Nihari masala, cook until fragrant.',
      'Add water, bring to a boil, then simmer covered for 3 hours until tender.',
      'Whisk flour with water and stir into the gravy to thicken.',
      'Garnish with ginger, green chili and lime before serving.',
    ],
  ),
  Recipe(
    id: 'pasta',
    title: 'Creamy Garlic Butter Pasta',
    cuisine: 'Italian',
    difficulty: 'Easy',
    prepMinutes: 10,
    cookMinutes: 15,
    servingsBase: 4,
    calories: 560,
    likes: '892',
    comments: 41,
    chef: 'Rabia Nasar',
    reelSeconds: 38,
    tags: ['Italian', 'Quick', 'Vegetarian'],
    ingredients: [
      '300g fettuccine',
      '4 tbsp butter',
      '6 cloves garlic, minced',
      '1 cup heavy cream',
      '1/2 cup parmesan, grated',
      'Salt, pepper, parsley',
    ],
    steps: [
      'Boil pasta in salted water until al dente; reserve 1 cup pasta water.',
      'Melt butter, sauté garlic until golden and fragrant.',
      'Pour in cream, simmer gently for 3 minutes.',
      'Toss in pasta and parmesan, loosen with pasta water as needed.',
      'Finish with parsley, season, and serve immediately.',
    ],
  ),
  Recipe(
    id: 'curry',
    title: 'Thai Green Curry',
    cuisine: 'Thai',
    difficulty: 'Medium',
    prepMinutes: 15,
    cookMinutes: 25,
    servingsBase: 4,
    calories: 480,
    likes: '734',
    comments: 29,
    chef: 'Rabia Nasar',
    reelSeconds: 52,
    tags: ['Thai', 'Spicy', 'Dairy-free'],
    ingredients: [
      '3 tbsp green curry paste',
      '400ml coconut milk',
      '300g chicken thigh, sliced',
      '1 eggplant, cubed',
      'Thai basil leaves',
      'Fish sauce, palm sugar',
    ],
    steps: [
      'Fry curry paste in a splash of coconut milk until fragrant.',
      'Add chicken, cook until sealed.',
      'Pour in remaining coconut milk, add eggplant, simmer 15 minutes.',
      'Season with fish sauce and palm sugar to taste.',
      'Stir through Thai basil just before serving.',
    ],
  ),
  Recipe(
    id: 'lava',
    title: 'Chocolate Lava Cake',
    cuisine: 'Dessert',
    difficulty: 'Easy',
    prepMinutes: 15,
    cookMinutes: 12,
    servingsBase: 4,
    calories: 390,
    likes: '2.1K',
    comments: 158,
    chef: 'Rabia Nasar',
    reelSeconds: 41,
    tags: ['Dessert', 'Chocolate', '30-min'],
    ingredients: [
      '200g dark chocolate',
      '200g butter',
      '4 eggs + 4 yolks',
      '150g sugar',
      '80g flour',
      'Butter and cocoa for ramekins',
    ],
    steps: [
      'Melt chocolate and butter together until smooth.',
      'Whisk eggs, yolks and sugar until pale and thick.',
      'Fold chocolate mixture into eggs, then fold in flour.',
      'Pour into buttered ramekins, chill 15 minutes.',
      'Bake at 220°C for 12 minutes until edges set, centre stays soft.',
    ],
  ),
  Recipe(
    id: 'chicken',
    title: 'Grilled Lemon Herb Chicken',
    cuisine: 'Healthy',
    difficulty: 'Easy',
    prepMinutes: 15,
    cookMinutes: 20,
    servingsBase: 4,
    calories: 340,
    likes: '611',
    comments: 22,
    chef: 'Rabia Nasar',
    reelSeconds: 35,
    tags: ['Healthy', 'High-protein', 'Grilled'],
    ingredients: [
      '4 chicken breasts',
      '2 lemons, juiced and zested',
      '3 tbsp olive oil',
      '2 cloves garlic, minced',
      'Fresh rosemary and thyme',
      'Salt and pepper',
    ],
    steps: [
      'Whisk lemon juice, zest, oil, garlic and herbs into a marinade.',
      'Marinate chicken for at least 30 minutes.',
      'Grill over medium-high heat, 6-7 minutes per side.',
      'Rest for 5 minutes before slicing.',
      'Serve with extra lemon wedges.',
    ],
  ),
];
