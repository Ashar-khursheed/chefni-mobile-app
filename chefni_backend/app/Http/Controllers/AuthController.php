<?php

namespace App\Http\Controllers;

use App\Exceptions\OtpDeliveryException;
use App\Models\User;
use App\Services\CreditService;
use App\Services\OtpService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;
use RuntimeException;

class AuthController extends Controller
{
    /**
     * Register a user and start the 14-day trial. Creates a real row and
     * issues a Sanctum token bound to it.
     */
    public function register(Request $request)
    {
        $data = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users,email',
            'password' => 'required|string|min:8',
            'country_code' => 'nullable|string|max:5',
        ]);

        $user = User::create([
            'name' => $data['name'],
            'email' => strtolower($data['email']),
            'password' => $data['password'], // hashed by the model cast
            'role' => 'user',
            'subscription_tier' => 'creator_trial',
            'trial_active' => true,
            'trial_ends_at' => now()->addDays(14),
            'country_code' => strtoupper($data['country_code'] ?? 'PK'),
        ]);

        app(CreditService::class)->grantAllowance($user);
        $user->refresh();

        return response()->json([
            'success' => true,
            'message' => 'Registration successful. Your 14-day free trial is active.',
            'access_token' => $user->createToken('mobile')->plainTextToken,
            'token_type' => 'Bearer',
            'user' => $user->toSessionArray(),
        ], 201);
    }

    /**
     * Verify credentials against the stored hash. Wrong passwords are
     * rejected with 422 rather than silently succeeding.
     */
    public function login(Request $request)
    {
        $data = $request->validate([
            'email' => 'required|string|email',
            'password' => 'required|string',
        ]);

        $user = User::where('email', strtolower($data['email']))->first();

        if (! $user || ! Hash::check($data['password'], $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['These credentials do not match our records.'],
            ]);
        }

        return response()->json([
            'success' => true,
            'access_token' => $user->createToken('mobile')->plainTextToken,
            'token_type' => 'Bearer',
            'user' => $user->toSessionArray(),
        ]);
    }

    /**
     * Send a login code to a phone number. Deliberately answers the same way
     * whether or not the number has an account — the caller learns nothing
     * about who is registered.
     */
    public function requestOtp(Request $request, OtpService $otp)
    {
        $data = $request->validate([
            'phone' => 'required|string|min:10|max:20',
        ]);

        try {
            $otp->issue($data['phone']);
        } catch (OtpDeliveryException $e) {
            // The channel itself failed (WhatsApp API down/misconfigured) —
            // distinct from a cooldown, so the client shouldn't just wait and
            // retry the same way.
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 503);
        } catch (RuntimeException $e) {
            // Cooldown, not a failure the user can fix by retrying immediately.
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 429);
        }

        return response()->json([
            'success' => true,
            'message' => 'Code sent.',
            'expires_in' => 300,
        ]);
    }

    /**
     * Exchange a valid code for a token, creating the account on first use.
     * Returns the same shape as login/register so the app's token handling is
     * unchanged.
     */
    public function verifyOtp(Request $request, OtpService $otp)
    {
        $data = $request->validate([
            'phone' => 'required|string|min:10|max:20',
            'code' => 'required|string|size:6',
            'name' => 'nullable|string|max:255',
            'country_code' => 'nullable|string|max:5',
        ]);

        if (! $otp->verify($data['phone'], $data['code'])) {
            throw ValidationException::withMessages([
                'code' => ['That code is not valid. Request a new one.'],
            ]);
        }

        $phone = $otp->normalise($data['phone']);
        $user = User::where('phone', $phone)->first();
        $isNew = $user === null;

        if ($isNew) {
            $user = User::create([
                // The sign-in screen collects only a number, so the key may be
                // absent or blank; a name is set later in the profile.
                'name' => trim($data['name'] ?? '') ?: 'Chef',
                'phone' => $phone,
                'phone_verified_at' => now(),
                'role' => 'user',
                'subscription_tier' => 'creator_trial',
                'trial_active' => true,
                'trial_ends_at' => now()->addDays(14),
                'country_code' => strtoupper($data['country_code'] ?? 'PK'),
            ]);

            app(CreditService::class)->grantAllowance($user);
            $user->refresh();
        } elseif ($user->phone_verified_at === null) {
            $user->update(['phone_verified_at' => now()]);
        }

        return response()->json([
            'success' => true,
            'access_token' => $user->createToken('mobile')->plainTextToken,
            'token_type' => 'Bearer',
            'is_new_account' => $isNew,
            'user' => $user->toSessionArray(),
        ], $isNew ? 201 : 200);
    }

    /**
     * Current account — lets the app restore a session from a stored token.
     */
    public function me(Request $request)
    {
        return response()->json([
            'success' => true,
            'user' => $request->user()->toSessionArray(),
        ]);
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json(['success' => true, 'message' => 'Logged out.']);
    }

    /**
     * Account deletion (Apple / Play Store requirement). Revokes tokens and
     * removes the row; cascades clear the user's content.
     */
    public function deleteAccount(Request $request)
    {
        $user = $request->user();
        $user->tokens()->delete();
        $user->delete();

        return response()->json([
            'success' => true,
            'message' => 'Account deleted and personal data erasure initiated.',
            'erasure_scheduled_at' => now()->addDays(30)->toIso8601String(),
        ]);
    }
}
