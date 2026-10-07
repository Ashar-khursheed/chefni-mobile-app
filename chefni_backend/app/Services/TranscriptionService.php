<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use RuntimeException;

/**
 * Speech-to-text for the extracted audio track. The recipe extractor works
 * from what the chef says, so this is the first half of that pipeline.
 */
class TranscriptionService
{
    private const TIMEOUT_SECONDS = 180;

    /** Whisper's upload ceiling. A 60s mono 16 kHz WAV lands far below it. */
    private const MAX_UPLOAD_BYTES = 25 * 1024 * 1024;

    public function isConfigured(): bool
    {
        return ! empty(config('services.openai.key'));
    }

    /**
     * @return string Transcript text; empty when the audio carried no speech.
     *
     * @throws RuntimeException on a missing key, unreadable file or API failure.
     */
    public function transcribe(string $audioFilePath): string
    {
        $key = config('services.openai.key');

        if (empty($key)) {
            throw new RuntimeException(
                'Transcription is not configured: set OPENAI_API_KEY in the environment.'
            );
        }

        if (! is_file($audioFilePath)) {
            throw new RuntimeException("Audio file not found at: {$audioFilePath}");
        }

        $size = filesize($audioFilePath);

        if ($size === 0) {
            return '';
        }

        if ($size > self::MAX_UPLOAD_BYTES) {
            throw new RuntimeException(
                'Extracted audio is larger than the '
                .round(self::MAX_UPLOAD_BYTES / 1024 / 1024)
                .'MB transcription limit.'
            );
        }

        $response = Http::withToken($key)
            ->timeout(self::TIMEOUT_SECONDS)
            ->attach('file', file_get_contents($audioFilePath), basename($audioFilePath))
            ->post('https://api.openai.com/v1/audio/transcriptions', [
                'model' => config('services.openai.transcription_model', 'whisper-1'),
                'response_format' => 'text',
            ]);

        if ($response->failed()) {
            throw new RuntimeException(
                'Transcription failed (HTTP '.$response->status().'): '
                .$this->errorMessageFrom($response->body())
            );
        }

        return trim($response->body());
    }

    /** Error bodies arrive as JSON when the API rejects the request, plain text otherwise. */
    private function errorMessageFrom(string $body): string
    {
        $decoded = json_decode($body, true);

        return $decoded['error']['message'] ?? mb_substr(trim($body), 0, 300);
    }
}
