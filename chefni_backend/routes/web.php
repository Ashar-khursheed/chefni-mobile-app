<?php

use Illuminate\Support\Facades\Route;

// Landing page with API Overview
Route::get('/', function () {
    $html = '
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Chefni AI - API Service</title>
            <style>
                body {
                    background-color: #321925;
                    color: #FFF5EA;
                    font-family: system-ui, -apple-system, sans-serif;
                    display: flex;
                    justify-content: center;
                    align-items: center;
                    height: 100vh;
                    margin: 0;
                }
                .card {
                    background: #26121B;
                    padding: 40px;
                    border-radius: 20px;
                    border: 2px solid #D83A75;
                    box-shadow: 0 10px 30px rgba(0,0,0,0.5);
                    text-align: center;
                    max-width: 550px;
                }
                .badge {
                    background: #D83A75;
                    color: white;
                    padding: 6px 16px;
                    border-radius: 20px;
                    font-size: 12px;
                    font-weight: bold;
                    display: inline-block;
                    margin-bottom: 16px;
                }
                h1 { color: #D83A75; margin: 0 0 10px 0; font-size: 28px; }
                p { color: #D8C7B5; font-size: 14px; line-height: 1.6; }
                .btn {
                    display: inline-block;
                    background: #D83A75;
                    color: white;
                    padding: 12px 24px;
                    border-radius: 10px;
                    text-decoration: none;
                    font-weight: bold;
                    margin-top: 16px;
                    box-shadow: 0 4px 12px rgba(216, 58, 117, 0.4);
                }
                .status { background: #422332; padding: 12px; border-radius: 10px; border: 1px solid #572C3E; margin-top: 20px; font-weight: bold; color: #38BDF8; }
                .endpoint-list { text-align: left; background: #1F0F17; padding: 16px; border-radius: 10px; margin-top: 20px; font-size: 13px; font-family: monospace; color: #4ADE80; }
            </style>
        </head>
        <body>
            <div class="card">
                <div class="badge">Chefni AI • FINE. FAST. FAB.</div>
                <h1>Chefni RESTful API Service</h1>
                <p>Laravel API Backend is running live with Sanctum Auth, High-Precision 1-Min Video Processing, Geo-Pricing Matrix, and Ad Management.</p>
                <a href="/docs" class="btn">📖 Open Interactive Swagger UI Docs</a>
                <div class="status">🟢 Status: Online & Ready</div>
                <div class="endpoint-list">
                    <strong>Sample API Endpoints:</strong><br>
                    • GET <a href="/api/reels/official" style="color: #38BDF8;">/api/reels/official</a><br>
                    • GET <a href="/api/geo/pricing" style="color: #38BDF8;">/api/geo/pricing</a><br>
                    • GET <a href="/api/legal/privacy-policy" style="color: #38BDF8;">/api/legal/privacy-policy</a>
                </div>
            </div>
        </body>
        </html>
    ';

    return response($html, 200)->header('Content-Type', 'text/html');
});

// Interactive Swagger UI Console Route (Clean High-Contrast Theme)
Route::get('/docs', function () {
    $html = '
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <title>Chefni AI - Swagger OpenAPI Documentation</title>
            <link rel="stylesheet" type="text/css" href="https://cdnjs.cloudflare.com/ajax/libs/swagger-ui/4.18.3/swagger-ui.css" />
            <style>
                html { box-sizing: border-box; overflow: -moz-scrollbars-vertical; overflow-y: scroll; }
                *, *:before, *:after { box-sizing: inherit; }
                body { margin:0; background: #FAFAFA; color: #3b4151; font-family: sans-serif; }
                .swagger-ui .topbar { background-color: #321925; border-bottom: 3px solid #D83A75; }
                .swagger-ui .info .title { color: #D83A75; font-weight: bold; }
                .swagger-ui .scheme-container { background: #F3F4F6; box-shadow: none; border-radius: 8px; margin: 20px 0; }
                .swagger-ui .opblock .opblock-summary-path { color: #1F2937 !important; font-weight: bold !important; }
                .swagger-ui .opblock .opblock-summary-description { color: #4B5563 !important; }
            </style>
        </head>
        <body>
            <div id="swagger-ui"></div>
            <script src="https://cdnjs.cloudflare.com/ajax/libs/swagger-ui/4.18.3/swagger-ui-bundle.js"></script>
            <script src="https://cdnjs.cloudflare.com/ajax/libs/swagger-ui/4.18.3/swagger-ui-standalone-preset.js"></script>
            <script>
                window.onload = function() {
                    const ui = SwaggerUIBundle({
                        url: "/swagger.json",
                        dom_id: "#swagger-ui",
                        deepLinking: true,
                        presets: [
                            SwaggerUIBundle.presets.apis,
                            SwaggerUIStandalonePreset
                        ],
                        plugins: [
                            SwaggerUIBundle.plugins.DownloadUrl
                        ],
                        layout: "StandaloneLayout"
                    });
                    window.ui = ui;
                };
            </script>
        </body>
        </html>
    ';

    return response($html, 200)->header('Content-Type', 'text/html');
});
