<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Restaurant Pro's full cost matrix needs more than ingredient cost: labor,
 * overhead and packaging land on the card itself (not per-ingredient), and a
 * selling price is what turns a total cost into a gross margin.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('recipe_cards', function (Blueprint $table) {
            $table->decimal('labor_cost', 10, 2)->default(0)->after('extraction_confidence');
            $table->decimal('overhead_cost', 10, 2)->default(0)->after('labor_cost');
            $table->decimal('packaging_cost', 10, 2)->default(0)->after('overhead_cost');
            $table->decimal('selling_price', 10, 2)->nullable()->after('packaging_cost');
        });
    }

    public function down(): void
    {
        Schema::table('recipe_cards', function (Blueprint $table) {
            $table->dropColumn(['labor_cost', 'overhead_cost', 'packaging_cost', 'selling_price']);
        });
    }
};
