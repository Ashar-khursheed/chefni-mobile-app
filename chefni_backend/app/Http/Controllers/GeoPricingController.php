<?php

namespace App\Http\Controllers;

use App\Models\RegionalPrice;
use Illuminate\Http\Request;

class GeoPricingController extends Controller
{
    /** Presentation details that aren't pricing data, so they don't need a column. */
    private const CURRENCY_SYMBOLS = [
        'PKR' => 'Rs.',
        'AED' => 'AED',
        'USD' => '$',
    ];

    private const GATEWAYS = [
        'PK' => ['Stripe', 'EasyPaisa', 'JazzCash', 'BankTransfer'],
        'AE' => ['Stripe', 'AppleIAP', 'GooglePlayIAP'],
        'US' => ['Stripe', 'AppleIAP', 'GooglePlayIAP'],
    ];

    /** Resolve regional pricing from the admin-editable table, not a hardcoded matrix. */
    public function getPricingForLocation(Request $request)
    {
        $countryCode = strtoupper($request->input('country', 'PK'));

        $region = RegionalPrice::where('country_code', $countryCode)
            ->where('is_active', true)
            ->first()
            ?? RegionalPrice::where('country_code', 'US')->where('is_active', true)->first();

        if ($region === null) {
            return response()->json([
                'success' => false,
                'message' => 'No regional pricing is configured yet.',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'resolved_country' => $countryCode,
            'pricing' => $this->toApiArray($region),
            'all_available_regions' => RegionalPrice::where('is_active', true)->pluck('country_code'),
        ]);
    }

    public function listRegions()
    {
        return response()->json([
            'success' => true,
            'data' => RegionalPrice::orderBy('country_code')->get()
                ->map(fn (RegionalPrice $r) => $this->toApiArray($r))
                ->values(),
        ]);
    }

    /** Admin edit of one region's prices — the endpoint the mobile/web admin's "Update" action calls. */
    public function updatePricingRule(Request $request)
    {
        $data = $request->validate([
            'country_code' => 'required|string|size:2',
            'country_name' => 'sometimes|string|max:120',
            'currency_code' => 'sometimes|string|max:5',
            'creator_monthly_price' => 'required|numeric|min:0',
            'creator_yearly_price' => 'required|numeric|min:0',
            'pro_monthly_price' => 'required|numeric|min:0',
            'pro_yearly_price' => 'required|numeric|min:0',
            'is_active' => 'sometimes|boolean',
        ]);

        $code = strtoupper($data['country_code']);
        $existing = RegionalPrice::where('country_code', $code)->first();

        if ($existing === null && (!isset($data['country_name']) || !isset($data['currency_code']))) {
            return response()->json([
                'success' => false,
                'message' => 'country_name and currency_code are required for a new region.',
            ], 422);
        }

        $region = RegionalPrice::updateOrCreate(
            ['country_code' => $code],
            [
                'country_name' => $data['country_name'] ?? $existing?->country_name,
                'currency_code' => $data['currency_code'] ?? $existing?->currency_code,
                'creator_monthly_price' => $data['creator_monthly_price'],
                'creator_yearly_price' => $data['creator_yearly_price'],
                'pro_monthly_price' => $data['pro_monthly_price'],
                'pro_yearly_price' => $data['pro_yearly_price'],
                'is_active' => $data['is_active'] ?? $existing?->is_active ?? true,
            ],
        );

        return response()->json([
            'success' => true,
            'data' => $this->toApiArray($region),
        ]);
    }

    private function toApiArray(RegionalPrice $region): array
    {
        return [
            'country_code' => $region->country_code,
            'country_name' => $region->country_name,
            'currency_code' => $region->currency_code,
            'symbol' => self::CURRENCY_SYMBOLS[$region->currency_code] ?? $region->currency_code,
            'creator_monthly' => (float) $region->creator_monthly_price,
            'creator_yearly' => (float) $region->creator_yearly_price,
            'pro_monthly' => (float) $region->pro_monthly_price,
            'pro_yearly' => (float) $region->pro_yearly_price,
            'payment_gateways' => self::GATEWAYS[$region->country_code] ?? ['Stripe'],
            'is_available' => (bool) $region->is_active,
        ];
    }
}
