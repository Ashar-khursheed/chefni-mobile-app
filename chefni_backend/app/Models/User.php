<?php

namespace App\Models;

use App\Services\CreditService;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    protected $fillable = [
        'name',
        'email',
        'phone',
        'phone_verified_at',
        'password',
        'role',
        'subscription_tier',
        'trial_active',
        'trial_ends_at',
        'country_code',
        'brand_name',
        'brand_logo_url',
        'white_label_enabled',
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    // No email_verified_at cast: the column does not exist, and casting a
    // missing column silently breaks any code that reads it.
    protected $casts = [
        'phone_verified_at' => 'datetime',
        'trial_ends_at' => 'datetime',
        'credits_reset_at' => 'datetime',
        'trial_active' => 'boolean',
        'video_credits_balance' => 'integer',
        'white_label_enabled' => 'boolean',
        'password' => 'hashed',
    ];

    public function recipes()
    {
        return $this->hasMany(Recipe::class);
    }

    public function reels()
    {
        return $this->hasMany(Reel::class);
    }

    public function inventoryItems()
    {
        return $this->hasMany(InventoryItem::class);
    }

    public function shoppingListItems()
    {
        return $this->hasMany(ShoppingListItem::class);
    }

    public function savedRecipes()
    {
        return $this->belongsToMany(Recipe::class, 'saved_recipes')->withTimestamps();
    }

    public function likedReels()
    {
        return $this->belongsToMany(Reel::class, 'reel_likes')->withTimestamps();
    }

    public function subscriptions()
    {
        return $this->hasMany(Subscription::class);
    }

    public function videos()
    {
        return $this->hasMany(UserVideo::class);
    }

    public function recipeCards()
    {
        return $this->hasMany(RecipeCard::class);
    }

    public function activeSubscription()
    {
        return $this->hasOne(Subscription::class)
            ->whereIn('status', ['trialing', 'active'])
            ->latestOfMany();
    }

    public function isAdmin(): bool
    {
        return $this->role === 'admin';
    }

    /**
     * Paid tiers and the trial unlock Creator Studio. Mirrors
     * SubscriptionTier.unlocksCreatorTools on the client.
     */
    public function hasCreatorTools(): bool
    {
        if ($this->isAdmin() || $this->subscription_tier === 'free') {
            return false;
        }

        // An expired trial that was never converted drops back to free access.
        return ! $this->trialHasExpired();
    }

    public function videoCredits()
    {
        return $this->hasMany(VideoCredit::class);
    }

    public function stores()
    {
        return $this->hasMany(Store::class);
    }

    public function staffMembers()
    {
        return $this->hasMany(StaffMember::class);
    }

    public function haccpLogs()
    {
        return $this->hasMany(HaccpLog::class);
    }

    /**
     * Team, HACCP and white-label are Restaurant Pro only — Creator does not
     * unlock them, unlike the rest of Creator Studio.
     */
    public function isRestaurantPro(): bool
    {
        return $this->subscription_tier === 'restaurant_pro' && ! $this->trialHasExpired();
    }

    /**
     * Every account has one store; single-location users never chose it, so
     * this is what inventory falls back to when no store is named.
     */
    public function defaultStore(): Store
    {
        return $this->stores()->where('is_default', true)->first()
            ?? $this->stores()->oldest('id')->first()
            ?? $this->stores()->create(['name' => 'Main Kitchen', 'is_default' => true]);
    }

    /**
     * A trial that has run past its end date no longer grants creator tooling,
     * even if the tier column still says otherwise. Checkout sets both, but
     * nothing resets them when the clock runs out.
     */
    public function trialHasExpired(): bool
    {
        return $this->trial_active
            && $this->trial_ends_at !== null
            && $this->trial_ends_at->isPast();
    }

    /**
     * Credits left this period, or null on an uncapped tier.
     *
     * Reads the stored balance rather than counting videos, so a failed encode
     * can be refunded and a monthly reset means something.
     */
    public function uploadQuotaRemaining(): ?int
    {
        return app(CreditService::class)->isUnlimited($this)
            ? null
            : max(0, (int) $this->video_credits_balance);
    }

    /** Total credits the tier grants per period — what the UI counts against. */
    public function uploadQuotaTotal(): ?int
    {
        return app(CreditService::class)->allowanceFor($this);
    }

    public function canUpload(): bool
    {
        $remaining = $this->uploadQuotaRemaining();

        return $remaining === null || $remaining > 0;
    }

    /**
     * Shape consumed by the mobile app's UserSession.fromJson.
     */
    public function toSessionArray(): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'email' => $this->email,
            'phone' => $this->phone,
            'role' => $this->role,
            'subscription_tier' => $this->subscription_tier,
            'trial_active' => (bool) $this->trial_active,
            'trial_ends_at' => $this->trial_ends_at?->toIso8601String(),
            'trial_expired' => $this->trialHasExpired(),
            'country_code' => $this->country_code,
            'upload_quota_remaining' => $this->uploadQuotaRemaining(),
            'upload_quota_total' => $this->uploadQuotaTotal(),
        ];
    }
}
