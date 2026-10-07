<?php

return [

    /*
     * Demo sign-in: when enabled, one fixed number accepts one fixed code so
     * the app can be demonstrated without an SMS gateway. Never enable in
     * production.
     */
    'chefni' => [
        'demo_login' => env('CHEFNI_DEMO_LOGIN', false),
    ],

    /*
    |--------------------------------------------------------------------------
    | OTP Delivery — WhatsApp Business API
    |--------------------------------------------------------------------------
    |
    | Chosen over Firebase or a traditional SMS gateway (~Rs 2/message via
    | Meta's Cloud API). Requires a WhatsApp Business phone number and an
    | approved authentication template whose body takes the code as its one
    | parameter. Without an access token, OTP codes are written to the log
    | instead (see AppServiceProvider) — safe for local dev, never for prod.
    |
    */

    'whatsapp' => [
        'phone_number_id' => env('WHATSAPP_PHONE_NUMBER_ID'),
        'access_token' => env('WHATSAPP_ACCESS_TOKEN'),
        'template_name' => env('WHATSAPP_OTP_TEMPLATE', 'otp_code'),
        'template_language' => env('WHATSAPP_OTP_TEMPLATE_LANG', 'en'),
        'api_version' => env('WHATSAPP_API_VERSION', 'v21.0'),
    ],

    /*
    |--------------------------------------------------------------------------
    | Media Toolchain
    |--------------------------------------------------------------------------
    |
    | Absolute paths are safest on Windows and on hosts where the web user has
    | a trimmed PATH. Leave as-is when both binaries are on PATH.
    |
    */

    'ffmpeg' => [
        'binary' => env('FFMPEG_BINARY', 'ffmpeg'),
        'probe_binary' => env('FFPROBE_BINARY', 'ffprobe'),
    ],

    /*
    |--------------------------------------------------------------------------
    | Recipe Extraction
    |--------------------------------------------------------------------------
    |
    | The pipeline transcribes the video's audio, then asks Claude to turn that
    | transcript into a structured recipe with per-ingredient cost estimates.
    | Without these keys the pipeline still produces a reel — it just stops
    | before the recipe card and says so.
    |
    */

    'anthropic' => [
        'key' => env('ANTHROPIC_API_KEY'),
        'model' => env('ANTHROPIC_MODEL', 'claude-opus-5'),
        'version' => env('ANTHROPIC_VERSION', '2023-06-01'),
    ],

    'openai' => [
        'key' => env('OPENAI_API_KEY'),
        'transcription_model' => env('OPENAI_TRANSCRIPTION_MODEL', 'whisper-1'),
    ],

    'stripe' => [
        'key' => env('STRIPE_KEY'),
        'secret' => env('STRIPE_SECRET'),
    ],

];
