import '../models/recipe.dart';
import '../network/api_client.dart';

class RecipeRepository {
  RecipeRepository(this._api);

  final ApiClient _api;

  Future<List<Recipe>> fetchRecipes({String? cuisine, String? search}) async {
    final json = await _api.get('/recipes', query: {
      if (cuisine != null && cuisine != 'All') 'cuisine': cuisine,
      if (search != null && search.isNotEmpty) 'search': search,
    });

    return (json['data'] as List)
        .map((e) => Recipe.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Recipe> fetchRecipe(String id) async {
    final json = await _api.get('/recipes/$id');
    return Recipe.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<List<String>> fetchCuisines() async {
    final json = await _api.get('/recipes/cuisines');
    return (json['data'] as List).map((e) => e.toString()).toList();
  }

  /// Returns the new saved state as reported by the server.
  Future<bool> toggleSave(String id) async {
    final json = await _api.post('/recipes/$id/save');
    return json['is_saved'] as bool? ?? false;
  }

  Future<List<Recipe>> fetchSaved() async {
    final json = await _api.get('/me/saved-recipes');
    return (json['data'] as List)
        .map((e) => Recipe.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
