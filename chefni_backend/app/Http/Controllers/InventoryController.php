<?php

namespace App\Http\Controllers;

use App\Models\InventoryItem;
use App\Models\Recipe;
use Illuminate\Http\Request;

class InventoryController extends Controller
{
    public function index(Request $request)
    {
        $request->validate(['store_id' => 'nullable|integer']);

        $query = $request->user()->inventoryItems()->orderBy('name');

        // Without a store filter the response covers every location, which is
        // what a single-location account wants.
        if ($request->filled('store_id')) {
            $query->where('store_id', $request->integer('store_id'));
        }

        $items = $query->get();

        return response()->json([
            'success' => true,
            'data' => $items->map(fn (InventoryItem $i) => $i->toApiArray())->values(),
            'expiring_count' => $items->filter->isExpiringSoon()->count(),
            'low_stock_count' => $items->filter->isLowStock()->count(),
        ]);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'name' => 'required|string|max:255',
            'quantity' => 'required|string|max:64',
            'unit' => 'nullable|string|max:32',
            'unit_cost' => 'nullable|numeric|min:0',
            'min_threshold' => 'nullable|numeric|min:0',
            'expiry_date' => 'nullable|date',
            'store_id' => 'nullable|integer',
        ]);

        $user = $request->user();
        $storeId = $this->resolveStoreId($request, $data['store_id'] ?? null);

        $item = $user->inventoryItems()->create([
            'store_id' => $storeId,
            'name' => $data['name'],
            'quantity' => $data['quantity'],
            'unit' => $data['unit'] ?? '',
            'unit_cost' => $data['unit_cost'] ?? null,
            'min_threshold' => $data['min_threshold'] ?? 0,
            'expiry_date' => $data['expiry_date'] ?? null,
        ]);

        return response()->json(['success' => true, 'data' => $item->toApiArray()], 201);
    }

    /**
     * Stock changes as it is used, so quantity and thresholds need editing
     * without deleting and re-adding the row.
     */
    public function update(Request $request, int $id)
    {
        $data = $request->validate([
            'name' => 'sometimes|string|max:255',
            'quantity' => 'sometimes|string|max:64',
            'unit' => 'nullable|string|max:32',
            'unit_cost' => 'nullable|numeric|min:0',
            'min_threshold' => 'nullable|numeric|min:0',
            'expiry_date' => 'nullable|date',
            'store_id' => 'nullable|integer',
        ]);

        $item = $request->user()->inventoryItems()->findOrFail($id);

        if (array_key_exists('store_id', $data)) {
            $data['store_id'] = $this->resolveStoreId($request, $data['store_id']);
        }

        $item->update($data);

        return response()->json(['success' => true, 'data' => $item->fresh()->toApiArray()]);
    }

    public function destroy(Request $request, int $id)
    {
        $request->user()->inventoryItems()->findOrFail($id)->delete();

        return response()->json(['success' => true]);
    }

    /**
     * Keeps stock inside a location the caller owns. An unknown or absent id
     * lands in their default kitchen rather than being rejected — single-store
     * clients never send one.
     */
    private function resolveStoreId(Request $request, ?int $storeId): int
    {
        $user = $request->user();

        if ($storeId !== null && $user->stores()->whereKey($storeId)->exists()) {
            return $storeId;
        }

        return $user->defaultStore()->id;
    }

    /**
     * "Can I cook this?" — compares a recipe's ingredients against the
     * user's pantry by name match and reports what is missing.
     */
    public function checkRecipe(Request $request, string $slug)
    {
        $recipe = Recipe::with('ingredients')
            ->where('slug', $slug)
            ->orWhere('id', $slug)
            ->firstOrFail();

        $pantry = $request->user()->inventoryItems()->pluck('name')
            ->map(fn ($n) => mb_strtolower($n));

        $requirements = $recipe->ingredients->map(function ($ingredient) use ($pantry) {
            $line = $ingredient->raw_line ?? $ingredient->name;
            $inStock = $pantry->contains(
                fn ($item) => str_contains(mb_strtolower($line), $item)
            );

            return [
                'name' => $line,
                'in_stock' => $inStock,
            ];
        });

        $missing = $requirements->where('in_stock', false)->values();

        return response()->json([
            'success' => true,
            'recipe' => ['id' => $recipe->slug, 'title' => $recipe->title],
            'can_cook' => $missing->isEmpty(),
            'missing_count' => $missing->count(),
            'requirements' => $requirements->values(),
        ]);
    }
}
