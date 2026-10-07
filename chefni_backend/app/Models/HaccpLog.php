<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class HaccpLog extends Model
{
    protected $fillable = [
        'user_id',
        'store_id',
        'type',
        'label',
        'value',
        'status',
        'logged_by',
        'notes',
    ];

    public const TYPES = ['temperature', 'hygiene'];
    public const STATUSES = ['pass', 'warning', 'fail'];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function store(): BelongsTo
    {
        return $this->belongsTo(Store::class);
    }

    public function toApiArray(): array
    {
        return [
            'id' => $this->id,
            'store_id' => $this->store_id,
            'type' => $this->type,
            'label' => $this->label,
            'value' => $this->value,
            'status' => $this->status,
            'logged_by' => $this->logged_by,
            'notes' => $this->notes,
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
