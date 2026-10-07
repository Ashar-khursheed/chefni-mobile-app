<?php

namespace App\Services;

use App\Models\OtpCode;
use App\Services\Sms\SmsSender;
use Illuminate\Support\Facades\Hash;
use RuntimeException;

/**
 * Issues and checks the six-digit codes that stand in for a password.
 *
 * The code is hashed on the way in and compared on the way out, so it exists
 * in the clear only inside the SMS. Rate limits live here rather than in the
 * controller so both the request and verify paths share them.
 */
class OtpService
{
    private const CODE_TTL_SECONDS = 300;   // 5 minutes
    private const RESEND_COOLDOWN_SECONDS = 60;

    /**
     * A demo account whose code never changes, so the app can be shown without
     * an SMS gateway. Guarded by config so it cannot reach production.
     */
    private const TEST_PHONE = '+923001112233';
    private const TEST_CODE = '123456';

    public function __construct(private readonly SmsSender $sms)
    {
    }

    /**
     * Send a fresh code, replacing any live one for this number.
     *
     * @throws RuntimeException when asked again inside the cooldown window.
     */
    public function issue(string $phone): void
    {
        $phone = $this->normalise($phone);

        // The demo number needs no code issued, and no cooldown getting in the
        // way of repeated sign-ins during a walkthrough.
        if ($this->isTestPhone($phone)) {
            $this->sms->sendOtp($phone, self::TEST_CODE, (int) (self::CODE_TTL_SECONDS / 60));

            return;
        }

        // Cooldown counts every recent send, consumed or not — otherwise
        // verifying a code immediately unlocks another free SMS.
        $recent = OtpCode::where('phone', $phone)
            ->latest('created_at')
            ->first();

        if ($recent && $recent->created_at->diffInSeconds(now()) < self::RESEND_COOLDOWN_SECONDS) {
            $wait = self::RESEND_COOLDOWN_SECONDS - (int) $recent->created_at->diffInSeconds(now());
            throw new RuntimeException("Please wait {$wait} seconds before requesting another code.");
        }

        // Only one code may be live per number, so an old one cannot be used
        // after a resend.
        OtpCode::where('phone', $phone)->whereNull('consumed_at')->delete();

        $code = str_pad((string) random_int(0, 999999), 6, '0', STR_PAD_LEFT);

        OtpCode::create([
            'phone' => $phone,
            'code_hash' => Hash::make($code),
            'expires_at' => now()->addSeconds(self::CODE_TTL_SECONDS),
        ]);

        $this->sms->sendOtp($phone, $code, (int) (self::CODE_TTL_SECONDS / 60));
    }

    /**
     * True when the code matches a live record; the record is then consumed so
     * the same code cannot be replayed.
     */
    public function verify(string $phone, string $code): bool
    {
        $phone = $this->normalise($phone);

        // The demo code is reusable on purpose — a walkthrough should not be
        // able to lock itself out.
        if ($this->isTestPhone($phone)) {
            return $code === self::TEST_CODE;
        }

        $record = OtpCode::where('phone', $phone)
            ->whereNull('consumed_at')
            ->latest('created_at')
            ->first();

        if (! $record || ! $record->isUsable()) {
            return false;
        }

        if (! Hash::check($code, $record->code_hash)) {
            $record->increment('attempts');

            return false;
        }

        $record->update(['consumed_at' => now()]);

        return true;
    }

    /**
     * True only for the demo number, and only while the demo account is
     * switched on. It is off unless CHEFNI_DEMO_LOGIN is explicitly set, so a
     * production deploy cannot inherit a fixed code by accident.
     */
    private function isTestPhone(string $normalisedPhone): bool
    {
        return config('services.chefni.demo_login', false)
            && $normalisedPhone === self::TEST_PHONE;
    }

    /**
     * Strip formatting and settle on a single stored form, so "0312 4567890",
     * "+92 312 4567890" and "923124567890" are one account, not three.
     */
    public function normalise(string $phone): string
    {
        $digits = preg_replace('/\D+/', '', $phone) ?? '';

        // Already international.
        if (str_starts_with($digits, '92')) {
            return '+'.$digits;
        }

        // Local form, "03xx…".
        if (str_starts_with($digits, '0')) {
            return '+92'.substr($digits, 1);
        }

        // Bare subscriber number, "3xx…" — what a UI showing a fixed "+92"
        // prefix sends. Without this it would become +3xx…, a different
        // country, and the code would never match.
        if (strlen($digits) === 10 && str_starts_with($digits, '3')) {
            return '+92'.$digits;
        }

        return '+'.$digits;
    }
}
