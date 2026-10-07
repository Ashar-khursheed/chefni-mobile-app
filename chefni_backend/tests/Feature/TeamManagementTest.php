<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

/**
 * Team is a Restaurant Pro-only roster capped at 5 people. The rules worth
 * pinning down: lower tiers are refused, the cap is enforced, and an account
 * can never touch another account's staff.
 */
class TeamManagementTest extends TestCase
{
    use RefreshDatabase;

    private function restaurantProUser(): User
    {
        return User::create([
            'name' => 'Owner Chef',
            'phone' => '+923000000010',
            'subscription_tier' => 'restaurant_pro',
        ]);
    }

    public function test_free_tier_is_refused(): void
    {
        $user = User::create([
            'name' => 'Free Chef',
            'phone' => '+923000000011',
            'subscription_tier' => 'free',
        ]);
        Sanctum::actingAs($user);

        $this->getJson('/api/team')->assertStatus(402);
    }

    public function test_creator_tier_is_also_refused(): void
    {
        $user = User::create([
            'name' => 'Creator Chef',
            'phone' => '+923000000012',
            'subscription_tier' => 'creator',
        ]);
        Sanctum::actingAs($user);

        $this->getJson('/api/team')->assertStatus(402);
    }

    public function test_restaurant_pro_can_add_and_list_staff(): void
    {
        Sanctum::actingAs($this->restaurantProUser());

        $this->postJson('/api/team', ['name' => 'Ali', 'role' => 'chef'])
            ->assertCreated()
            ->assertJsonPath('data.name', 'Ali')
            ->assertJsonPath('data.role', 'chef');

        $this->getJson('/api/team')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('max_staff', 5);
    }

    public function test_a_sixth_staff_member_is_refused(): void
    {
        $user = $this->restaurantProUser();
        Sanctum::actingAs($user);

        for ($i = 0; $i < 5; $i++) {
            $this->postJson('/api/team', ['name' => "Staff $i", 'role' => 'staff'])
                ->assertCreated();
        }

        $this->postJson('/api/team', ['name' => 'One too many', 'role' => 'staff'])
            ->assertStatus(422);
    }

    public function test_an_invalid_role_is_rejected(): void
    {
        Sanctum::actingAs($this->restaurantProUser());

        $this->postJson('/api/team', ['name' => 'Ali', 'role' => 'owner'])
            ->assertStatus(422)
            ->assertJsonValidationErrors('role');
    }

    public function test_an_account_cannot_edit_or_delete_another_accounts_staff(): void
    {
        $owner = $this->restaurantProUser();
        Sanctum::actingAs($owner);
        $staffId = $this->postJson('/api/team', ['name' => 'Ali', 'role' => 'chef'])
            ->json('data.id');

        $other = User::create([
            'name' => 'Other Owner',
            'phone' => '+923000000013',
            'subscription_tier' => 'restaurant_pro',
        ]);
        Sanctum::actingAs($other);

        $this->patchJson("/api/team/{$staffId}", ['name' => 'Hijacked'])->assertNotFound();
        $this->deleteJson("/api/team/{$staffId}")->assertNotFound();
    }

    public function test_staff_can_be_deactivated_without_deleting_them(): void
    {
        Sanctum::actingAs($this->restaurantProUser());
        $staffId = $this->postJson('/api/team', ['name' => 'Ali', 'role' => 'chef'])
            ->json('data.id');

        $this->patchJson("/api/team/{$staffId}", ['is_active' => false])
            ->assertOk()
            ->assertJsonPath('data.is_active', false);
    }
}
