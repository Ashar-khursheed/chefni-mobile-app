<?php

namespace Tests\Feature;

use App\Models\RecipeCard;
use App\Models\RecipeCardIngredient;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

/**
 * The full cost matrix adds labor, overhead and packaging on top of
 * ingredient cost, and turns a selling price into a gross margin — the
 * numbers a restaurant actually prices a dish on.
 */
class RecipeCardCostMatrixTest extends TestCase
{
    use RefreshDatabase;

    private function cardWithIngredient(User $user): RecipeCard
    {
        $card = RecipeCard::create([
            'user_id' => $user->id,
            'title' => 'Chicken Karahi',
            'servings' => 4,
        ]);

        RecipeCardIngredient::create([
            'recipe_card_id' => $card->id,
            'name' => 'Chicken',
            'quantity' => 1000,
            'unit' => 'g',
            'ai_estimated_cost' => 800,
        ]);

        return $card;
    }

    public function test_true_total_cost_adds_labor_overhead_and_packaging_to_ingredients(): void
    {
        $user = User::create(['name' => 'Chef', 'phone' => '+923000000050']);
        $card = $this->cardWithIngredient($user);
        Sanctum::actingAs($user);

        $this->patchJson("/api/recipe-cards/{$card->id}", [
            'labor_cost' => 150,
            'overhead_cost' => 50,
            'packaging_cost' => 30,
        ])->assertOk()
            ->assertJsonPath('data.total_cost', 800)
            ->assertJsonPath('data.true_total_cost', 1030);
    }

    public function test_gross_margin_is_null_without_a_selling_price(): void
    {
        $user = User::create(['name' => 'Chef', 'phone' => '+923000000051']);
        $card = $this->cardWithIngredient($user);
        Sanctum::actingAs($user);

        $this->getJson("/api/recipe-cards/{$card->id}")
            ->assertOk()
            ->assertJsonPath('data.gross_margin_pct', null);
    }

    public function test_gross_margin_is_computed_once_a_selling_price_is_set(): void
    {
        $user = User::create(['name' => 'Chef', 'phone' => '+923000000052']);
        $card = $this->cardWithIngredient($user);
        Sanctum::actingAs($user);

        // True cost: 800 ingredients + 100 labor = 900. Selling at 1500 is a
        // (1500-900)/1500 = 40.0% margin.
        $response = $this->patchJson("/api/recipe-cards/{$card->id}", [
            'labor_cost' => 100,
            'selling_price' => 1500,
        ])->assertOk();

        $this->assertEquals(40.0, $response->json('data.gross_margin_pct'));
    }

    public function test_cost_matrix_fields_reject_negative_values(): void
    {
        $user = User::create(['name' => 'Chef', 'phone' => '+923000000053']);
        $card = $this->cardWithIngredient($user);
        Sanctum::actingAs($user);

        $this->patchJson("/api/recipe-cards/{$card->id}", [
            'labor_cost' => -10,
        ])->assertStatus(422)->assertJsonValidationErrors('labor_cost');
    }
}
