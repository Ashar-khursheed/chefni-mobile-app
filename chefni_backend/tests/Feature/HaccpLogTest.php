<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class HaccpLogTest extends TestCase
{
    use RefreshDatabase;

    private function restaurantProUser(): User
    {
        return User::create([
            'name' => 'Owner Chef',
            'phone' => '+923000000020',
            'subscription_tier' => 'restaurant_pro',
        ]);
    }

    public function test_free_tier_cannot_log_or_read_haccp_entries(): void
    {
        $user = User::create([
            'name' => 'Free Chef',
            'phone' => '+923000000021',
            'subscription_tier' => 'free',
        ]);
        Sanctum::actingAs($user);

        $this->getJson('/api/haccp-logs')->assertStatus(402);
    }

    public function test_a_temperature_entry_can_be_logged_and_read_back(): void
    {
        Sanctum::actingAs($this->restaurantProUser());

        $this->postJson('/api/haccp-logs', [
            'type' => 'temperature',
            'label' => 'Walk-in fridge',
            'value' => '4°C',
            'status' => 'pass',
            'logged_by' => 'Ali',
        ])->assertCreated()
            ->assertJsonPath('data.label', 'Walk-in fridge')
            ->assertJsonPath('data.status', 'pass');

        $this->getJson('/api/haccp-logs')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('fail_count', 0);
    }

    public function test_failed_checks_are_counted_for_the_inspection_summary(): void
    {
        Sanctum::actingAs($this->restaurantProUser());

        $this->postJson('/api/haccp-logs', [
            'type' => 'hygiene',
            'label' => 'Handwashing station',
            'status' => 'fail',
            'notes' => 'Soap dispenser empty',
        ])->assertCreated();

        $this->getJson('/api/haccp-logs')->assertJsonPath('fail_count', 1);
    }

    public function test_an_invalid_status_is_rejected(): void
    {
        Sanctum::actingAs($this->restaurantProUser());

        $this->postJson('/api/haccp-logs', [
            'type' => 'hygiene',
            'label' => 'Handwashing station',
            'status' => 'maybe',
        ])->assertStatus(422)->assertJsonValidationErrors('status');
    }

    public function test_logs_are_scoped_to_the_owning_account(): void
    {
        $a = $this->restaurantProUser();
        Sanctum::actingAs($a);
        $this->postJson('/api/haccp-logs', [
            'type' => 'temperature', 'label' => 'Freezer', 'status' => 'pass',
        ])->assertCreated();

        $b = User::create([
            'name' => 'Other Owner',
            'phone' => '+923000000022',
            'subscription_tier' => 'restaurant_pro',
        ]);
        Sanctum::actingAs($b);

        $this->getJson('/api/haccp-logs')->assertOk()->assertJsonCount(0, 'data');
    }
}
