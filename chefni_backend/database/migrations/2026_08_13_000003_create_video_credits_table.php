<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Credits become a ledger rather than a COUNT of videos.
 *
 * The old derivation could not express the spec's tiers (3 total on trial vs
 * 10 per month on Creator), and it charged the user for encodes that failed.
 * Every movement is now a row, and the balance on `users` is the fast read.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('video_credits', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->integer('delta');                 // negative consumes
            $table->string('reason');                 // grant|consume|refund|monthly_reset
            $table->integer('balance_after');
            $table->foreignId('user_video_id')->nullable()
                ->constrained('user_videos')->nullOnDelete();
            $table->timestamps();

            $table->index(['user_id', 'created_at']);
        });

        Schema::table('users', function (Blueprint $table) {
            $table->integer('video_credits_balance')->default(0)->after('trial_ends_at');
            $table->timestamp('credits_reset_at')->nullable()->after('video_credits_balance');
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['video_credits_balance', 'credits_reset_at']);
        });

        Schema::dropIfExists('video_credits');
    }
};
