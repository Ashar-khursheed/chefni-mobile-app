<?php

namespace Tests\Feature;

use App\Models\RegionalPrice;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

/**
 * Geo-pricing used to be a hardcoded matrix with a broken admin-update
 * endpoint (it pointed at a controller method that didn't exist). These
 * pin the fixed behaviour: pricing reads from the DB, and admin edits
 * actually persist.
 */
class GeoPricingTest extends TestCase
{
    use RefreshDatabase;

    // PK/AE/US are seeded by migration — the geo-pricing endpoint is on the
    // live paywall, so a fresh deploy must never 404 with nothing configured.
    // These tests build on that baseline rather than re-seeding it.

    public function test_public_pricing_lookup_reads_from_the_database(): void
    {
        $response = $this->getJson('/api/geo/pricing?country=PK')
            ->assertOk()
            ->assertJsonPath('pricing.country_code', 'PK')
            ->assertJsonPath('pricing.symbol', 'Rs.');

        $this->assertEquals(1390.0, $response->json('pricing.creator_monthly'));
    }

    public function test_an_unconfigured_region_falls_back_to_us(): void
    {
        $this->getJson('/api/geo/pricing?country=ZZ')
            ->assertOk()
            ->assertJsonPath('pricing.country_code', 'US');
    }

    public function test_pricing_lookup_404s_when_the_table_is_empty(): void
    {
        RegionalPrice::query()->delete();

        $this->getJson('/api/geo/pricing?country=PK')->assertStatus(404);
    }

    public function test_a_non_admin_cannot_update_pricing(): void
    {
        $user = User::create(['name' => 'User', 'phone' => '+923000000060']);
        Sanctum::actingAs($user);

        $this->postJson('/api/admin/geo-pricing', [
            'country_code' => 'PK',
            'creator_monthly_price' => 1500,
            'creator_yearly_price' => 12500,
            'pro_monthly_price' => 3600,
            'pro_yearly_price' => 33400,
        ])->assertStatus(403);
    }

    public function test_an_admin_update_actually_persists(): void
    {
        $admin = User::create(['name' => 'Admin', 'phone' => '+923000000061', 'role' => 'admin']);
        Sanctum::actingAs($admin);

        $response = $this->postJson('/api/admin/geo-pricing', [
            'country_code' => 'PK',
            'creator_monthly_price' => 1500,
            'creator_yearly_price' => 13500,
            'pro_monthly_price' => 3800,
            'pro_yearly_price' => 35000,
        ])->assertOk();
        $this->assertEquals(1500.0, $response->json('data.creator_monthly'));

        $this->assertEquals(1500, RegionalPrice::where('country_code', 'PK')->value('creator_monthly_price'));

        // The public endpoint must reflect the edit immediately.
        $follow = $this->getJson('/api/geo/pricing?country=PK');
        $this->assertEquals(1500.0, $follow->json('pricing.creator_monthly'));
    }

    public function test_admin_can_add_a_brand_new_region(): void
    {
        $admin = User::create(['name' => 'Admin', 'phone' => '+923000000062', 'role' => 'admin']);
        Sanctum::actingAs($admin);

        $this->postJson('/api/admin/geo-pricing', [
            'country_code' => 'GB',
            'country_name' => 'United Kingdom',
            'currency_code' => 'GBP',
            'creator_monthly_price' => 3.99,
            'creator_yearly_price' => 39.99,
            'pro_monthly_price' => 9.99,
            'pro_yearly_price' => 99.99,
        ])->assertOk()->assertJsonPath('data.country_code', 'GB');

        // 3 seeded regions plus the new one.
        $this->getJson('/api/admin/geo-pricing')->assertJsonCount(4, 'data');
    }
}
