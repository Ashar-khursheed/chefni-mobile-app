<?php

namespace App\Http\Controllers;

use App\Models\Reel;
use Illuminate\Http\Request;

class OfficialReelController extends Controller
{
    /**
     * Public reels feed. Only official Chefni content is returned — private
     * user uploads never appear here.
     */
    public function index(Request $request)
    {
        $reels = Reel::with(['user', 'recipe'])
            ->where('is_official', true)
            ->latest('id')
            ->get();

        $likedIds = $this->likedIds($request);

        return response()->json([
            'success' => true,
            'total' => $reels->count(),
            'data' => $reels->map(
                fn (Reel $r) => $r->toApiArray($likedIds->contains($r->id))
            )->values(),
        ]);
    }

    public function show(Request $request, int $id)
    {
        $reel = Reel::with(['user', 'recipe'])->where('is_official', true)->findOrFail($id);

        return response()->json([
            'success' => true,
            'data' => $reel->toApiArray($this->likedIds($request)->contains($reel->id)),
        ]);
    }

    /**
     * Toggle a like. The count is derived from the pivot table, so it stays
     * correct instead of drifting on repeated taps.
     */
    public function like(Request $request, int $id)
    {
        $reel = Reel::findOrFail($id);
        $user = $request->user();

        if ($user->likedReels()->where('reel_id', $reel->id)->exists()) {
            $user->likedReels()->detach($reel->id);
            $reel->decrement('likes_count');
            $isLiked = false;
        } else {
            $user->likedReels()->attach($reel->id);
            $reel->increment('likes_count');
            $isLiked = true;
        }

        return response()->json([
            'success' => true,
            'is_liked' => $isLiked,
            'likes_count' => $reel->fresh()->likes_count,
        ]);
    }

    private function likedIds(Request $request)
    {
        return $request->user()
            ? $request->user()->likedReels()->pluck('reels.id')
            : collect();
    }
}
