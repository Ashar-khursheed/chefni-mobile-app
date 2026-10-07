<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Gates creator-only surfaces. Checkout starts a 14-day trial and sets the
 * tier, but nothing walks the clock back when it runs out — this is what
 * actually stops an expired trial from behaving like a paid account.
 */
class EnsureCreatorAccess
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if (! $user) {
            return response()->json([
                'success' => false,
                'message' => 'Authentication required.',
            ], 401);
        }

        if ($user->trialHasExpired()) {
            // Settle the record so the client's next session read reflects it.
            $user->update([
                'subscription_tier' => 'free',
                'trial_active' => false,
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Your 14-day trial has ended. Subscribe to keep using creator tools.',
                'trial_expired' => true,
                'upgrade_required' => true,
            ], 402);
        }

        if (! $user->hasCreatorTools()) {
            return response()->json([
                'success' => false,
                'message' => 'This feature is part of the Creator plan.',
                'upgrade_required' => true,
            ], 402);
        }

        return $next($request);
    }
}
