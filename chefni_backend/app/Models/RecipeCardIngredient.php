<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class RecipeCardIngredient extends Model
{
    use HasFactory;

    protected $fillable = [
        'recipe_card_id',
        'name',
        'quantity',
        'unit',
        'category',
        'ai_estimated_cost',
        'user_cost',
        'sort_order',
    ];

    /**
     * Costs stay uncast. A `decimal:` cast routes every assignment through
     * brick/math, which deprecation-warns on the floats the extractor produces;
     * the column is already DECIMAL(10,2), so the database does the rounding.
     */
    protected $casts = [
        'quantity' => 'float',
        'sort_order' => 'integer',
    ];

    public function card()
    {
        return $this->belongsTo(RecipeCard::class, 'recipe_card_id');
    }

    /** A user override always wins over the model's guess. */
    public function effectiveCost(): float
    {
        return (float) ($this->user_cost ?? $this->ai_estimated_cost ?? 0);
    }

    public function isUserOverridden(): bool
    {
        return $this->user_cost !== null;
    }

    public function toApiArray(): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'quantity' => $this->quantity,
            'unit' => $this->unit,
            'category' => $this->category,
            'ai_estimated_cost' => $this->ai_estimated_cost !== null
                ? (float) $this->ai_estimated_cost
                : null,
            'user_cost' => $this->user_cost !== null ? (float) $this->user_cost : null,
            'effective_cost' => $this->effectiveCost(),
            'is_user_overridden' => $this->isUserOverridden(),
            'sort_order' => $this->sort_order,
        ];
    }
}
