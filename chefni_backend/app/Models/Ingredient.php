<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Ingredient extends Model
{
    use HasFactory;

    protected $fillable = [
        'recipe_id',
        'raw_line',
        'position',
        'name',
        'quantity',
        'unit',
        'category',
        'cost_pkr',
    ];

    public function recipe()
    {
        return $this->belongsTo(Recipe::class);
    }
}
