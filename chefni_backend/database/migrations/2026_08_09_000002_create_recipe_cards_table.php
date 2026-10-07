<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('recipe_cards', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->foreignId('user_video_id')->nullable()->constrained()->onDelete('cascade');

            $table->string('title');
            $table->text('summary')->nullable();
            $table->string('cuisine')->nullable();
            $table->unsignedSmallInteger('prep_time_mins')->nullable();
            $table->unsignedSmallInteger('cook_time_mins')->nullable();
            $table->unsignedSmallInteger('servings')->default(4);
            $table->json('steps')->nullable();

            // Currency the AI priced the ingredients in, derived from the
            // account's region at extraction time.
            $table->string('currency', 5)->default('PKR');

            // Every cost starts as an AI guess. The flag flips once the user
            // overrides any row, so the UI can stop calling the total an estimate.
            $table->boolean('cost_is_ai_estimate')->default(true);
            $table->boolean('user_edited_cost')->default(false);

            // What the model reported about its own confidence, so the card can
            // warn when the transcript was thin.
            $table->string('extraction_confidence')->nullable();
            $table->timestamps();

            $table->index(['user_id', 'created_at']);
        });

        Schema::create('recipe_card_ingredients', function (Blueprint $table) {
            $table->id();
            $table->foreignId('recipe_card_id')->constrained()->onDelete('cascade');

            $table->string('name');
            $table->float('quantity')->default(0);
            $table->string('unit')->default('g');
            $table->string('category')->nullable();

            // AI's original guess is kept alongside the user's override so an
            // edit can always be reverted and the two can be compared.
            $table->decimal('ai_estimated_cost', 10, 2)->nullable();
            $table->decimal('user_cost', 10, 2)->nullable();

            $table->unsignedSmallInteger('sort_order')->default(0);
            $table->timestamps();

            $table->index('recipe_card_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('recipe_card_ingredients');
        Schema::dropIfExists('recipe_cards');
    }
};
