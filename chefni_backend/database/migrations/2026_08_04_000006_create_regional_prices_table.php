<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('regional_prices', function (Blueprint $table) {
            $table->id();
            $table->string('country_code', 5)->unique();
            $table->string('country_name');
            $table->string('currency_code', 5);
            $table->double('creator_monthly_price');
            $table->double('creator_yearly_price');
            $table->double('pro_monthly_price');
            $table->double('pro_yearly_price');
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('regional_prices');
    }
};
