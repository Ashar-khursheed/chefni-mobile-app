<?php

namespace App\Services\Sms;

/**
 * One seam for delivering an OTP code. The method is OTP-specific (not a
 * generic "send text") because the real driver is WhatsApp Business API,
 * which cannot send freeform text to a number outside an open conversation
 * window — only a pre-approved template with the code as a parameter.
 */
interface SmsSender
{
    /**
     * @throws \App\Exceptions\OtpDeliveryException when the message could not
     *         be handed off to the delivery channel.
     */
    public function sendOtp(string $phone, string $code, int $expiresInMinutes): void;
}
