<?php

namespace App\Http\Controllers;

use App\Models\Recipe;
use App\Models\ShoppingListItem;
use Illuminate\Http\Request;

class ShoppingListController extends Controller
{
    public function index(Request $request)
    {
        $items = $request->user()->shoppingListItems()->latest('id')->get();

        return response()->json([
            'success' => true,
            'total_count' => $items->count(),
            'checked_count' => $items->where('is_checked', true)->count(),
            'data' => $items->map(fn (ShoppingListItem $i) => $i->toApiArray())->values(),
        ]);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'name' => 'required|string|max:255',
            'quantity' => 'nullable|string|max:64',
            'category' => 'nullable|string|max:120',
        ]);

        $item = $request->user()->shoppingListItems()->create([
            'name' => $data['name'],
            'quantity' => $data['quantity'] ?? '',
            'category' => $data['category'] ?? 'Added manually',
        ]);

        return response()->json(['success' => true, 'data' => $item->toApiArray()], 201);
    }

    /**
     * Bulk-add a recipe's ingredients. Skips lines already on the list for
     * that recipe so repeated taps do not duplicate rows.
     */
    public function addFromRecipe(Request $request)
    {
        $data = $request->validate([
            'recipe_slug' => 'required|string',
            'lines' => 'required|array|min:1',
            'lines.*' => 'required|string|max:255',
        ]);

        $recipe = Recipe::where('slug', $data['recipe_slug'])
            ->orWhere('id', $data['recipe_slug'])
            ->firstOrFail();

        $user = $request->user();
        $existing = $user->shoppingListItems()
            ->where('recipe_id', $recipe->id)
            ->pluck('name')
            ->map(fn ($n) => mb_strtolower($n));

        $created = 0;
        foreach ($data['lines'] as $line) {
            if ($existing->contains(mb_strtolower($line))) {
                continue;
            }
            $user->shoppingListItems()->create([
                'recipe_id' => $recipe->id,
                'name' => $line,
                'category' => $recipe->title,
            ]);
            $created++;
        }

        return response()->json([
            'success' => true,
            'added' => $created,
            'skipped' => count($data['lines']) - $created,
        ], 201);
    }

    public function toggle(Request $request, int $id)
    {
        $item = $request->user()->shoppingListItems()->findOrFail($id);
        $item->update(['is_checked' => ! $item->is_checked]);

        return response()->json(['success' => true, 'data' => $item->toApiArray()]);
    }

    public function destroy(Request $request, int $id)
    {
        $request->user()->shoppingListItems()->findOrFail($id)->delete();

        return response()->json(['success' => true]);
    }

    public function clearChecked(Request $request)
    {
        $deleted = $request->user()->shoppingListItems()->where('is_checked', true)->delete();

        return response()->json(['success' => true, 'deleted' => $deleted]);
    }
}
