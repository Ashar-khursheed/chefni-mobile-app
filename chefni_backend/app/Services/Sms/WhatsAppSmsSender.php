<?php

namespace App\Services\Sms;

use App\Exceptions\OtpDeliveryException;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Throwable;

/**
 * Delivers the OTP as a WhatsApp Business API template message via Meta's
 * Cloud API — the channel this project settled on (~Rs 2/message) instead of
 * Firebase or a traditional SMS gateway.
 *
 * WhatsApp cannot send freeform text outside an open customer conversation,
 * so the code goes out through a pre-approved template (created once in Meta
 * Business Manager) with the code as its one body parameter. The template
 * name/language are config, not hardcoded, so swapping the approved template
 * later needs no code change.
 */
class WhatsAppSmsSender implements SmsSender
{
    public function __construct(
        private readonly string $phoneNumberId,
        private readonly string $accessToken,
        private readonly string $templateName,
        private readonly string $templateLanguage,
        private readonly string $apiVersion,
    ) {
    }

    public function sendOtp(string $phone, string $code, int $expiresInMinutes): void
    {
        $to = ltrim($phone, '+');

        try {
            $response = Http::withToken($this->accessToken)
                ->timeout(10)
                ->post("https://graph.facebook.com/{$this->apiVersion}/{$this->phoneNumberId}/messages", [
                    'messaging_product' => 'whatsapp',
                    'to' => $to,
                    'type' => 'template',
                    'template' => [
                        'name' => $this->templateName,
                        'language' => ['code' => $this->templateLanguage],
                        'components' => [
                            [
                                'type' => 'body',
                                'parameters' => [
                                    ['type' => 'text', 'text' => $code],
                                ],
                            ],
                        ],
                    ],
                ]);
        } catch (Throwable $e) {
            Log::error('WhatsApp OTP send failed (transport)', ['phone' => $phone, 'error' => $e->getMessage()]);

            throw new OtpDeliveryException('Could not send the verification code. Please try again shortly.');
        }

        if ($response->failed()) {
            Log::error('WhatsApp OTP send failed (API)', [
                'phone' => $phone,
                'status' => $response->status(),
                'body' => $response->json() ?? $response->body(),
            ]);

            throw new OtpDeliveryException('Could not send the verification code. Please try again shortly.');
        }
    }
}
