<?php

namespace App\Http\Controllers;

use App\Jobs\ProcessVideoJob;
use App\Models\UserVideo;
use App\Services\CreditService;
use App\Services\VideoProcessingService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use RuntimeException;

class UserStudioController extends Controller
{
    /** Raw uploads are trimmed to a 60-second reel, so a hard ceiling is fine. */
    private const MAX_UPLOAD_KB = 512000; // 500 MB

    public function __construct(
        private readonly VideoProcessingService $videoService,
        private readonly CreditService $credits,
    ) {
    }

    /**
     * Accept a raw cooking video and queue it for reel compression and recipe
     * extraction. Returns immediately — the client polls `status` for progress.
     */
    public function uploadVideo(Request $request)
    {
        $data = $request->validate([
            'title' => 'required|string|max:255',
            'video' => 'required|file|mimetypes:video/mp4,video/quicktime,video/x-msvideo,video/x-matroska,video/webm|max:'.self::MAX_UPLOAD_KB,
            'is_private' => 'nullable|boolean',
        ]);

        $user = $request->user();

        if (! $user->canUpload()) {
            $total = $user->uploadQuotaTotal() ?? 0;

            return response()->json([
                'success' => false,
                'message' => "You have used all {$total} video extractions included "
                    .'on your plan. Upgrade to keep creating.',
                'upgrade_required' => true,
            ], 403);
        }

        // A queued job that cannot encode would only surface the problem minutes
        // later, so refuse up front instead.
        if (! $this->videoService->isAvailable()) {
            return response()->json([
                'success' => false,
                'message' => 'Video processing is unavailable on this server: FFmpeg is not installed.',
            ], 503);
        }

        $file = $request->file('video');
        $rawPath = $file->store('raw_uploads', 'local');

        $video = UserVideo::create([
            'user_id' => $user->id,
            'title' => $data['title'],
            'status' => UserVideo::STATUS_QUEUED,
            'raw_path' => $rawPath,
            'original_size_bytes' => $file->getSize(),
            'is_private' => $data['is_private'] ?? true,
        ]);

        // Charged once the row exists so the ledger can point at the video,
        // and so ProcessVideoJob can refund this exact charge if it fails.
        try {
            $this->credits->consume($user, $video->id);
        } catch (RuntimeException $e) {
            $video->delete();

            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
                'upgrade_required' => true,
            ], 402);
        }

        ProcessVideoJob::dispatch($video->id);

        return response()->json([
            'success' => true,
            'message' => 'Upload received. Your reel is being prepared.',
            'data' => $video->toApiArray(),
            'upload_quota_remaining' => $user->fresh()->uploadQuotaRemaining(),
        ], 202);
    }

    /** Polled by the client while a video moves through the pipeline. */
    public function status(Request $request, int $id)
    {
        $video = $this->findOwned($request, $id);

        return response()->json([
            'success' => true,
            'data' => $video->toApiArray(),
        ]);
    }

    public function myVideos(Request $request)
    {
        $videos = $request->user()
            ->videos()
            ->with('recipeCard')
            ->latest()
            ->paginate(20);

        return response()->json([
            'success' => true,
            'data' => $videos->getCollection()->map->toApiArray()->all(),
            'meta' => [
                'current_page' => $videos->currentPage(),
                'last_page' => $videos->lastPage(),
                'total' => $videos->total(),
            ],
            'upload_quota_remaining' => $request->user()->uploadQuotaRemaining(),
        ]);
    }

    public function destroy(Request $request, int $id)
    {
        $video = $this->findOwned($request, $id);

        foreach ([$video->reel_path, $video->thumbnail_path] as $path) {
            if ($path && Storage::disk('public')->exists($path)) {
                Storage::disk('public')->delete($path);
            }
        }

        if ($video->raw_path && Storage::disk('local')->exists($video->raw_path)) {
            Storage::disk('local')->delete($video->raw_path);
        }

        // The recipe card cascades with the row.
        $video->delete();

        return response()->json([
            'success' => true,
            'message' => 'Video deleted.',
        ]);
    }

    private function findOwned(Request $request, int $id): UserVideo
    {
        return $request->user()
            ->videos()
            ->with('recipeCard')
            ->findOrFail($id);
    }
}
