<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class BrandingTest extends TestCase
{
    use RefreshDatabase;

    private function restaurantProUser(): User
    {
        return User::create([
            'name' => 'Owner Chef',
            'phone' => '+923000000030',
            'subscription_tier' => 'restaurant_pro',
        ]);
    }

    public function test_free_tier_cannot_reach_branding(): void
    {
        $user = User::create([
            'name' => 'Free Chef',
            'phone' => '+923000000031',
            'subscription_tier' => 'free',
        ]);
        Sanctum::actingAs($user);

        $this->getJson('/api/branding')->assertStatus(402);
    }

    public function test_white_label_cannot_be_turned_on_without_a_logo(): void
    {
        Sanctum::actingAs($this->restaurantProUser());

        $this->patchJson('/api/branding', [
            'white_label_enabled' => true,
        ])->assertStatus(422);
    }

    public function test_setting_a_logo_and_enabling_white_label_persists(): void
    {
        Sanctum::actingAs($this->restaurantProUser());

        $this->patchJson('/api/branding', [
            'brand_name' => 'Karahi House',
            'brand_logo_url' => 'https://example.com/logo.png',
            'white_label_enabled' => true,
        ])->assertOk()
            ->assertJsonPath('data.brand_name', 'Karahi House')
            ->assertJsonPath('data.white_label_enabled', true);

        $this->getJson('/api/branding')
            ->assertOk()
            ->assertJsonPath('data.white_label_enabled', true);
    }

    public function test_white_label_can_be_turned_back_off(): void
    {
        $user = $this->restaurantProUser();
        Sanctum::actingAs($user);

        $this->patchJson('/api/branding', [
            'brand_logo_url' => 'https://example.com/logo.png',
            'white_label_enabled' => true,
        ])->assertOk();

        $this->patchJson('/api/branding', [
            'white_label_enabled' => false,
        ])->assertOk()->assertJsonPath('data.white_label_enabled', false);
    }
}
