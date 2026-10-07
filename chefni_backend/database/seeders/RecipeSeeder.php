<?php

namespace Database\Seeders;

use App\Models\Ingredient;
use App\Models\Recipe;
use App\Models\RecipeStep;
use App\Models\Reel;
use App\Models\User;
use Illuminate\Database\Seeder;

class RecipeSeeder extends Seeder
{
    public function run(): void
    {
        $chef = User::where('email', 'rabia@chefni.app')->firstOrFail();

        foreach ($this->recipes() as $data) {
            $recipe = Recipe::updateOrCreate(
                ['slug' => $data['slug']],
                [
                    'user_id' => $chef->id,
                    'title' => $data['title'],
                    'cuisine' => $data['cuisine'],
                    'difficulty' => $data['difficulty'],
                    'calories' => $data['calories'],
                    'tags' => $data['tags'],
                    'likes_count' => $data['likes_count'],
                    'comments_count' => $data['comments_count'],
                    'prep_time_mins' => $data['prep'],
                    'cook_time_mins' => $data['cook'],
                    'servings_base' => $data['servings'],
                    'is_official' => true,
                    'is_published' => true,
                ]
            );

            $recipe->ingredients()->delete();
            foreach ($data['ingredients'] as $i => $line) {
                Ingredient::create([
                    'recipe_id' => $recipe->id,
                    'raw_line' => $line,
                    'position' => $i,
                    'name' => $line,
                    'quantity' => 1,
                    'unit' => '',
                    'category' => 'General',
                ]);
            }

            $recipe->steps()->delete();
            foreach ($data['steps'] as $i => $instruction) {
                RecipeStep::create([
                    'recipe_id' => $recipe->id,
                    'position' => $i + 1,
                    'instruction' => $instruction,
                ]);
            }

            Reel::updateOrCreate(
                ['recipe_id' => $recipe->id],
                [
                    'user_id' => $chef->id,
                    'title' => $data['title'],
                    'video_url' => $data['video_url'],
                    'duration_sec' => $data['reel_seconds'],
                    'watermark_applied' => true,
                    'is_official' => true,
                    'likes_count' => $data['likes_count'],
                    'views_count' => $data['likes_count'] * 12,
                ]
            );
        }
    }

