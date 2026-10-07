<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class OtpCode extends Model
{
    /** Wrong guesses allowed before the code is dead. */
    public const MAX_ATTEMPTS = 5;

    protected $fillable = [
        'phone',
        'code_hash',
        'expires_at',
        'attempts',
        'consumed_at',
    ];

    protected function casts(): array
    {
        return [
            'expires_at' => 'datetime',
            'consumed_at' => 'datetime',
        ];
    }

    public function isExpired(): bool
    {
        return $this->expires_at->isPast();
    }

    public function isConsumed(): bool
    {
        return $this->consumed_at !== null;
    }

    public function isExhausted(): bool
    {
        return $this->attempts >= self::MAX_ATTEMPTS;
    }

    /** A code is only usable while it is fresh, unused and un-brute-forced. */
    public function isUsable(): bool
    {
        return ! $this->isExpired() && ! $this->isConsumed() && ! $this->isExhausted();
    }
}
