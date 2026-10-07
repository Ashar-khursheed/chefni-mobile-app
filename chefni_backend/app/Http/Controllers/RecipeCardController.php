<?php

namespace App\Http\Controllers;

use App\Models\RecipeCard;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class RecipeCardController extends Controller
{
    public function index(Request $request)
    {
        $cards = $request->user()
            ->recipeCards()
            ->with('ingredients')
            ->latest()
            ->paginate(20);

        return response()->json([
            'success' => true,
            'data' => $cards->getCollection()->map->toApiArray()->all(),
            'meta' => [
                'current_page' => $cards->currentPage(),
                'last_page' => $cards->lastPage(),
                'total' => $cards->total(),
            ],
        ]);
    }

    public function show(Request $request, int $id)
    {
        return response()->json([
            'success' => true,
            'data' => $this->findOwned($request, $id)->toApiArray(),
        ]);
    }

    /**
     * Override the AI's cost estimates. Sending `null` for an ingredient's cost
     * reverts it to the original estimate rather than zeroing it.
     */
    public function updateCosts(Request $request, int $id)
    {
        $data = $request->validate([
            'costs' => 'required|array|min:1',
            'costs.*.ingredient_id' => 'required|integer',
            'costs.*.user_cost' => 'nullable|numeric|min:0|max:99999999',
        ]);

        $card = $this->findOwned($request, $id);
        $byId = $card->ingredients->keyBy('id');

        // Reject the whole batch rather than silently applying part of it.
        foreach ($data['costs'] as $entry) {
            if (! $byId->has($entry['ingredient_id'])) {
                return response()->json([
                    'success' => false,
                    'message' => "Ingredient {$entry['ingredient_id']} does not belong to this recipe card.",
                ], 422);
            }
        }

        DB::transaction(function () use ($data, $byId, $card) {
            foreach ($data['costs'] as $entry) {
                $byId[$entry['ingredient_id']]->update([
                    'user_cost' => $entry['user_cost'] ?? null,
                ]);
            }

            $card->load('ingredients');

            // Once any row carries an override the total is no longer purely
            // the model's guess — but reverting every row restores that.
            $hasOverride = $card->ingredients->contains->isUserOverridden();

            $card->update([
                'user_edited_cost' => $hasOverride,
                'cost_is_ai_estimate' => ! $hasOverride,
            ]);
        });

        return response()->json([
            'success' => true,
            'message' => 'Costs updated.',
            'data' => $card->fresh(['ingredients'])->toApiArray(),
        ]);
    }

    /** Servings changes rescale quantities on read; the stored base is unchanged. */
    public function update(Request $request, int $id)
    {
        $data = $request->validate([
            'title' => 'nullable|string|max:255',
            'servings' => 'nullable|integer|min:1|max:500',
            'labor_cost' => 'nullable|numeric|min:0|max:99999999',
            'overhead_cost' => 'nullable|numeric|min:0|max:99999999',
            'packaging_cost' => 'nullable|numeric|min:0|max:99999999',
            'selling_price' => 'nullable|numeric|min:0|max:99999999',
        ]);

        $card = $this->findOwned($request, $id);
        $card->update(array_filter($data, fn ($v) => $v !== null));

        return response()->json([
            'success' => true,
            'data' => $card->fresh(['ingredients'])->toApiArray(),
        ]);
    }

    public function destroy(Request $request, int $id)
    {
        $this->findOwned($request, $id)->delete();

        return response()->json([
            'success' => true,
            'message' => 'Recipe card deleted.',
        ]);
    }

    private function findOwned(Request $request, int $id): RecipeCard
    {
        return $request->user()
            ->recipeCards()
            ->with('ingredients')
            ->findOrFail($id);
    }
}
