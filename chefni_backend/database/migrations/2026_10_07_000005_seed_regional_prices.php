<?php

use App\Models\RegionalPrice;
use Illuminate\Database\Migrations\Migration;

/**
 * The geo-pricing endpoint used to serve these three regions from a
 * hardcoded PHP array instead of the (already-migrated) regional_prices
 * table, so the admin "update pricing" endpoint had nothing to write to.
 * This seeds the table the controller now actually reads and writes.
 */
return new class extends Migration
{
    public function up(): void
    {
        $regions = [
            [
                'country_code' => 'PK',
                'country_name' => 'Pakistan',
                'currency_code' => 'PKR',
                'creator_monthly_price' => 1390,
                'creator_yearly_price' => 12500,
                'pro_monthly_price' => 3600,
                'pro_yearly_price' => 33400,
                'is_active' => true,
            ],
            [
                'country_code' => 'AE',
                'country_name' => 'United Arab Emirates / GCC',
                'currency_code' => 'AED',
                'creator_monthly_price' => 19.99,
                'creator_yearly_price' => 179.99,
                'pro_monthly_price' => 49.99,
                'pro_yearly_price' => 449.99,
                'is_active' => true,
            ],
            [
                'country_code' => 'US',
                'country_name' => 'United States / Global',
                'currency_code' => 'USD',
                'creator_monthly_price' => 4.99,
                'creator_yearly_price' => 44.99,
                'pro_monthly_price' => 12.99,
                'pro_yearly_price' => 119.99,
                'is_active' => true,
            ],
        ];

        foreach ($regions as $region) {
            RegionalPrice::updateOrCreate(['country_code' => $region['country_code']], $region);
        }
    }

    public function down(): void
    {
        RegionalPrice::whereIn('country_code', ['PK', 'AE', 'US'])->delete();
    }
};
