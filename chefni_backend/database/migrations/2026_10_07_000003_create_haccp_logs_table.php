<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Digital HACCP checklist entries — temperature and hygiene checks a
 * Restaurant Pro kitchen logs for health-inspection records.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('haccp_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('store_id')->nullable()->constrained()->nullOnDelete();

            $table->string('type'); // temperature | hygiene
            $table->string('label'); // e.g. "Walk-in fridge", "Handwashing station"
            $table->string('value')->nullable(); // e.g. "4°C", "Pass"
            $table->string('status'); // pass | warning | fail
            $table->string('logged_by')->nullable();
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->index(['user_id', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('haccp_logs');
    }
};
