<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('subscriptions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->string('tier');                       // creator, restaurant_pro
            $table->string('billing_cycle')->default('monthly');
            $table->string('payment_method');             // card, jazzcash, easypaisa, bank
            $table->string('status')->default('trialing'); // trialing, active, cancelled, pending
            $table->string('price_label')->default('');
            $table->string('country_code', 5)->default('PK');
            $table->timestamp('trial_ends_at')->nullable();
            $table->timestamp('current_period_ends_at')->nullable();
            $table->timestamp('cancelled_at')->nullable();
            $table->timestamps();

            $table->index(['user_id', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('subscriptions');
    }
};
