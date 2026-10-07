<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class RegionalPrice extends Model
{
    use HasFactory;

    protected $fillable = [
        'country_code',
        'country_name',
        'currency_code',
        'creator_monthly_price',
        'creator_yearly_price',
        'pro_monthly_price',
        'pro_yearly_price',
        'is_active',
    ];
}
