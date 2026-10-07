<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('user_videos', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->string('title');

            // queued → compressing → transcribing → extracting → ready | failed
            $table->string('status')->default('queued');
            $table->text('failure_reason')->nullable();

            // Raw upload is deleted once the reel is produced; the column keeps
            // the last known path so a retry can tell whether the source is gone.
            $table->string('raw_path')->nullable();
            $table->string('reel_path')->nullable();
            $table->string('thumbnail_path')->nullable();

            $table->unsignedBigInteger('original_size_bytes')->nullable();
            $table->unsignedBigInteger('reel_size_bytes')->nullable();
            $table->float('original_duration_sec')->nullable();
            $table->float('reel_duration_sec')->nullable();
            $table->string('resolution')->nullable();

            $table->longText('transcript')->nullable();
            $table->boolean('is_private')->default(true);

            $table->timestamp('processing_started_at')->nullable();
            $table->timestamp('processing_finished_at')->nullable();
            $table->timestamps();

            $table->index(['user_id', 'status']);
            $table->index(['user_id', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('user_videos');
    }
};
