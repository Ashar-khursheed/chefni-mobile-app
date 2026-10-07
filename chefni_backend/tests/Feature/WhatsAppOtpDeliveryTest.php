<?php

namespace Tests\Feature;

use App\Exceptions\OtpDeliveryException;
use App\Services\Sms\WhatsAppSmsSender;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

/**
 * The WhatsApp sender is the real OTP delivery channel this project settled
 * on. These pin the request it sends and how it fails — a misconfigured
 * token or a Meta API outage must surface as a clear error, not a silent
 * "code sent" that never arrives.
 */
class WhatsAppOtpDeliveryTest extends TestCase
{
    use RefreshDatabase;

    private function sender(): WhatsAppSmsSender
    {
        return new WhatsAppSmsSender(
            phoneNumberId: '123456',
            accessToken: 'test-token',
            templateName: 'otp_code',
            templateLanguage: 'en',
            apiVersion: 'v21.0',
        );
    }

    public function test_sends_a_template_message_with_the_code_as_the_body_parameter(): void
    {
        Http::fake(['graph.facebook.com/*' => Http::response(['messages' => [['id' => 'wamid.1']]], 200)]);

        $this->sender()->sendOtp('+923124567890', '482913', 5);

        Http::assertSent(function ($request) {
            return $request->url() === 'https://graph.facebook.com/v21.0/123456/messages'
                && $request->hasHeader('Authorization', 'Bearer test-token')
                && $request['to'] === '923124567890'
                && $request['type'] === 'template'
                && $request['template']['name'] === 'otp_code'
                && $request['template']['language']['code'] === 'en'
                && $request['template']['components'][0]['parameters'][0]['text'] === '482913';
        });
    }

    public function test_strips_the_leading_plus_for_the_whatsapp_recipient_format(): void
    {
        Http::fake(['graph.facebook.com/*' => Http::response(['messages' => []], 200)]);

        $this->sender()->sendOtp('+923124567890', '111111', 5);

        Http::assertSent(fn ($request) => ! str_starts_with($request['to'], '+'));
    }

    public function test_an_api_error_response_raises_a_delivery_exception(): void
    {
        Http::fake(['graph.facebook.com/*' => Http::response(['error' => ['message' => 'Invalid token']], 401)]);

        $this->expectException(OtpDeliveryException::class);
        $this->sender()->sendOtp('+923124567890', '111111', 5);
    }

    public function test_a_transport_failure_raises_a_delivery_exception_rather_than_crashing(): void
    {
        Http::fake(fn () => throw new \Illuminate\Http\Client\ConnectionException('timed out'));

        $this->expectException(OtpDeliveryException::class);
        $this->sender()->sendOtp('+923124567890', '111111', 5);
    }

    public function test_the_request_endpoint_requires_the_otp_request_to_actually_attempt_delivery(): void
    {
        // End-to-end through the controller with the WhatsApp sender failing —
        // the client must see 503, not a generic 500 or a false "code sent".
        config([
            'services.whatsapp.phone_number_id' => '123456',
            'services.whatsapp.access_token' => 'test-token',
            'services.whatsapp.template_name' => 'otp_code',
            'services.whatsapp.template_language' => 'en',
            'services.whatsapp.api_version' => 'v21.0',
        ]);
        Http::fake(['graph.facebook.com/*' => Http::response(['error' => ['message' => 'down']], 500)]);

        $this->postJson('/api/auth/phone/request', ['phone' => '03124567890'])
            ->assertStatus(503);
    }
}
