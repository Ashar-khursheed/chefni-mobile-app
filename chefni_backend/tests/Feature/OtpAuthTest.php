<?php

namespace Tests\Feature;

use App\Models\OtpCode;
use App\Models\User;
use App\Services\OtpService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use RuntimeException;
use Tests\TestCase;

/**
 * The OTP is the only credential, so the guarantees that matter are: a code
 * works once, a wrong code cannot be guessed indefinitely, and the same number
 * always resolves to the same account.
 */
class OtpAuthTest extends TestCase
{
    use RefreshDatabase;

    private function otp(): OtpService
    {
        return app(OtpService::class);
    }

    /** Reads the plaintext code by re-hashing candidates is impossible, so
     * tests seed a known code directly. */
    private function seedCode(string $phone, string $code = '123456'): void
    {
        OtpCode::create([
            'phone' => $phone,
            'code_hash' => Hash::make($code),
            'expires_at' => now()->addMinutes(5),
        ]);
    }

    public function test_numbers_normalise_to_one_stored_form(): void
    {
        $expected = '+923124567890';

        $this->assertSame($expected, $this->otp()->normalise('03124567890'));
        $this->assertSame($expected, $this->otp()->normalise('+92 312 4567890'));
        $this->assertSame($expected, $this->otp()->normalise('923124567890'));

        // The sign-in form shows a fixed "+92" and sends only the subscriber
        // digits. Treating those as a country code sends the code to a number
        // the user can never verify.
        $this->assertSame($expected, $this->otp()->normalise('3124567890'));
    }

    public function test_a_valid_code_verifies_once_and_cannot_be_replayed(): void
    {
        $phone = '+923124567890';
        $this->seedCode($phone);

        $this->assertTrue($this->otp()->verify($phone, '123456'));
        $this->assertFalse($this->otp()->verify($phone, '123456'));
    }

    public function test_five_wrong_guesses_burn_the_code(): void
    {
        $phone = '+923124567890';
        $this->seedCode($phone);

        for ($i = 0; $i < OtpCode::MAX_ATTEMPTS; $i++) {
            $this->assertFalse($this->otp()->verify($phone, '000000'));
        }

        // Even the correct code is dead once the attempt budget is spent.
        $this->assertFalse($this->otp()->verify($phone, '123456'));
    }

    public function test_an_expired_code_is_rejected(): void
    {
        $phone = '+923124567890';

        OtpCode::create([
            'phone' => $phone,
            'code_hash' => Hash::make('123456'),
            'expires_at' => now()->subMinute(),
        ]);

        $this->assertFalse($this->otp()->verify($phone, '123456'));
    }

    public function test_requesting_twice_in_quick_succession_is_refused(): void
    {
        $phone = '03124567890';

        $this->otp()->issue($phone);

        $this->expectException(RuntimeException::class);
        $this->otp()->issue($phone);
    }

    public function test_verifying_a_new_number_creates_an_account_with_a_trial(): void
    {
        $phone = '03124567890';
        $this->seedCode('+923124567890');

        $response = $this->postJson('/api/auth/phone/verify', [
            'phone' => $phone,
            'code' => '123456',
            'name' => 'Rabia Nasar',
        ]);

        $response->assertCreated()
            ->assertJsonPath('is_new_account', true)
            ->assertJsonPath('user.phone', '+923124567890');

        $user = User::where('phone', '+923124567890')->first();
        $this->assertNotNull($user);
        $this->assertTrue((bool) $user->trial_active);
        $this->assertSame(3, $user->video_credits_balance);
    }

    public function test_verifying_a_known_number_signs_in_rather_than_duplicating(): void
    {
        $phone = '+923124567890';

        User::create([
            'name' => 'Existing Chef',
            'phone' => $phone,
            'subscription_tier' => 'creator',
            'trial_active' => false,
        ]);

        $this->seedCode($phone);

        $this->postJson('/api/auth/phone/verify', [
            'phone' => '03124567890',
            'code' => '123456',
        ])->assertOk()->assertJsonPath('is_new_account', false);

        $this->assertSame(1, User::where('phone', $phone)->count());
    }

    public function test_sign_up_works_without_a_name(): void
    {
        // What the sign-in screen actually sends — number and code only.
        $this->seedCode('+923124567890');

        $this->postJson('/api/auth/phone/verify', [
            'phone' => '3124567890',
            'code' => '123456',
        ])->assertCreated();

        $this->assertSame('Chef', User::where('phone', '+923124567890')->value('name'));
    }

    public function test_the_demo_number_accepts_its_fixed_code_repeatedly(): void
    {
        config(['services.chefni.demo_login' => true]);

        // Reusable on purpose: a walkthrough must not lock itself out.
        $this->assertTrue($this->otp()->verify('3001112233', '123456'));
        $this->assertTrue($this->otp()->verify('03001112233', '123456'));
    }

    public function test_the_demo_code_is_refused_on_other_numbers(): void
    {
        config(['services.chefni.demo_login' => true]);
        $this->seedCode('+923459876543', '654321');

        // A fixed demo code must not become a master key.
        $this->assertFalse($this->otp()->verify('3459876543', '123456'));
        $this->assertTrue($this->otp()->verify('3459876543', '654321'));
    }

    public function test_the_demo_number_is_inert_when_the_flag_is_off(): void
    {
        config(['services.chefni.demo_login' => false]);

        $this->assertFalse($this->otp()->verify('3001112233', '123456'));
    }

    public function test_a_wrong_code_is_rejected_by_the_endpoint(): void
    {
        $this->seedCode('+923124567890');

        $this->postJson('/api/auth/phone/verify', [
            'phone' => '03124567890',
            'code' => '999999',
        ])->assertStatus(422)->assertJsonValidationErrors('code');
    }
}
