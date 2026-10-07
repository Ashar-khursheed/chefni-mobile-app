<?php

namespace App\Http\Controllers;

use App\Models\UserVideo;
use Illuminate\Http\Request;

/**
 * Notices are derived from the account's current state on every request
 * rather than stored — credit resets, trial/expiry alerts and low-stock
 * warnings are all true facts right now, not events that need a delivery log.
 * This keeps the feature real (not a fake mailbox) without needing a push
 * backend behind it.
 */
class NotificationController extends Controller
{
    public function index(Request $request)
    {
        $user = $request->user();
        $notices = [];

        $trialDays = $user->trial_active && $user->trial_ends_at
            ? max(0, (int) now()->startOfDay()->diffInDays($user->trial_ends_at, false))
            : null;

        if ($trialDays !== null && $trialDays <= 3) {
            $notices[] = [
                'id' => 'trial_ending',
                'type' => 'subscription',
                'severity' => $trialDays === 0 ? 'high' : 'medium',
                'title' => $trialDays === 0 ? 'Your trial ends today' : "Your trial ends in {$trialDays} day" . ($trialDays === 1 ? '' : 's'),
                'body' => 'Subscribe to keep uploading videos and generating recipe cards without interruption.',
                'created_at' => now()->toIso8601String(),
            ];
        }

        if (! $user->isAdmin() && $user->subscription_tier !== 'free') {
            $remaining = $user->uploadQuotaRemaining();
            if ($remaining !== null && $remaining <= 1) {
                $notices[] = [
                    'id' => 'credits_low',
                    'type' => 'credits',
                    'severity' => $remaining === 0 ? 'high' : 'medium',
                    'title' => $remaining === 0
                        ? 'No video credits left this period'
                        : '1 video credit left this period',
                    'body' => 'Your credit balance resets at the start of your next billing period.',
                    'created_at' => now()->toIso8601String(),
                ];
            }
        }

        $expiringItems = $user->inventoryItems()->get()->filter->isExpiringSoon();
        if ($expiringItems->isNotEmpty()) {
            $notices[] = [
                'id' => 'inventory_expiring',
                'type' => 'inventory',
                'severity' => 'medium',
                'title' => $expiringItems->count() === 1
                    ? "{$expiringItems->first()->name} is expiring soon"
                    : "{$expiringItems->count()} pantry items are expiring soon",
                'body' => 'Check your inventory before stock goes to waste.',
                'created_at' => now()->toIso8601String(),
            ];
        }

        $lowStockItems = $user->inventoryItems()->get()->filter->isLowStock();
        if ($lowStockItems->isNotEmpty()) {
            $notices[] = [
                'id' => 'inventory_low_stock',
                'type' => 'inventory',
                'severity' => 'low',
                'title' => $lowStockItems->count() === 1
                    ? "{$lowStockItems->first()->name} is running low"
                    : "{$lowStockItems->count()} pantry items are running low",
                'body' => 'Add these to your shopping list before you run out.',
                'created_at' => now()->toIso8601String(),
            ];
        }

        $recentFailure = $user->videos()
            ->where('status', UserVideo::STATUS_FAILED)
            ->latest()
            ->first();
        if ($recentFailure && $recentFailure->created_at?->gt(now()->subDays(7))) {
            $notices[] = [
                'id' => 'video_failed_' . $recentFailure->id,
                'type' => 'video',
                'severity' => 'medium',
                'title' => "\"{$recentFailure->title}\" couldn't be processed",
                'body' => $recentFailure->failure_reason ?? 'Try uploading it again, or a different clip.',
                'created_at' => $recentFailure->created_at->toIso8601String(),
            ];
        }

        return response()->json([
            'success' => true,
            'data' => $notices,
        ]);
    }
}
