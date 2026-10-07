<?php

namespace App\Http\Controllers;

use App\Models\Recipe;
use App\Models\Subscription;
use App\Models\User;
use Illuminate\Http\Request;

class AdminController extends Controller
{
    /** Platform overview — all figures derived from real rows. */
    public function telemetry()
    {
        $totalUsers = User::count();
        $activeSubs = Subscription::whereIn('status', ['trialing', 'active'])->count();
        $signupsToday = User::whereDate('created_at', today())->count();

        $signupTrend = collect(range(6, 0))->map(function ($daysAgo) {
            $date = today()->subDays($daysAgo);

            return [
                'label' => $date->format('D'),
                'value' => User::whereDate('created_at', $date)->count(),
            ];
        });

        return response()->json([
            'success' => true,
            'data' => [
                'total_users' => $totalUsers,
                'active_subscriptions' => $activeSubs,
                'signups_today' => $signupsToday,
                'total_recipes' => Recipe::count(),
                'signup_trend' => $signupTrend->values(),
            ],
        ]);
    }

    public function users(Request $request)
    {
        $query = User::query();

        if ($search = $request->query('search')) {
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                    ->orWhere('email', 'like', "%{$search}%");
            });
        }

        $users = $query->orderBy('name')->limit(100)->get();

        return response()->json([
            'success' => true,
            'data' => $users->map(fn (User $u) => [
                'id' => $u->id,
                'name' => $u->name,
                'email' => $u->email,
                'role' => $u->role,
                'plan' => $this->planLabel($u->subscription_tier),
                'joined_at' => $u->created_at?->toIso8601String(),
            ])->values(),
        ]);
    }

    public function revenue()
    {
        $byPlan = Subscription::whereIn('status', ['trialing', 'active'])
            ->selectRaw('tier, COUNT(*) as count')
            ->groupBy('tier')
            ->get()
            ->map(fn ($row) => [
                'name' => $this->planLabel($row->tier),
                'count' => (int) $row->count,
            ]);

        $gateways = Subscription::selectRaw('payment_method, COUNT(*) as count')
            ->groupBy('payment_method')
            ->get();
        $gatewayTotal = max(1, $gateways->sum('count'));

        return response()->json([
            'success' => true,
            'data' => [
                'by_plan' => $byPlan->values(),
                'gateway_split' => $gateways->map(fn ($row) => [
                    'name' => $this->gatewayLabel($row->payment_method),
                    'pct' => (int) round($row->count / $gatewayTotal * 100),
                ])->values(),
            ],
        ]);
    }

    private function planLabel(?string $tier): string
    {
        return match ($tier) {
            'creator' => 'Creator',
            'creator_trial' => 'Creator (trial)',
            'restaurant_pro' => 'Restaurant Pro',
            default => 'Free',
        };
    }

    private function gatewayLabel(?string $method): string
    {
        return match ($method) {
            'card' => 'Stripe (card)',
            'jazzcash' => 'JazzCash',
            'easypaisa' => 'EasyPaisa',
            'bank' => 'Bank transfer',
            default => 'Other',
        };
    }
}
