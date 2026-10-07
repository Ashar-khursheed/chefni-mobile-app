<?php

use App\Models\Store;
use App\Models\User;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Inventory becomes per-location for Restaurant Pro.
 *
 * Existing rows belong to a user but no store, so every account gets a default
 * "Main Kitchen" and its stock is moved there — nothing disappears from a
 * pantry that was already in use.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('stores', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('name');
            $table->string('address')->nullable();
            $table->boolean('is_default')->default(false);
            $table->timestamps();
        });

        Schema::table('inventory_items', function (Blueprint $table) {
            $table->foreignId('store_id')->nullable()->after('user_id')
                ->constrained()->nullOnDelete();
            $table->decimal('unit_cost', 10, 2)->nullable()->after('unit');
            $table->decimal('min_threshold', 10, 2)->default(0)->after('unit_cost');
        });

        // Backfill: one default store per user, and point their stock at it.
        User::query()->select('id')->chunkById(200, function ($users) {
            foreach ($users as $user) {
                $store = Store::create([
                    'user_id' => $user->id,
                    'name' => 'Main Kitchen',
                    'is_default' => true,
                ]);

                \DB::table('inventory_items')
                    ->where('user_id', $user->id)
                    ->whereNull('store_id')
                    ->update(['store_id' => $store->id]);
            }
        });
    }

    public function down(): void
    {
        Schema::table('inventory_items', function (Blueprint $table) {
            $table->dropConstrainedForeignId('store_id');
            $table->dropColumn(['unit_cost', 'min_threshold']);
        });

        Schema::dropIfExists('stores');
    }
};
