<?php

namespace App\Http\Middleware;

use Illuminate\Auth\Middleware\Authenticate as Middleware;
use Illuminate\Http\Request;

class Authenticate extends Middleware
{
    /**
     * API clients get a 401 JSON body rather than a redirect to a login page.
     */
    protected function redirectTo(Request $request): ?string
    {
        return $request->expectsJson() ? null : null;
    }
}
