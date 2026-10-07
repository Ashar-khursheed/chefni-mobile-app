<?php

namespace Database\Seeders;

use App\Models\InventoryItem;
use App\Models\User;
use Illuminate\Database\Seeder;

class InventorySeeder extends Seeder
{
    public function run(): void
    {
        $users = User::whereIn('email', ['user@chefni.app', 'creator@chefni.app'])->get();

        $items = [
            ['All-Purpose Flour', '500', 'g', 45],
            ['Cooking Oil', '1.5', 'litres', 90],
            ['Plain Yogurt', '150', 'g', 2],
            ['Chefni Spice Mix', '3', 'packets', 120],
        ];

        foreach ($users as $user) {
            foreach ($items as [$name, $quantity, $unit, $daysToExpiry]) {
                InventoryItem::updateOrCreate(
                    ['user_id' => $user->id, 'name' => $name],
                    [
                        'quantity' => $quantity,
                        'unit' => $unit,
                        'expiry_date' => now()->addDays($daysToExpiry),
                        'is_expiring' => $daysToExpiry <= 7,
                    ]
                );
            }
        }
    }
}
