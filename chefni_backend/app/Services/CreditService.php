<?php

namespace App\Services;

use App\Models\User;
use App\Models\VideoCredit;
use Illuminate\Support\Facades\DB;
use RuntimeException;

/**
 * The one place credits move.
 *
 * Balances are held on `users` for cheap reads, but every change is written as
 * a ledger row inside the same transaction, so the two cannot drift.
 */
class CreditService
{
    /** Extractions granted per tier. Null means the tier is uncapped. */
    public const TRIAL_ALLOWANCE = 3;
    public const CREATOR_MONTHLY_ALLOWANCE = 10;

    /**
     * Credits a tier is entitled to per period, or null when unlimited.
     */
    public function allowanceFor(User $user): ?int
    {
        if ($user->subscription_tier === 'restaurant_pro') {
            return null;
        }

        if ($user->trial_active && ! $user->trialHasExpired()) {
            return self::TRIAL_ALLOWANCE;
        }

        return $user->subscription_tier === 'creator'
            ? self::CREATOR_MONTHLY_ALLOWANCE
            : 0;
    }

    public function isUnlimited(User $user): bool
    {
        return $this->allowanceFor($user) === null;
    }

    /**
     * Set the balance to the tier's allowance. Used at sign-up and by the
     * monthly reset; both are grants rather than adjustments, because a reset
     * replaces the balance instead of adding to it.
     */
    public function grantAllowance(User $user, string $reason = VideoCredit::REASON_GRANT): void
    {
        $allowance = $this->allowanceFor($user);

        if ($allowance === null) {
            return; // Unlimited tiers keep no balance.
        }

        DB::transaction(function () use ($user, $allowance, $reason) {
            $delta = $allowance - $user->video_credits_balance;

            $user->forceFill([
                'video_credits_balance' => $allowance,
                'credits_reset_at' => now(),
            ])->save();

            VideoCredit::create([
                'user_id' => $user->id,
                'delta' => $delta,
                'reason' => $reason,
                'balance_after' => $allowance,
            ]);
        });
    }

    /**
     * Take one credit for an upload.
     *
     * @throws RuntimeException when the balance is empty — the caller turns
     *                          that into a 402 with an upgrade prompt.
     */
    public function consume(User $user, ?int $videoId = null): void
    {
        if ($this->isUnlimited($user)) {
            return;
        }

        DB::transaction(function () use ($user, $videoId) {
            // Lock the row so two uploads cannot spend the same last credit.
            $fresh = User::whereKey($user->id)->lockForUpdate()->first();

            if ($fresh->video_credits_balance < 1) {
                throw new RuntimeException('No video credits remaining.');
            }

            $balance = $fresh->video_credits_balance - 1;
            $fresh->forceFill(['video_credits_balance' => $balance])->save();

            VideoCredit::create([
                'user_id' => $fresh->id,
                'delta' => -1,
                'reason' => VideoCredit::REASON_CONSUME,
                'balance_after' => $balance,
                'user_video_id' => $videoId,
            ]);

            $user->video_credits_balance = $balance;
        });
    }

    /**
     * Give a credit back when processing failed. A user should not pay for an
     * encode that never produced a reel.
     */
    public function refund(User $user, ?int $videoId = null): void
    {
        if ($this->isUnlimited($user)) {
            return;
        }

        DB::transaction(function () use ($user, $videoId) {
            $fresh = User::whereKey($user->id)->lockForUpdate()->first();

            // Never refund past the allowance — a repeated refund for the same
            // video would otherwise mint credits.
            $allowance = $this->allowanceFor($fresh) ?? 0;
            if ($fresh->video_credits_balance >= $allowance) {
                return;
            }

            $balance = $fresh->video_credits_balance + 1;
            $fresh->forceFill(['video_credits_balance' => $balance])->save();

            VideoCredit::create([
                'user_id' => $fresh->id,
                'delta' => 1,
                'reason' => VideoCredit::REASON_REFUND,
                'balance_after' => $balance,
                'user_video_id' => $videoId,
            ]);

            $user->video_credits_balance = $balance;
        });
    }
}
