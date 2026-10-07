<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Storage;

class UserVideo extends Model
{
    use HasFactory;

    public const STATUS_QUEUED = 'queued';
    public const STATUS_COMPRESSING = 'compressing';
    public const STATUS_TRANSCRIBING = 'transcribing';
    public const STATUS_EXTRACTING = 'extracting';
    public const STATUS_READY = 'ready';
    public const STATUS_FAILED = 'failed';

    protected $fillable = [
        'user_id',
        'title',
        'status',
        'failure_reason',
        'raw_path',
        'reel_path',
        'thumbnail_path',
        'original_size_bytes',
        'reel_size_bytes',
        'original_duration_sec',
        'reel_duration_sec',
        'resolution',
        'transcript',
        'is_private',
        'processing_started_at',
        'processing_finished_at',
    ];

    protected $casts = [
        'is_private' => 'boolean',
        'original_size_bytes' => 'integer',
        'reel_size_bytes' => 'integer',
        'original_duration_sec' => 'float',
        'reel_duration_sec' => 'float',
        'processing_started_at' => 'datetime',
        'processing_finished_at' => 'datetime',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function recipeCard()
    {
        return $this->hasOne(RecipeCard::class);
    }

    /** Terminal states no longer move on their own; the client can stop polling. */
    public function isSettled(): bool
    {
        return in_array($this->status, [self::STATUS_READY, self::STATUS_FAILED], true);
    }

    /**
     * Rough progress for the client's status bar. The pipeline has no
     * sub-step reporting, so each stage contributes a fixed slice.
     */
    public function progressPercent(): int
    {
        return match ($this->status) {
            self::STATUS_QUEUED => 5,
            self::STATUS_COMPRESSING => 35,
            self::STATUS_TRANSCRIBING => 65,
            self::STATUS_EXTRACTING => 85,
            self::STATUS_READY => 100,
            default => 0,
        };
    }

    public function reelUrl(): ?string
    {
        return $this->reel_path ? Storage::disk('public')->url($this->reel_path) : null;
    }

    public function thumbnailUrl(): ?string
    {
        return $this->thumbnail_path ? Storage::disk('public')->url($this->thumbnail_path) : null;
    }

    /** Percentage of the original file size the compressed reel occupies. */
    public function compressionRatio(): ?float
    {
        if (! $this->original_size_bytes || ! $this->reel_size_bytes) {
            return null;
        }

        return round(($this->reel_size_bytes / $this->original_size_bytes) * 100, 1);
    }

    public function toApiArray(): array
    {
        return [
            'id' => $this->id,
            'title' => $this->title,
            'status' => $this->status,
            'progress' => $this->progressPercent(),
            'is_settled' => $this->isSettled(),
            'failure_reason' => $this->failure_reason,
            'is_private' => $this->is_private,
            'video_url' => $this->reelUrl(),
            'thumbnail_url' => $this->thumbnailUrl(),
            'original_size_bytes' => $this->original_size_bytes,
            'reel_size_bytes' => $this->reel_size_bytes,
            'compression_percent' => $this->compressionRatio(),
            'original_duration_sec' => $this->original_duration_sec,
            'reel_duration_sec' => $this->reel_duration_sec,
            'resolution' => $this->resolution,
            'recipe_card_id' => $this->recipeCard?->id,
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
