<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Per-user state the app writes back: shopping list, saved recipes and
 * reel likes. Without these, every interaction is lost on reload.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('shopping_list_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->foreignId('recipe_id')->nullable()->constrained()->onDelete('set null');
            $table->string('name');
            $table->string('quantity')->default('');
            $table->string('category')->default('Other');
            $table->boolean('is_checked')->default(false);
            $table->timestamps();

            $table->index(['user_id', 'is_checked']);
        });

        Schema::create('saved_recipes', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->foreignId('recipe_id')->constrained()->onDelete('cascade');
            $table->timestamps();

            $table->unique(['user_id', 'recipe_id']);
        });

        Schema::create('reel_likes', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->foreignId('reel_id')->constrained()->onDelete('cascade');
            $table->timestamps();

            $table->unique(['user_id', 'reel_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('reel_likes');
        Schema::dropIfExists('saved_recipes');
        Schema::dropIfExists('shopping_list_items');
    }
};
