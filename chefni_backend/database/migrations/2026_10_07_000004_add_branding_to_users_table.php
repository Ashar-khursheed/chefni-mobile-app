<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * White-label is a Restaurant Pro add-on: swap the Chefni watermark on
 * exported reels for the restaurant's own logo.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('brand_name')->nullable()->after('country_code');
            $table->string('brand_logo_url')->nullable()->after('brand_name');
            $table->boolean('white_label_enabled')->default(false)->after('brand_logo_url');
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['brand_name', 'brand_logo_url', 'white_label_enabled']);
        });
    }
};
