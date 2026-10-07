<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use RuntimeException;

/**
 * Turns a cooking video's transcript into a structured recipe card with
 * per-ingredient cost estimates for the user's region.
 *
 * Every cost here is the model's guess. The card stores them as estimates and
 * the app presents them as editable — nothing in this pipeline knows real
 * market prices.
 */
class RecipeExtractionService
{
    private const TIMEOUT_SECONDS = 240;
    private const MAX_TOKENS = 8000;

    /** Below this the transcript carries too little to extract a recipe from. */
    private const MIN_TRANSCRIPT_CHARS = 120;

    /** Currency the AI is asked to price in, per region. */
    private const REGION_CURRENCY = [
        'PK' => ['code' => 'PKR', 'label' => 'Pakistani Rupees (PKR)'],
        'AE' => ['code' => 'AED', 'label' => 'UAE Dirhams (AED)'],
        'US' => ['code' => 'USD', 'label' => 'US Dollars (USD)'],
        'GB' => ['code' => 'GBP', 'label' => 'British Pounds (GBP)'],
        'IN' => ['code' => 'INR', 'label' => 'Indian Rupees (INR)'],
        'SA' => ['code' => 'SAR', 'label' => 'Saudi Riyals (SAR)'],
    ];

    public function isConfigured(): bool
    {
        return ! empty(config('services.anthropic.key'));
    }

    public function currencyFor(string $region): string
    {
        return self::REGION_CURRENCY[strtoupper($region)]['code'] ?? 'PKR';
    }

    /**
     * @param  string  $transcript  What the chef said, from TranscriptionService.
     * @param  string  $region      ISO country code driving the pricing currency.
     * @return array{title: string, summary: ?string, cuisine: ?string, prep_time_mins: ?int, cook_time_mins: ?int, servings: int, currency: string, confidence: string, steps: list<string>, ingredients: list<array{name: string, quantity: float, unit: string, category: ?string, estimated_cost: ?float}>}
     *
     * @throws RuntimeException when the key is missing, the transcript is too
     *                          thin, or the API call fails.
     */
    public function extract(string $transcript, string $fallbackTitle, string $region = 'PK'): array
    {
        $key = config('services.anthropic.key');

        if (empty($key)) {
            throw new RuntimeException(
                'Recipe extraction is not configured: set ANTHROPIC_API_KEY in the environment.'
            );
        }

        $transcript = trim($transcript);

        if (mb_strlen($transcript) < self::MIN_TRANSCRIPT_CHARS) {
            throw new RuntimeException(
                'The video did not contain enough spoken detail to build a recipe from.'
            );
        }

        $region = strtoupper($region);
        $currency = self::REGION_CURRENCY[$region] ?? self::REGION_CURRENCY['PK'];

        $response = Http::withHeaders([
            'x-api-key' => $key,
            'anthropic-version' => config('services.anthropic.version', '2023-06-01'),
            'content-type' => 'application/json',
        ])
            ->timeout(self::TIMEOUT_SECONDS)
            ->post('https://api.anthropic.com/v1/messages', [
                'model' => config('services.anthropic.model', 'claude-opus-5'),
                'max_tokens' => self::MAX_TOKENS,
                'system' => $this->systemPrompt($currency['label'], $region),
                // A schema-constrained response means the pipeline never has to
                // guess whether the model returned parseable JSON.
                'output_config' => ['format' => $this->responseSchema()],
                'messages' => [[
                    'role' => 'user',
                    'content' => $this->userPrompt($transcript, $fallbackTitle),
                ]],
            ]);

        if ($response->failed()) {
            throw new RuntimeException(
                'Recipe extraction failed (HTTP '.$response->status().'): '
                .$this->errorMessageFrom($response->json(), $response->body())
            );
        }

        $body = $response->json();
        $stopReason = $body['stop_reason'] ?? null;

        if ($stopReason === 'refusal') {
            throw new RuntimeException(
                'The recipe model declined to process this video\'s content.'
            );
        }

        if ($stopReason === 'max_tokens') {
            throw new RuntimeException(
                'The recipe was too long to extract in one pass. Try a shorter video.'
            );
        }

        return $this->normalise(
            $this->decodeContent($body),
            $fallbackTitle,
            $currency['code'],
        );
    }

    private function systemPrompt(string $currencyLabel, string $region): string
    {
        return <<<PROMPT
        You read transcripts of cooking videos and turn them into structured recipe cards.

        Work only from what the chef actually says. When a quantity, time, or
        ingredient is not stated, infer the most plausible value for the dish
        rather than leaving it out — a usable card matters more than a literal one.

        For every ingredient, estimate what that quantity costs a home cook in
        {$region} at typical {$currencyLabel} retail prices. These are rough
        estimates shown to the user as editable figures, so give a sensible
        number for each ingredient rather than omitting the cost.

        Set `confidence` to reflect how much the transcript actually supported:
        "high" when quantities and steps were spoken explicitly, "medium" when
        you inferred a fair amount, "low" when the transcript was vague enough
        that the card is mostly reconstruction.
        PROMPT;
    }

