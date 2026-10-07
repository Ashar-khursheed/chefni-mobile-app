<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * One movement of the credit balance. Rows are append-only — a correction is
 * another row, never an edit, so the history stays auditable.
 */
class VideoCredit extends Model
{
    public const REASON_GRANT = 'grant';
    public const REASON_CONSUME = 'consume';
    public const REASON_REFUND = 'refund';
    public const REASON_MONTHLY_RESET = 'monthly_reset';

    protected $fillable = [
        'user_id',
        'delta',
        'reason',
        'balance_after',
        'user_video_id',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function toApiArray(): array
    {
        return [
            'id' => $this->id,
            'delta' => (int) $this->delta,
            'reason' => $this->reason,
            'balance_after' => (int) $this->balance_after,
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
