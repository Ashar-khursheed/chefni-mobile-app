<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;

class UserSeeder extends Seeder
{
    public function run(): void
    {
        // Content owner — official Chefni recipes and reels belong to this account.
        User::updateOrCreate(
            ['email' => 'rabia@chefni.app'],
            [
                'name' => 'Rabia Nasar',
                'password' => 'password123',
                'role' => 'admin',
                'subscription_tier' => 'restaurant_pro',
                'trial_active' => false,
                'country_code' => 'PK',
            ]
        );

        // Free consumer — sees upgrade prompts and ad slots.
        User::updateOrCreate(
            ['email' => 'user@chefni.app'],
            [
                'name' => 'Home Chef',
                'password' => 'password123',
                'role' => 'user',
                'subscription_tier' => 'free',
                'trial_active' => false,
                'country_code' => 'PK',
            ]
        );

        // Subscriber on trial — unlocks Creator Studio.
        User::updateOrCreate(
            ['email' => 'creator@chefni.app'],
            [
                'name' => 'Zara Hussain',
                'password' => 'password123',
                'role' => 'user',
                'subscription_tier' => 'creator_trial',
                'trial_active' => true,
                'trial_ends_at' => now()->addDays(14),
                'country_code' => 'PK',
            ]
        );
    }
}
