<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class RecipeCard extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'user_video_id',
        'title',
        'summary',
        'cuisine',
        'prep_time_mins',
        'cook_time_mins',
        'servings',
        'steps',
        'currency',
        'cost_is_ai_estimate',
        'user_edited_cost',
        'extraction_confidence',
        'labor_cost',
        'overhead_cost',
        'packaging_cost',
        'selling_price',
    ];

    protected $casts = [
        'steps' => 'array',
        'cost_is_ai_estimate' => 'boolean',
        'user_edited_cost' => 'boolean',
        'servings' => 'integer',
        'prep_time_mins' => 'integer',
        'cook_time_mins' => 'integer',
        'labor_cost' => 'float',
        'overhead_cost' => 'float',
        'packaging_cost' => 'float',
        'selling_price' => 'float',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function video()
    {
        return $this->belongsTo(UserVideo::class, 'user_video_id');
    }

    public function ingredients()
    {
        return $this->hasMany(RecipeCardIngredient::class)->orderBy('sort_order');
    }

    /** Sum of effective ingredient costs — user overrides where present, AI guesses otherwise. */
    public function totalCost(): float
    {
        return round(
            $this->ingredients->sum(fn (RecipeCardIngredient $i) => $i->effectiveCost()),
            2
        );
    }

    /** Ingredients plus labor, overhead and packaging — the full cost matrix. */
    public function trueTotalCost(): float
    {
        return round(
            $this->totalCost() + $this->labor_cost + $this->overhead_cost + $this->packaging_cost,
            2
        );
    }

    /** Null until a selling price is set — there is no margin without one. */
    public function grossMarginPct(): ?float
    {
        if ($this->selling_price === null || $this->selling_price <= 0) {
            return null;
        }

        return round(
            (($this->selling_price - $this->trueTotalCost()) / $this->selling_price) * 100,
            1
        );
    }

    public function toApiArray(): array
    {
        $total = $this->totalCost();
        $servings = max(1, $this->servings);
        $trueTotal = $this->trueTotalCost();

        return [
            'id' => $this->id,
            'user_video_id' => $this->user_video_id,
            'title' => $this->title,
            'summary' => $this->summary,
            'cuisine' => $this->cuisine,
            'prep_time_mins' => $this->prep_time_mins,
            'cook_time_mins' => $this->cook_time_mins,
            'servings' => $this->servings,
            'steps' => $this->steps ?? [],
            'currency' => $this->currency,
            'cost_is_ai_estimate' => $this->cost_is_ai_estimate,
            'user_edited_cost' => $this->user_edited_cost,
            'extraction_confidence' => $this->extraction_confidence,
            'total_cost' => $total,
            'cost_per_serving' => round($total / $servings, 2),
            'labor_cost' => $this->labor_cost,
            'overhead_cost' => $this->overhead_cost,
            'packaging_cost' => $this->packaging_cost,
            'selling_price' => $this->selling_price,
            'true_total_cost' => $trueTotal,
            'true_cost_per_serving' => round($trueTotal / $servings, 2),
            'gross_margin_pct' => $this->grossMarginPct(),
            'ingredients' => $this->ingredients->map->toApiArray()->all(),
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
