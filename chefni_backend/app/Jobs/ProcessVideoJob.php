<?php

namespace App\Jobs;

use App\Models\RecipeCard;
use App\Models\UserVideo;
use App\Services\CreditService;
use App\Services\RecipeExtractionService;
use App\Services\TranscriptionService;
use App\Services\VideoProcessingService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;
use Throwable;

/**
 * The upload pipeline: compress the raw video into a watermarked reel, then
 * transcribe it and extract a recipe card.
 *
 * The reel is the deliverable. If transcription or extraction fails the video
 * still finishes as ready with a note explaining why no recipe came out of it —
 * only a failed encode fails the whole job.
 */
class ProcessVideoJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    /** Encoding is expensive; a retry storm would be worse than a clean failure. */
    public int $tries = 1;

    /** Must stay under the queue connection's retry_after or the job double-runs. */
    public int $timeout = 870;

    public function __construct(public readonly int $videoId)
    {
        $this->onQueue('video');
    }

    public function handle(
        VideoProcessingService $video,
        TranscriptionService $transcriber,
        RecipeExtractionService $extractor,
    ): void {
        $record = UserVideo::find($this->videoId);

        if (! $record) {
            Log::warning("ProcessVideoJob: video {$this->videoId} no longer exists.");

            return;
        }

        $rawPath = $record->raw_path ? Storage::disk('local')->path($record->raw_path) : null;

        if (! $rawPath || ! is_file($rawPath)) {
            $this->markFailed($record, 'The uploaded file could not be found on the server.');

            return;
        }

        if (! $video->isAvailable()) {
            $this->markFailed(
                $record,
                'Video processing is unavailable: FFmpeg is not installed on the server.'
            );

            return;
        }

        $record->update([
            'status' => UserVideo::STATUS_COMPRESSING,
            'processing_started_at' => now(),
            'failure_reason' => null,
        ]);

        $reelRelative = 'reels/'.uniqid('reel_').'.mp4';
        $reelAbsolute = Storage::disk('public')->path($reelRelative);

        try {
            $metadata = $video->processAndCompressReel(
                $rawPath,
                $reelAbsolute,
                Storage::disk('public')->path('assets/chefni_logo_watermark.png'),
            );
        } catch (Throwable $e) {
            Log::error("ProcessVideoJob: encode failed for video {$record->id}", [
                'error' => $e->getMessage(),
            ]);
            $this->markFailed($record, $e->getMessage());
            $this->deleteRaw($record);

            return;
        }

        $thumbRelative = 'thumbnails/'.uniqid('thumb_').'.jpg';

        $hasThumbnail = $video->extractThumbnail(
            $reelAbsolute,
            Storage::disk('public')->path($thumbRelative),
        );

        $record->update([
            'reel_path' => $reelRelative,
            'thumbnail_path' => $hasThumbnail ? $thumbRelative : null,
            'reel_size_bytes' => $metadata['file_size_bytes'],
            'original_duration_sec' => $metadata['original_duration_sec'],
            'reel_duration_sec' => $metadata['reel_duration_sec'],
            'resolution' => $metadata['resolution'],
        ]);

        // From here the reel exists, so nothing below may fail the video.
        $recipeNote = $this->buildRecipeCard($record, $rawPath, $video, $transcriber, $extractor);

        $record->update([
            'status' => UserVideo::STATUS_READY,
            'failure_reason' => $recipeNote,
            'processing_finished_at' => now(),
        ]);

        $this->deleteRaw($record);
    }

    /**
     * @return string|null A user-facing note when no recipe card was produced.
     */
    private function buildRecipeCard(
        UserVideo $record,
        string $rawPath,
        VideoProcessingService $video,
        TranscriptionService $transcriber,
        RecipeExtractionService $extractor,
    ): ?string {
        if (! $transcriber->isConfigured() || ! $extractor->isConfigured()) {
            return 'Reel is ready. Automatic recipe extraction is not configured on this server.';
        }

        $record->update(['status' => UserVideo::STATUS_TRANSCRIBING]);

        $audioPath = storage_path('app/tmp/'.uniqid('audio_').'.wav');

        try {
            if (! $video->extractAudioForTranscription($rawPath, $audioPath)) {
                return 'Reel is ready. This video has no audio track, so no recipe could be extracted.';
            }

            $transcript = $transcriber->transcribe($audioPath);
        } catch (Throwable $e) {
            Log::warning("ProcessVideoJob: transcription failed for video {$record->id}", [
                'error' => $e->getMessage(),
            ]);

            return 'Reel is ready, but the audio could not be transcribed: '.$e->getMessage();
        } finally {
            if (is_file($audioPath)) {
                @unlink($audioPath);
            }
        }

        $record->update([
            'status' => UserVideo::STATUS_EXTRACTING,
            'transcript' => $transcript,
        ]);

        try {
            $recipe = $extractor->extract(
                $transcript,
                $record->title,
                $record->user?->country_code ?? 'PK',
            );
        } catch (Throwable $e) {
            Log::warning("ProcessVideoJob: extraction failed for video {$record->id}", [
                'error' => $e->getMessage(),
            ]);

            return 'Reel is ready, but no recipe could be built from it: '.$e->getMessage();
        }

        $this->persistRecipeCard($record, $recipe);

        return null;
    }

    /** @param array<string, mixed> $recipe */
    private function persistRecipeCard(UserVideo $record, array $recipe): void
    {
        DB::transaction(function () use ($record, $recipe) {
            $card = RecipeCard::create([
                'user_id' => $record->user_id,
                'user_video_id' => $record->id,
                'title' => $recipe['title'],
                'summary' => $recipe['summary'],
                'cuisine' => $recipe['cuisine'],
                'prep_time_mins' => $recipe['prep_time_mins'],
                'cook_time_mins' => $recipe['cook_time_mins'],
                'servings' => $recipe['servings'],
                'steps' => $recipe['steps'],
                'currency' => $recipe['currency'],
                'cost_is_ai_estimate' => true,
                'user_edited_cost' => false,
                'extraction_confidence' => $recipe['confidence'],
            ]);

            foreach ($recipe['ingredients'] as $ingredient) {
                $card->ingredients()->create([
                    'name' => $ingredient['name'],
                    'quantity' => $ingredient['quantity'],
                    'unit' => $ingredient['unit'],
                    'category' => $ingredient['category'],
                    'ai_estimated_cost' => $ingredient['estimated_cost'],
                    'sort_order' => $ingredient['sort_order'],
                ]);
            }
        });
    }

    /** Source footage is large and serves no purpose once the reel exists. */
    private function deleteRaw(UserVideo $record): void
    {
        if ($record->raw_path && Storage::disk('local')->exists($record->raw_path)) {
            Storage::disk('local')->delete($record->raw_path);
        }
    }

    /**
     * Failing here means no reel was produced, so the credit spent at upload
     * goes back. Every failure path routes through this method, which is why
     * the refund lives here rather than at each call site.
     */
    private function markFailed(UserVideo $record, string $reason): void
    {
        $record->update([
            'status' => UserVideo::STATUS_FAILED,
            'failure_reason' => $reason,
            'processing_finished_at' => now(),
        ]);

        if ($record->user) {
            app(CreditService::class)->refund($record->user, $record->id);
        }
    }

    /** Reached when the worker times out or the process dies mid-encode. */
    public function failed(?Throwable $e): void
    {
        $record = UserVideo::find($this->videoId);

        if ($record && ! $record->isSettled()) {
            $this->markFailed(
                $record,
                'Processing stopped unexpectedly: '.($e?->getMessage() ?? 'unknown error')
            );
        }
    }
}
