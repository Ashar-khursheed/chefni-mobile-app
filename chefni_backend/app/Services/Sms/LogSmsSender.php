<?php

namespace App\Services\Sms;

use Illuminate\Support\Facades\Log;

/**
 * Development driver: writes the message to the log instead of sending it, so
 * the OTP flow is testable without a WhatsApp Business account or spending
 * credit.
 *
 * Never bind this in production — the code lands in plain text in the log.
 */
class LogSmsSender implements SmsSender
{
    public function sendOtp(string $phone, string $code, int $expiresInMinutes): void
    {
        Log::info("[OTP to {$phone}] code {$code}, expires in {$expiresInMinutes} min");
    }
}
