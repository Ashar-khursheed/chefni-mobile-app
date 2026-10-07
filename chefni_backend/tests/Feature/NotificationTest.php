<?php

namespace Tests\Feature;

use App\Models\InventoryItem;
use App\Models\User;
use App\Models\UserVideo;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

/**
 * Notices are derived from live account state rather than stored, so these
 * tests assert the derivation rules directly: what state produces which
 * notice, and that a clean account produces none.
 */
class NotificationTest extends TestCase
{
    use RefreshDatabase;

    public function test_an_account_with_nothing_notable_has_no_notices(): void
    {
        $user = User::create([
            'name' => 'Quiet Chef',
            'phone' => '+923000000040',
            'subscription_tier' => 'free',
        ]);
        Sanctum::actingAs($user);

        $this->getJson('/api/notifications')->assertOk()->assertJsonCount(0, 'data');
    }

    public function test_a_trial_ending_within_three_days_is_flagged(): void
    {
        $user = User::create([
            'name' => 'Trial Chef',
            'phone' => '+923000000041',
            'subscription_tier' => 'creator_trial',
            'trial_active' => true,
            'trial_ends_at' => now()->addDays(2),
        ]);
        Sanctum::actingAs($user);

        $response = $this->getJson('/api/notifications')->assertOk();
        $this->assertTrue(
            collect($response->json('data'))->contains(fn ($n) => $n['id'] === 'trial_ending')
        );
    }

    public function test_a_trial_ending_in_ten_days_is_not_flagged_yet(): void
    {
        $user = User::create([
            'name' => 'Trial Chef',
            'phone' => '+923000000042',
            'subscription_tier' => 'creator_trial',
            'trial_active' => true,
            'trial_ends_at' => now()->addDays(10),
        ]);
        Sanctum::actingAs($user);

        $response = $this->getJson('/api/notifications')->assertOk();
        $this->assertFalse(
            collect($response->json('data'))->contains(fn ($n) => $n['id'] === 'trial_ending')
        );
    }

    public function test_expiring_inventory_is_flagged(): void
    {
        $user = User::create([
            'name' => 'Stocked Chef',
            'phone' => '+923000000043',
            'subscription_tier' => 'free',
        ]);
        InventoryItem::create([
            'user_id' => $user->id,
            'name' => 'Milk',
            'quantity' => '2',
            'unit' => 'L',
            'expiry_date' => now()->addDays(2),
        ]);
        Sanctum::actingAs($user);

        $response = $this->getJson('/api/notifications')->assertOk();
        $this->assertTrue(
            collect($response->json('data'))->contains(fn ($n) => $n['id'] === 'inventory_expiring')
        );
    }

    public function test_a_recent_failed_video_is_flagged(): void
    {
        $user = User::create([
            'name' => 'Unlucky Chef',
            'phone' => '+923000000044',
            'subscription_tier' => 'free',
        ]);
        UserVideo::create([
            'user_id' => $user->id,
            'title' => 'Biryani take two',
            'status' => UserVideo::STATUS_FAILED,
            'failure_reason' => 'Audio was too quiet to transcribe.',
        ]);
        Sanctum::actingAs($user);

        $response = $this->getJson('/api/notifications')->assertOk();
        $notice = collect($response->json('data'))->first(fn ($n) => $n['type'] === 'video');
        $this->assertNotNull($notice);
        $this->assertSame('Audio was too quiet to transcribe.', $notice['body']);
    }
}
