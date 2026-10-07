<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

/**
 * White-label is a Restaurant Pro add-on: when enabled, exported reels carry
 * the restaurant's own name/logo instead of the Chefni watermark. Storing the
 * logo itself is out of scope here — this persists the URL and the toggle;
 * the reel export pipeline reads them at render time.
 */
class BrandingController extends Controller
{
    public function show(Request $request)
    {
        $user = $request->user();

        return response()->json([
            'success' => true,
            'data' => $this->toApiArray($user),
        ]);
    }

    public function update(Request $request)
    {
        $data = $request->validate([
            'brand_name' => 'nullable|string|max:120',
            'brand_logo_url' => 'nullable|url|max:500',
            'white_label_enabled' => 'required|boolean',
        ]);

        $user = $request->user();

        if ($data['white_label_enabled'] && empty($data['brand_logo_url'] ?? $user->brand_logo_url)) {
            return response()->json([
                'success' => false,
                'message' => 'Add a logo before turning white-label on.',
            ], 422);
        }

        $user->update($data);

        return response()->json([
            'success' => true,
            'data' => $this->toApiArray($user->fresh()),
        ]);
    }

    private function toApiArray($user): array
    {
        return [
            'brand_name' => $user->brand_name,
            'brand_logo_url' => $user->brand_logo_url,
            'white_label_enabled' => (bool) $user->white_label_enabled,
        ];
    }
}
