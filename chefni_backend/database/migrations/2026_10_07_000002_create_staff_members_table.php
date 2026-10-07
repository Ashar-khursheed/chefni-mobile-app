<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Restaurant Pro's kitchen team: up to 5 people per account, scoped to a
 * location. Staff do not get their own login — the owner's app shows them a
 * stripped-down "staff view" (steps and timers, no costs) rather than a
 * separate authenticated surface, which keeps this a simple roster rather
 * than a second auth system.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('staff_members', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('store_id')->nullable()->constrained()->nullOnDelete();

            $table->string('name');
            $table->string('role'); // manager | chef | staff
            $table->string('phone')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();

            $table->index(['user_id', 'is_active']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('staff_members');
    }
};
