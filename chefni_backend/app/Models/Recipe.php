<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Recipe extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'slug',
        'title',
        'cuisine',
        'difficulty',
        'calories',
        'tags',
        'hero_image_url',
        'likes_count',
        'comments_count',
        'summary',
        'prep_time_mins',
        'cook_time_mins',
        'servings_base',
        'base_ingredient_weight_g',
        'is_official',
        'is_published',
    ];

    protected $casts = [
        'tags' => 'array',
        'is_official' => 'boolean',
        'is_published' => 'boolean',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function ingredients()
    {
        return $this->hasMany(Ingredient::class)->orderBy('position');
    }

    public function steps()
    {
        return $this->hasMany(RecipeStep::class)->orderBy('position');
    }

    public function reel()
    {
        return $this->hasOne(Reel::class);
    }

    /**
     * Shape consumed by the mobile app's Recipe.fromJson.
     */
    public function toApiArray(bool $isSaved = false): array
    {
        return [
            'id' => $this->slug ?: (string) $this->id,
            'title' => $this->title,
            'cuisine' => $this->cuisine,
            'difficulty' => $this->difficulty,
            'prep_minutes' => $this->prep_time_mins,
            'cook_minutes' => $this->cook_time_mins,
            'servings' => $this->servings_base,
            'calories' => $this->calories,
            'likes' => $this->formattedLikes(),
            'comments' => $this->comments_count,
            'chef' => $this->user?->name ?? 'Chefni',
            'reel_seconds' => $this->reel?->duration_sec ?? 0,
            'tags' => $this->tags ?? [],
            'hero_image_url' => $this->hero_image_url,
            'is_saved' => $isSaved,
            'ingredients' => $this->relationLoaded('ingredients')
                ? $this->ingredients->pluck('raw_line')->filter()->values()->all()
                : [],
            'steps' => $this->relationLoaded('steps')
                ? $this->steps->pluck('instruction')->values()->all()
                : [],
        ];
    }

    private function formattedLikes(): string
    {
        $count = (int) $this->likes_count;

        return $count >= 1000
            ? rtrim(rtrim(number_format($count / 1000, 1), '0'), '.').'K'
            : (string) $count;
    }
}
