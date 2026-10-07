<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Subscription extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'tier',
        'billing_cycle',
        'payment_method',
        'status',
        'price_label',
        'country_code',
        'trial_ends_at',
        'current_period_ends_at',
        'cancelled_at',
    ];

    protected $casts = [
        'trial_ends_at' => 'datetime',
        'current_period_ends_at' => 'datetime',
        'cancelled_at' => 'datetime',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function toApiArray(): array
    {
        return [
            'id' => $this->id,
            'tier' => $this->tier,
            'billing_cycle' => $this->billing_cycle,
            'payment_method' => $this->payment_method,
            'status' => $this->status,
            'price_label' => $this->price_label,
            'trial_ends_at' => $this->trial_ends_at?->toIso8601String(),
            'current_period_ends_at' => $this->current_period_ends_at?->toIso8601String(),
        ];
    }
}
