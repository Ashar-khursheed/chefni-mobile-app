<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Adds the recipe attributes the mobile app renders (cuisine filters, difficulty
 * and calorie badges, tag pills, hero media) which the original table lacked.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('recipes', function (Blueprint $table) {
            $table->string('slug')->nullable()->unique()->after('id');
            $table->string('cuisine')->default('General')->after('title');
            $table->string('difficulty')->default('Easy')->after('cuisine');
            $table->integer('calories')->default(0)->after('difficulty');
            $table->json('tags')->nullable()->after('calories');
            $table->string('hero_image_url')->nullable()->after('tags');
            $table->integer('likes_count')->default(0)->after('hero_image_url');
            $table->integer('comments_count')->default(0)->after('likes_count');
            $table->boolean('is_published')->default(true)->after('is_official');
        });

        Schema::create('recipe_steps', function (Blueprint $table) {
            $table->id();
            $table->foreignId('recipe_id')->constrained()->onDelete('cascade');
            $table->unsignedInteger('position');
            $table->text('instruction');
            $table->timestamps();

            $table->unique(['recipe_id', 'position']);
        });

        // Ingredients are rendered as free-text lines ("1kg beef shank, bone-in"),
        // so keep the raw line alongside the parsed quantity used for costing.
        Schema::table('ingredients', function (Blueprint $table) {
            $table->string('raw_line')->nullable()->after('recipe_id');
            $table->unsignedInteger('position')->default(0)->after('raw_line');
        });
    }

    public function down(): void
    {
        Schema::table('ingredients', function (Blueprint $table) {
            $table->dropColumn(['raw_line', 'position']);
        });

        Schema::dropIfExists('recipe_steps');

        Schema::table('recipes', function (Blueprint $table) {
            $table->dropColumn([
                'slug', 'cuisine', 'difficulty', 'calories', 'tags',
                'hero_image_url', 'likes_count', 'comments_count', 'is_published',
            ]);
        });
    }
};
