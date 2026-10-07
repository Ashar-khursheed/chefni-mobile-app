<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

class LegalController extends Controller
{
    public function getPrivacyPolicy()
    {
        return response()->json([
            'success' => true,
            'title' => 'Chefni AI Privacy Policy',
            'last_updated' => '2026-08-04',
            'sections' => [
                [
                    'heading' => '1. Data Collection & Purpose',
                    'content' => 'Chefni AI collects minimal personal data (Email address, optional chef name, uploaded raw cooking videos) strictly for video reel generation, AI recipe extraction, and subscription management.',
                ],
                [
                    'heading' => '2. Video Content Privacy',
                    'content' => 'All user-uploaded videos and extracted recipes remain strictly private inside your personal dashboard. Only official Chefni content is displayed publicly on the app feed.',
                ],
                [
                    'heading' => '3. Data Erasure Rights',
                    'content' => 'Under Apple Guidelines 5.1.1(v) and Google Play Policy, users can trigger 1-tap Account Deletion at any time from App Settings to permanently erase all personal data within 30 days.',
                ],
            ]
        ]);
    }

    public function getTermsOfService()
    {
        return response()->json([
            'success' => true,
            'title' => 'Chefni AI Terms of Service & EULA',
            'last_updated' => '2026-08-04',
            'content' => 'By using Chefni AI, you agree to the 14-day free trial terms, subscription auto-renewal policies, and brand usage guidelines for downloaded watermarked 1-minute reels.'
        ]);
    }
}