    private function userPrompt(string $transcript, string $fallbackTitle): string
    {
        return <<<PROMPT
        Build a recipe card from this cooking video transcript.

        The uploader titled the video "{$fallbackTitle}" — use that as a hint,
        but prefer a title that names the dish if the transcript reveals it.

        Transcript:
        {$transcript}
        PROMPT;
    }

    /** @return array<string, mixed> */
    private function responseSchema(): array
    {
        return [
            'type' => 'json_schema',
            'schema' => [
                'type' => 'object',
                'properties' => [
                    'title' => ['type' => 'string'],
                    'summary' => ['type' => 'string'],
                    'cuisine' => ['type' => 'string'],
                    'prep_time_mins' => ['type' => 'integer'],
                    'cook_time_mins' => ['type' => 'integer'],
                    'servings' => ['type' => 'integer'],
                    'confidence' => ['type' => 'string', 'enum' => ['high', 'medium', 'low']],
                    'steps' => [
                        'type' => 'array',
                        'items' => ['type' => 'string'],
                    ],
                    'ingredients' => [
                        'type' => 'array',
                        'items' => [
                            'type' => 'object',
                            'properties' => [
                                'name' => ['type' => 'string'],
                                'quantity' => ['type' => 'number'],
                                'unit' => ['type' => 'string'],
                                'category' => ['type' => 'string'],
                                'estimated_cost' => ['type' => 'number'],
                            ],
                            'required' => ['name', 'quantity', 'unit', 'category', 'estimated_cost'],
                            'additionalProperties' => false,
                        ],
                    ],
                ],
                'required' => [
                    'title', 'summary', 'cuisine', 'prep_time_mins', 'cook_time_mins',
                    'servings', 'confidence', 'steps', 'ingredients',
                ],
                'additionalProperties' => false,
            ],
        ];
    }

    /**
     * The schema guarantees the payload parses, but the response still arrives
     * wrapped in content blocks that have to be located first.
     *
     * @param  array<string, mixed>  $body
     * @return array<string, mixed>
     */
    private function decodeContent(array $body): array
    {
        foreach ($body['content'] ?? [] as $block) {
            if (($block['type'] ?? null) !== 'text') {
                continue;
            }

            $decoded = json_decode($block['text'] ?? '', true);

            if (is_array($decoded)) {
                return $decoded;
            }
        }

        throw new RuntimeException('The recipe model returned no readable recipe data.');
    }

    /**
     * Clamp the model's output into the shape the database expects. The schema
     * fixes types, not sanity — a zero serving count or an empty ingredient
     * name would still break the card downstream.
     *
     * @param  array<string, mixed>  $data
     * @return array<string, mixed>
     */
    private function normalise(array $data, string $fallbackTitle, string $currency): array
    {
        $ingredients = [];

        foreach ($data['ingredients'] ?? [] as $index => $item) {
            $name = trim((string) ($item['name'] ?? ''));

            if ($name === '') {
                continue;
            }

            $cost = $item['estimated_cost'] ?? null;

            $ingredients[] = [
                'name' => mb_substr($name, 0, 255),
                'quantity' => max(0, (float) ($item['quantity'] ?? 0)),
                'unit' => mb_substr(trim((string) ($item['unit'] ?? 'unit')) ?: 'unit', 0, 30),
                'category' => $this->trimmedOrNull($item['category'] ?? null, 60),
                'estimated_cost' => is_numeric($cost) ? round((float) $cost, 2) : null,
                'sort_order' => $index,
            ];
        }

        if ($ingredients === []) {
            throw new RuntimeException(
                'No ingredients could be identified from what was said in this video.'
            );
        }

        $steps = [];

        foreach ($data['steps'] ?? [] as $step) {
            $step = trim((string) $step);

            if ($step !== '') {
                $steps[] = $step;
            }
        }

        $confidence = $data['confidence'] ?? 'medium';

        return [
            'title' => $this->trimmedOrNull($data['title'] ?? null, 255) ?? $fallbackTitle,
            'summary' => $this->trimmedOrNull($data['summary'] ?? null, 1000),
            'cuisine' => $this->trimmedOrNull($data['cuisine'] ?? null, 60),
            'prep_time_mins' => $this->positiveIntOrNull($data['prep_time_mins'] ?? null),
            'cook_time_mins' => $this->positiveIntOrNull($data['cook_time_mins'] ?? null),
            'servings' => max(1, (int) ($data['servings'] ?? 4)),
            'currency' => $currency,
            'confidence' => in_array($confidence, ['high', 'medium', 'low'], true)
                ? $confidence
                : 'medium',
            'steps' => $steps,
            'ingredients' => $ingredients,
        ];
    }

    private function trimmedOrNull(mixed $value, int $maxLength): ?string
    {
        $value = trim((string) ($value ?? ''));

        return $value === '' ? null : mb_substr($value, 0, $maxLength);
    }

    /** Times are unsigned smallints; a negative or absurd value would throw on insert. */
    private function positiveIntOrNull(mixed $value): ?int
    {
        if (! is_numeric($value)) {
            return null;
        }

        $int = (int) $value;

        return $int > 0 ? min($int, 65535) : null;
    }

    private function errorMessageFrom(mixed $json, string $body): string
    {
        return $json['error']['message'] ?? mb_substr(trim($body), 0, 300);
    }
}
