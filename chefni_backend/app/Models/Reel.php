<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Reel extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'recipe_id',
        'title',
        'video_url',
        'duration_sec',
        'watermark_applied',
        'is_official',
        'likes_count',
        'views_count',
    ];

    protected $casts = [
        'watermark_applied' => 'boolean',
        'is_official' => 'boolean',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function recipe()
    {
        return $this->belongsTo(Recipe::class);
    }

    public function likedBy()
    {
        return $this->belongsToMany(User::class, 'reel_likes')->withTimestamps();
    }

    public function toApiArray(bool $isLiked = false): array
    {
        return [
            'id' => (string) $this->id,
            'title' => $this->title,
            'caption' => $this->title.' — full recipe & cost in the app.',
            'chef' => $this->user?->name ?? 'Chefni',
            'video_url' => $this->video_url,
            'duration_sec' => $this->duration_sec,
            'likes_count' => $this->likes_count,
            'comments_count' => $this->recipe?->comments_count ?? 0,
            'is_official' => (bool) $this->is_official,
            'is_liked' => $isLiked,
            'recipe_id' => $this->recipe?->slug ?? (string) $this->recipe_id,
        ];
    }
}
