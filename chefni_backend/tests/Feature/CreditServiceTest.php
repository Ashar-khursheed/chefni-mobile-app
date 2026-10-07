<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\VideoCredit;
use App\Services\CreditService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use RuntimeException;
use Tests\TestCase;

/**
 * Credits are the spending limit on the product's only expensive operation, so
 * the rules here are worth pinning down: a tier's allowance, what happens when
 * it runs out, and that a failed encode does not cost the user anything.
 */
class CreditServiceTest extends TestCase
{
    use RefreshDatabase;

    private function credits(): CreditService
    {
        return app(CreditService::class);
    }

    private function trialUser(): User
    {
        return User::create([
            'name' => 'Trial Chef',
            'phone' => '+923000000001',
            'subscription_tier' => 'creator_trial',
            'trial_active' => true,
            'trial_ends_at' => now()->addDays(14),
        ]);
    }

    public function test_trial_accounts_receive_three_extractions(): void
    {
        $user = $this->trialUser();
        $this->credits()->grantAllowance($user);

        $this->assertSame(3, $user->fresh()->video_credits_balance);
        $this->assertSame(3, $user->fresh()->uploadQuotaRemaining());
    }

    public function test_consuming_reduces_the_balance_and_writes_a_ledger_row(): void
    {
        $user = $this->trialUser();
        $this->credits()->grantAllowance($user);

        $this->credits()->consume($user->fresh());

        $this->assertSame(2, $user->fresh()->video_credits_balance);
        $this->assertDatabaseHas('video_credits', [
            'user_id' => $user->id,
            'delta' => -1,
            'reason' => VideoCredit::REASON_CONSUME,
            'balance_after' => 2,
        ]);
    }

    public function test_an_exhausted_balance_refuses_further_uploads(): void
    {
        $user = $this->trialUser();
        $this->credits()->grantAllowance($user);

        for ($i = 0; $i < 3; $i++) {
            $this->credits()->consume($user->fresh());
        }

        $this->assertFalse($user->fresh()->canUpload());

        $this->expectException(RuntimeException::class);
        $this->credits()->consume($user->fresh());
    }

    public function test_a_refund_returns_the_credit_spent_on_a_failed_encode(): void
    {
        $user = $this->trialUser();
        $this->credits()->grantAllowance($user);
        $this->credits()->consume($user->fresh());

        $this->credits()->refund($user->fresh());

        $this->assertSame(3, $user->fresh()->video_credits_balance);
    }

    public function test_refunds_cannot_push_the_balance_past_the_allowance(): void
    {
        $user = $this->trialUser();
        $this->credits()->grantAllowance($user);

        // Repeated refunds must not mint credits the tier never granted.
        for ($i = 0; $i < 5; $i++) {
            $this->credits()->refund($user->fresh());
        }

        $this->assertSame(3, $user->fresh()->video_credits_balance);
    }

    public function test_restaurant_pro_is_uncapped_and_keeps_no_balance(): void
    {
        $user = User::create([
            'name' => 'Pro Kitchen',
            'phone' => '+923000000002',
            'subscription_tier' => 'restaurant_pro',
            'trial_active' => false,
        ]);

        $this->assertTrue($this->credits()->isUnlimited($user));
        $this->assertNull($user->uploadQuotaRemaining());

        // Consuming on an uncapped tier is a no-op rather than an error.
        $this->credits()->consume($user);
        $this->assertSame(0, $user->fresh()->video_credits_balance);
    }

    public function test_creator_tier_receives_ten_extractions_per_month(): void
    {
        $user = User::create([
            'name' => 'Paid Creator',
            'phone' => '+923000000003',
            'subscription_tier' => 'creator',
            'trial_active' => false,
        ]);

        $this->credits()->grantAllowance($user);

        $this->assertSame(10, $user->fresh()->video_credits_balance);
    }
}
