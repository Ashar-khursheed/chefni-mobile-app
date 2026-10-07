<?php

namespace App\Http\Controllers;

use App\Models\Subscription;
use App\Services\CreditService;
use Illuminate\Http\Request;

class SubscriptionController extends Controller
{
    /** Region-specific pricing surfaced by the paywall. */
    private const PRICING = [
        'PK' => [
            'creator' => ['monthly' => 'Rs. 1,390 / mo', 'yearly' => 'Rs. 12,500 / yr'],
            'restaurant_pro' => ['monthly' => 'Rs. 3,600 / mo', 'yearly' => 'Rs. 33,400 / yr'],
        ],
        'AE' => [
            'creator' => ['monthly' => 'AED 19.99 / mo', 'yearly' => 'AED 179.99 / yr'],
            'restaurant_pro' => ['monthly' => 'AED 49.99 / mo', 'yearly' => 'AED 449.99 / yr'],
        ],
        'US' => [
            'creator' => ['monthly' => '$4.99 / mo', 'yearly' => '$44.99 / yr'],
            'restaurant_pro' => ['monthly' => '$12.99 / mo', 'yearly' => '$119.99 / yr'],
        ],
    ];

    private const FEATURES = [
        'free' => [
            '2 uploads / month',
            'Basic recipe extraction',
            'Basic reel generation',
            'Inventory logging',
        ],
        'creator' => [
            'Unlimited uploads',
            'Advanced AI reel generation',
            'One-click social publishing',
            'Recipe scaling & shopping lists',
            'Inventory tracking & costing',
            'Analytics dashboard',
        ],
        'restaurant_pro' => [
            'Everything in Creator',
            'Team access, multi-location',
            'Advanced costing & HACCP',
            'Advanced analytics',
            'Priority support',
        ],
    ];

    public function plans(Request $request)
    {
        $region = strtoupper($request->query('region', 'PK'));
        $pricing = self::PRICING[$region] ?? self::PRICING['PK'];

        $tiers = [
            [
                'tier' => 'free',
                'name' => 'Free',
                'monthly' => 'Free',
                'yearly' => 'Free',
                'badge' => false,
                'features' => self::FEATURES['free'],
            ],
            [
                'tier' => 'creator',
                'name' => 'Creator',
                'monthly' => $pricing['creator']['monthly'],
                'yearly' => $pricing['creator']['yearly'],
                'badge' => true,
                'features' => self::FEATURES['creator'],
            ],
            [
                'tier' => 'restaurant_pro',
                'name' => 'Restaurant Pro',
                'monthly' => $pricing['restaurant_pro']['monthly'],
                'yearly' => $pricing['restaurant_pro']['yearly'],
                'badge' => false,
                'features' => self::FEATURES['restaurant_pro'],
            ],
        ];

        return response()->json([
            'success' => true,
            'region' => $region,
            'data' => $tiers,
        ]);
    }

    /**
     * Start a trial subscription and move the account onto the tier, so the
     * app's creator tooling unlocks on the next session read.
     *
     * NOTE: no payment gateway is called here — no charge is attempted and no
     * card data is stored. Wiring Stripe/JazzCash/EasyPaisa is a separate
     * integration; this records the intent and starts the 14-day trial.
     */
    public function checkout(Request $request)
    {
        $data = $request->validate([
            'tier' => 'required|in:creator,restaurant_pro',
            'billing_cycle' => 'required|in:monthly,yearly',
            'payment_method' => 'required|in:card,jazzcash,easypaisa,bank',
            'region' => 'nullable|string|max:5',
        ]);

        $user = $request->user();
        $region = strtoupper($data['region'] ?? $user->country_code ?? 'PK');
        $pricing = self::PRICING[$region] ?? self::PRICING['PK'];
        $priceLabel = $pricing[$data['tier']][$data['billing_cycle']];

        // A trial is once per account. Without this, calling checkout again
        // hands out a fresh 14 days — and a fresh credit allowance — forever.
        $hadTrial = $user->subscriptions()->whereNotNull('trial_ends_at')->exists();
        $trialEndsAt = $hadTrial ? null : now()->addDays(14);

        // Bank transfer clears out of band, so it stays pending until confirmed.
        $status = $data['payment_method'] === 'bank'
            ? 'pending'
            : ($trialEndsAt ? 'trialing' : 'active');

        $periodEndsAt = $trialEndsAt ?? now()->addMonth();

        $subscription = Subscription::create([
            'user_id' => $user->id,
            'tier' => $data['tier'],
            'billing_cycle' => $data['billing_cycle'],
            'payment_method' => $data['payment_method'],
            'status' => $status,
            'price_label' => $priceLabel,
            'country_code' => $region,
            'trial_ends_at' => $trialEndsAt,
            'current_period_ends_at' => $periodEndsAt,
        ]);

        $user->update([
            'subscription_tier' => $data['tier'],
            'trial_active' => $trialEndsAt !== null,
            'trial_ends_at' => $trialEndsAt,
        ]);

        // The new tier carries a different allowance, so the balance is reset
        // to match it rather than carrying the old tier's credits over.
        app(CreditService::class)->grantAllowance($user->fresh());

        return response()->json([
            'success' => true,
            'message' => $trialEndsAt
                ? 'Trial started. No charge for 14 days.'
                : 'Subscription active.',
            'subscription' => $subscription->toApiArray(),
            'user' => $user->fresh()->toSessionArray(),
        ], 201);
    }

    public function current(Request $request)
    {
        $subscription = $request->user()->activeSubscription;

        return response()->json([
            'success' => true,
            'data' => $subscription?->toApiArray(),
        ]);
    }

    public function cancel(Request $request)
    {
        $user = $request->user();
        $subscription = $user->activeSubscription;

        if (! $subscription) {
            return response()->json([
                'success' => false,
                'message' => 'No active subscription to cancel.',
            ], 404);
        }

        $subscription->update(['status' => 'cancelled', 'cancelled_at' => now()]);
        $user->update([
            'subscription_tier' => 'free',
            'trial_active' => false,
            'trial_ends_at' => null,
        ]);

        return response()->json([
            'success' => true,
            'user' => $user->fresh()->toSessionArray(),
        ]);
    }
}
