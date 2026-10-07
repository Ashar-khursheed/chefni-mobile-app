<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Gates Restaurant Pro-only surfaces (team, HACCP, white-label). Creator and
 * Creator-trial do not unlock these — only Restaurant Pro does.
 */
class EnsureRestaurantProAccess
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

        if (! $user->isRestaurantPro()) {
            return response()->json([
                'success' => false,
                'message' => 'This feature is part of Restaurant Pro.',
                'upgrade_required' => true,
            ], 402);
        }

        return $next($request);
    }
}