    private function recipes(): array
    {
        $sample = 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/';

        return [
            [
                'slug' => 'nihari',
                'title' => 'Karachi Beef Nihari',
                'cuisine' => 'Pakistani',
                'difficulty' => 'Medium',
                'prep' => 20, 'cook' => 180, 'servings' => 6, 'calories' => 420,
                'likes_count' => 1243, 'comments_count' => 86, 'reel_seconds' => 45,
                'video_url' => $sample.'ForBiggerBlazes.mp4',
                'tags' => ['Pakistani', 'Comfort Food', 'Spicy'],
                'ingredients' => [
                    '1kg beef shank, bone-in',
                    '1/2 cup Nihari masala',
                    '4 tbsp ghee',
                    '2 onions, sliced',
                    '1/4 cup flour, for gravy',
                    'Ginger, chili, lime to garnish',
                ],
                'steps' => [
                    'Sear beef shank in ghee until browned on all sides.',
                    'Add sliced onions and Nihari masala, cook until fragrant.',
                    'Add water, bring to a boil, then simmer covered for 3 hours until tender.',
                    'Whisk flour with water and stir into the gravy to thicken.',
                    'Garnish with ginger, green chili and lime before serving.',
                ],
            ],
            [
                'slug' => 'pasta',
                'title' => 'Creamy Garlic Butter Pasta',
                'cuisine' => 'Italian',
                'difficulty' => 'Easy',
                'prep' => 10, 'cook' => 15, 'servings' => 4, 'calories' => 560,
                'likes_count' => 892, 'comments_count' => 41, 'reel_seconds' => 38,
                'video_url' => $sample.'ForBiggerEscapes.mp4',
                'tags' => ['Italian', 'Quick', 'Vegetarian'],
                'ingredients' => [
                    '300g fettuccine',
                    '4 tbsp butter',
                    '6 cloves garlic, minced',
                    '1 cup heavy cream',
                    '1/2 cup parmesan, grated',
                    'Salt, pepper, parsley',
                ],
                'steps' => [
                    'Boil pasta in salted water until al dente; reserve 1 cup pasta water.',
                    'Melt butter, sauté garlic until golden and fragrant.',
                    'Pour in cream, simmer gently for 3 minutes.',
                    'Toss in pasta and parmesan, loosen with pasta water as needed.',
                    'Finish with parsley, season, and serve immediately.',
                ],
            ],
            [
                'slug' => 'curry',
                'title' => 'Thai Green Curry',
                'cuisine' => 'Thai',
                'difficulty' => 'Medium',
                'prep' => 15, 'cook' => 25, 'servings' => 4, 'calories' => 480,
                'likes_count' => 734, 'comments_count' => 29, 'reel_seconds' => 52,
                'video_url' => $sample.'ForBiggerFun.mp4',
                'tags' => ['Thai', 'Spicy', 'Dairy-free'],
                'ingredients' => [
                    '3 tbsp green curry paste',
                    '400ml coconut milk',
                    '300g chicken thigh, sliced',
                    '1 eggplant, cubed',
                    'Thai basil leaves',
                    'Fish sauce, palm sugar',
                ],
                'steps' => [
                    'Fry curry paste in a splash of coconut milk until fragrant.',
                    'Add chicken, cook until sealed.',
                    'Pour in remaining coconut milk, add eggplant, simmer 15 minutes.',
                    'Season with fish sauce and palm sugar to taste.',
                    'Stir through Thai basil just before serving.',
                ],
            ],
            [
                'slug' => 'lava',
                'title' => 'Chocolate Lava Cake',
                'cuisine' => 'Dessert',
                'difficulty' => 'Easy',
                'prep' => 15, 'cook' => 12, 'servings' => 4, 'calories' => 390,
                'likes_count' => 2104, 'comments_count' => 158, 'reel_seconds' => 41,
                'video_url' => $sample.'ForBiggerJoyrides.mp4',
                'tags' => ['Dessert', 'Chocolate', '30-min'],
                'ingredients' => [
                    '200g dark chocolate',
                    '200g butter',
                    '4 eggs + 4 yolks',
                    '150g sugar',
                    '80g flour',
                    'Butter and cocoa for ramekins',
                ],
                'steps' => [
                    'Melt chocolate and butter together until smooth.',
                    'Whisk eggs, yolks and sugar until pale and thick.',
                    'Fold chocolate mixture into eggs, then fold in flour.',
                    'Pour into buttered ramekins, chill 15 minutes.',
                    'Bake at 220°C for 12 minutes until edges set, centre stays soft.',
                ],
            ],
            [
                'slug' => 'chicken',
                'title' => 'Grilled Lemon Herb Chicken',
                'cuisine' => 'Healthy',
                'difficulty' => 'Easy',
                'prep' => 15, 'cook' => 20, 'servings' => 4, 'calories' => 340,
                'likes_count' => 611, 'comments_count' => 22, 'reel_seconds' => 35,
                'video_url' => $sample.'ForBiggerMeltdowns.mp4',
                'tags' => ['Healthy', 'High-protein', 'Grilled'],
                'ingredients' => [
                    '4 chicken breasts',
                    '2 lemons, juiced and zested',
                    '3 tbsp olive oil',
                    '2 cloves garlic, minced',
                    'Fresh rosemary and thyme',
                    'Salt and pepper',
                ],
                'steps' => [
                    'Whisk lemon juice, zest, oil, garlic and herbs into a marinade.',
                    'Marinate chicken for at least 30 minutes.',
                    'Grill over medium-high heat, 6-7 minutes per side.',
                    'Rest for 5 minutes before slicing.',
                    'Serve with extra lemon wedges.',
                ],
            ],
        ];
    }
}
