<?php

namespace App\Http\Controllers;

use App\Models\Store;
use Illuminate\Http\Request;

/**
 * Locations a Restaurant Pro account operates. Ownership is enforced by
 * scoping every query through the authenticated user, matching how the rest of
 * the API guards its rows.
 */
class StoreController extends Controller
{
    public function index(Request $request)
    {
        $stores = $request->user()
            ->stores()
            ->with('inventoryItems')
            ->orderByDesc('is_default')
            ->orderBy('name')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $stores->map->toApiArray()->values(),
        ]);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'name' => 'required|string|max:120',
            'address' => 'nullable|string|max:255',
        ]);

        $user = $request->user();

        // Multi-location is a paid capability; everyone else keeps their one
        // default kitchen.
        if (! $user->hasCreatorTools() && $user->stores()->count() >= 1) {
            return response()->json([
                'success' => false,
                'message' => 'Multiple locations are part of Restaurant Pro.',
                'upgrade_required' => true,
            ], 402);
        }

        $store = $user->stores()->create([
            'name' => $data['name'],
            'address' => $data['address'] ?? null,
            'is_default' => $user->stores()->count() === 0,
        ]);

        return response()->json([
            'success' => true,
            'data' => $store->toApiArray(),
        ], 201);
    }

    public function update(Request $request, int $id)
    {
        $data = $request->validate([
            'name' => 'sometimes|string|max:120',
            'address' => 'nullable|string|max:255',
        ]);

        $store = $this->findOwned($request, $id);
        $store->update($data);

        return response()->json([
            'success' => true,
            'data' => $store->fresh()->toApiArray(),
        ]);
    }

    public function destroy(Request $request, int $id)
    {
        $store = $this->findOwned($request, $id);

        // Deleting the last location would strand every inventory row.
        if ($request->user()->stores()->count() <= 1) {
            return response()->json([
                'success' => false,
                'message' => 'You need at least one location.',
            ], 422);
        }

        $wasDefault = $store->is_default;
        $store->delete();

        if ($wasDefault) {
            $request->user()->stores()->oldest('id')->first()?->update(['is_default' => true]);
        }

        return response()->json(['success' => true]);
    }

    private function findOwned(Request $request, int $id): Store
    {
        return $request->user()->stores()->findOrFail($id);
    }
}
