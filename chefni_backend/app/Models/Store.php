<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

/**
 * A kitchen or branch. Restaurant Pro accounts run several; everyone else has
 * exactly one, created at sign-up, which keeps the single-location case free of
 * any "pick a store" step.
 */
class Store extends Model
{
    protected $fillable = [
        'user_id',
        'name',
        'address',
        'is_default',
    ];

    protected $casts = [
        'is_default' => 'boolean',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function inventoryItems(): HasMany
    {
        return $this->hasMany(InventoryItem::class);
    }

    public function toApiArray(): array
    {
        $items = $this->relationLoaded('inventoryItems')
            ? $this->inventoryItems
            : null;

        return [
            'id' => $this->id,
            'name' => $this->name,
            'address' => $this->address,
            'is_default' => $this->is_default,
            'item_count' => $items?->count(),
            'low_stock_count' => $items?->filter->isLowStock()->count(),
            'expiring_count' => $items?->filter->isExpiringSoon()->count(),
        ];
    }
}
