<?php

namespace App\Http\Controllers;

use App\Models\Recipe;
use Illuminate\Http\Request;

class RecipeController extends Controller
{
    /**
     * Recipe feed with optional cuisine filter and full-text search,
     * backing both the home feed and Discover.
     */
    public function index(Request $request)
    {
        $query = Recipe::with(['user', 'reel'])->where('is_published', true);

        if ($cuisine = $request->query('cuisine')) {
            if (strtolower($cuisine) !== 'all') {
                $query->where('cuisine', $cuisine);
            }
        }

        if ($search = $request->query('search')) {
            $query->where(function ($q) use ($search) {
                $q->where('title', 'like', "%{$search}%")
                    ->orWhere('cuisine', 'like', "%{$search}%");
            });
        }

        $recipes = $query->orderByDesc('likes_count')->get();
        $savedIds = $this->savedIds($request);

        return response()->json([
            'success' => true,
            'data' => $recipes->map(
                fn (Recipe $r) => $r->toApiArray($savedIds->contains($r->id))
            )->values(),
        ]);
    }

    public function show(Request $request, string $slug)
    {
        $recipe = Recipe::with(['user', 'reel', 'ingredients', 'steps'])
            ->where('slug', $slug)
            ->orWhere('id', $slug)
            ->firstOrFail();

        return response()->json([
            'success' => true,
            'data' => $recipe->toApiArray($this->savedIds($request)->contains($recipe->id)),
        ]);
    }

    /**
     * Distinct cuisines for the filter chips, so the client never hardcodes
     * a list that drifts from the catalogue.
     */
    public function cuisines()
    {
        $cuisines = Recipe::where('is_published', true)
            ->distinct()
            ->orderBy('cuisine')
            ->pluck('cuisine');

        return response()->json([
            'success' => true,
            'data' => collect(['All'])->concat($cuisines)->values(),
        ]);
    }

    public function toggleSave(Request $request, string $slug)
    {
        $recipe = Recipe::where('slug', $slug)->orWhere('id', $slug)->firstOrFail();
        $user = $request->user();

        if ($user->savedRecipes()->where('recipe_id', $recipe->id)->exists()) {
            $user->savedRecipes()->detach($recipe->id);
            $isSaved = false;
        } else {
            $user->savedRecipes()->attach($recipe->id);
            $isSaved = true;
        }

        return response()->json(['success' => true, 'is_saved' => $isSaved]);
    }

    public function saved(Request $request)
    {
        $recipes = $request->user()
            ->savedRecipes()
            ->with(['user', 'reel'])
            ->get();

        return response()->json([
            'success' => true,
            'data' => $recipes->map(fn (Recipe $r) => $r->toApiArray(true))->values(),
        ]);
    }

    /**
     * Saved recipe ids for the caller, or an empty set for guests.
     */
    private function savedIds(Request $request)
    {
        return $request->user()
            ? $request->user()->savedRecipes()->pluck('recipes.id')
            : collect();
    }
}
