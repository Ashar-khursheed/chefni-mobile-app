<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class InventoryItem extends Model
{
    use HasFactory;

    /** Stock within this many days of its date counts as expiring. */
    public const EXPIRY_WARNING_DAYS = 7;

    protected $fillable = [
        'user_id',
        'store_id',
        'name',
        'quantity',
        'unit',
        'unit_cost',
        'min_threshold',
        'expiry_date',
        'is_expiring',
    ];

    protected $casts = [
        'expiry_date' => 'date',
        'is_expiring' => 'boolean',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function store()
    {
        return $this->belongsTo(Store::class);
    }

    /** Negative once the date has passed; null when no date is set. */
    public function daysToExpiry(): ?int
    {
        return $this->expiry_date
            ? (int) now()->startOfDay()->diffInDays($this->expiry_date, false)
            : null;
    }

    public function isExpiringSoon(): bool
    {
        $days = $this->daysToExpiry();

        return $days !== null && $days <= self::EXPIRY_WARNING_DAYS;
    }

    /**
     * Quantity is free text ("2", "500g", "1.5"), so the numeric part is what
     * the threshold compares against. Unparseable quantities are never low —
     * guessing would raise false alarms.
     */
    public function numericQuantity(): ?float
    {
        if (preg_match('/-?\d+(\.\d+)?/', (string) $this->quantity, $m)) {
            return (float) $m[0];
        }

        return null;
    }

    public function isLowStock(): bool
    {
        $threshold = (float) ($this->min_threshold ?? 0);
        if ($threshold <= 0) {
            return false;
        }

        $quantity = $this->numericQuantity();

        return $quantity !== null && $quantity <= $threshold;
    }

    public function toApiArray(): array
    {
        $daysToExpiry = $this->daysToExpiry();

        return [
            'id' => $this->id,
            'store_id' => $this->store_id,
            'name' => $this->name,
            'quantity' => $this->quantity,
            'unit' => $this->unit,
            'unit_cost' => $this->unit_cost !== null ? (float) $this->unit_cost : null,
            'min_threshold' => (float) ($this->min_threshold ?? 0),
            'expiry_date' => $this->expiry_date?->toDateString(),
            'days_to_expiry' => $daysToExpiry,
            // Recompute rather than trusting the stored flag, which goes stale.
            'is_expiring' => $this->isExpiringSoon(),
            'is_low_stock' => $this->isLowStock(),
        ];
    }
}
