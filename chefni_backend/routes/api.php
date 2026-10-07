<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AdminController;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\BrandingController;
use App\Http\Controllers\GeoPricingController;
use App\Http\Controllers\HaccpController;
use App\Http\Controllers\InventoryController;
use App\Http\Controllers\LegalController;
use App\Http\Controllers\NotificationController;
use App\Http\Controllers\OfficialReelController;
use App\Http\Controllers\RecipeCardController;
use App\Http\Controllers\RecipeController;
use App\Http\Controllers\ShoppingListController;
use App\Http\Controllers\StoreController;
use App\Http\Controllers\SubscriptionController;
use App\Http\Controllers\TeamController;
use App\Http\Controllers\UserStudioController;

/*
|--------------------------------------------------------------------------
| Chefni AI REST API
|--------------------------------------------------------------------------
| Public routes serve the catalogue. Anything that reads or writes a
| specific account sits behind auth:sanctum; the admin surface additionally
| requires the admin role.
*/

// ── Public ──────────────────────────────────────────────────────────────
Route::post('/auth/register', [AuthController::class, 'register']);
Route::post('/auth/login', [AuthController::class, 'login']);

// Phone is the primary credential; email/password above stay for existing
// accounts. Throttled because each request costs an SMS.
Route::post('/auth/phone/request', [AuthController::class, 'requestOtp'])
    ->middleware('throttle:6,1');
Route::post('/auth/phone/verify', [AuthController::class, 'verifyOtp'])
    ->middleware('throttle:10,1');

Route::get('/recipes', [RecipeController::class, 'index']);
Route::get('/recipes/cuisines', [RecipeController::class, 'cuisines']);
Route::get('/recipes/{slug}', [RecipeController::class, 'show']);

Route::get('/reels/official', [OfficialReelController::class, 'index']);
Route::get('/reels/official/{id}', [OfficialReelController::class, 'show']);

Route::get('/subscriptions/plans', [SubscriptionController::class, 'plans']);
Route::get('/geo/pricing', [GeoPricingController::class, 'getPricingForLocation']);

Route::get('/legal/privacy-policy', [LegalController::class, 'getPrivacyPolicy']);
Route::get('/legal/terms', [LegalController::class, 'getTermsOfService']);

// ── Authenticated ───────────────────────────────────────────────────────
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/auth/me', [AuthController::class, 'me']);
    Route::post('/auth/logout', [AuthController::class, 'logout']);
    Route::post('/user/delete-account', [AuthController::class, 'deleteAccount']);

    Route::post('/recipes/{slug}/save', [RecipeController::class, 'toggleSave']);
    Route::get('/me/saved-recipes', [RecipeController::class, 'saved']);

    Route::post('/reels/official/{id}/like', [OfficialReelController::class, 'like']);

    Route::get('/shopping-list', [ShoppingListController::class, 'index']);
    Route::post('/shopping-list', [ShoppingListController::class, 'store']);
    Route::post('/shopping-list/from-recipe', [ShoppingListController::class, 'addFromRecipe']);
    Route::post('/shopping-list/{id}/toggle', [ShoppingListController::class, 'toggle']);
    Route::delete('/shopping-list/checked', [ShoppingListController::class, 'clearChecked']);
    Route::delete('/shopping-list/{id}', [ShoppingListController::class, 'destroy']);

    Route::get('/inventory', [InventoryController::class, 'index']);
    Route::post('/inventory', [InventoryController::class, 'store']);
    // Static segment first, so "check" is never read as an {id}.
    Route::get('/inventory/check/{slug}', [InventoryController::class, 'checkRecipe']);
    Route::patch('/inventory/{id}', [InventoryController::class, 'update']);
    Route::delete('/inventory/{id}', [InventoryController::class, 'destroy']);

    // Locations — inventory, HACCP and staff are all scoped to one of these.
    Route::get('/stores', [StoreController::class, 'index']);
    Route::post('/stores', [StoreController::class, 'store']);
    Route::patch('/stores/{id}', [StoreController::class, 'update']);
    Route::delete('/stores/{id}', [StoreController::class, 'destroy']);

    Route::get('/subscriptions/current', [SubscriptionController::class, 'current']);
    Route::post('/subscriptions/checkout', [SubscriptionController::class, 'checkout']);
    Route::post('/subscriptions/cancel', [SubscriptionController::class, 'cancel']);

    // ── Creator studio ──────────────────────────────────────────────────
    Route::post('/studio/upload-video', [UserStudioController::class, 'uploadVideo']);
    Route::get('/studio/videos', [UserStudioController::class, 'myVideos']);
    Route::get('/studio/videos/{id}/status', [UserStudioController::class, 'status']);
    Route::delete('/studio/videos/{id}', [UserStudioController::class, 'destroy']);

    // ── AI-generated recipe cards ───────────────────────────────────────
    Route::get('/recipe-cards', [RecipeCardController::class, 'index']);
    Route::get('/recipe-cards/{id}', [RecipeCardController::class, 'show']);
    Route::patch('/recipe-cards/{id}', [RecipeCardController::class, 'update']);
    Route::patch('/recipe-cards/{id}/costs', [RecipeCardController::class, 'updateCosts']);
    Route::delete('/recipe-cards/{id}', [RecipeCardController::class, 'destroy']);

    // ── Notifications — derived from live account state, not a stored log ──
    Route::get('/notifications', [NotificationController::class, 'index']);

    // ── Restaurant Pro: team, HACCP, white-label ────────────────────────
    Route::middleware('restaurant_pro')->group(function () {
        Route::get('/team', [TeamController::class, 'index']);
        Route::post('/team', [TeamController::class, 'store']);
        Route::patch('/team/{id}', [TeamController::class, 'update']);
        Route::delete('/team/{id}', [TeamController::class, 'destroy']);

        Route::get('/haccp-logs', [HaccpController::class, 'index']);
        Route::post('/haccp-logs', [HaccpController::class, 'store']);

        Route::get('/branding', [BrandingController::class, 'show']);
        Route::patch('/branding', [BrandingController::class, 'update']);
    });

    // ── Admin only ──────────────────────────────────────────────────────
    Route::middleware('admin')->group(function () {
        Route::get('/admin/telemetry', [AdminController::class, 'telemetry']);
        Route::get('/admin/users', [AdminController::class, 'users']);
        Route::get('/admin/revenue', [AdminController::class, 'revenue']);
        Route::get('/admin/geo-pricing', [GeoPricingController::class, 'listRegions']);
        Route::post('/admin/geo-pricing', [GeoPricingController::class, 'updatePricingRule']);
    });
});
