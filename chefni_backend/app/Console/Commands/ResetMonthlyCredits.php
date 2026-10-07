<?php

namespace App\Console\Commands;

use App\Models\User;
use App\Models\VideoCredit;
use App\Services\CreditService;
use Illuminate\Console\Command;

/**
 * Refills Creator balances once a month.
 *
 * Trial accounts are deliberately excluded: their 3 extractions are a total,
 * not a monthly allowance, so resetting them would hand out free credits.
 */
class ResetMonthlyCredits extends Command
{
    protected $signature = 'chefni:reset-credits';

    protected $description = 'Refill monthly video credits for Creator subscribers';

    public function handle(CreditService $credits): int
    {
        $refilled = 0;

        User::query()
            ->where('subscription_tier', 'creator')
            ->where(function ($q) {
                // Only accounts that have not already been refilled this month.
                $q->whereNull('credits_reset_at')
                    ->orWhere('credits_reset_at', '<', now()->startOfMonth());
            })
            ->chunkById(200, function ($users) use ($credits, &$refilled) {
                foreach ($users as $user) {
                    if ($user->trial_active && ! $user->trialHasExpired()) {
                        continue; // Still on trial allowance.
                    }

                    $credits->grantAllowance($user, VideoCredit::REASON_MONTHLY_RESET);
                    $refilled++;
                }
            });

        $this->info("Refilled credits for {$refilled} account(s).");

        return self::SUCCESS;
    }
}
