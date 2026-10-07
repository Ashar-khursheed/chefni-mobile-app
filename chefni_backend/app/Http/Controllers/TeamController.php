<?php

namespace App\Http\Controllers;

use App\Models\StaffMember;
use Illuminate\Http\Request;

/**
 * Restaurant Pro's kitchen roster — up to 5 people. Ownership is enforced by
 * scoping every query through the authenticated user, matching the rest of
 * the API.
 */
class TeamController extends Controller
{
    private const MAX_STAFF = 5;

    public function index(Request $request)
    {
        $staff = $request->user()
            ->staffMembers()
            ->orderByDesc('is_active')
            ->orderBy('name')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $staff->map->toApiArray()->values(),
            'max_staff' => self::MAX_STAFF,
        ]);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'name' => 'required|string|max:120',
            'role' => 'required|string|in:' . implode(',', StaffMember::ROLES),
            'phone' => 'nullable|string|max:32',
            'store_id' => 'nullable|integer',
        ]);

        $user = $request->user();

        if ($user->staffMembers()->count() >= self::MAX_STAFF) {
            return response()->json([
                'success' => false,
                'message' => 'Restaurant Pro supports up to ' . self::MAX_STAFF . ' staff members.',
            ], 422);
        }

        if (! empty($data['store_id']) && ! $user->stores()->whereKey($data['store_id'])->exists()) {
            return response()->json([
                'success' => false,
                'message' => 'That location does not belong to this account.',
            ], 422);
        }

        $staff = $user->staffMembers()->create([
            'name' => $data['name'],
            'role' => $data['role'],
            'phone' => $data['phone'] ?? null,
            'store_id' => $data['store_id'] ?? null,
            'is_active' => true,
        ]);

        return response()->json(['success' => true, 'data' => $staff->toApiArray()], 201);
    }

    public function update(Request $request, int $id)
    {
        $data = $request->validate([
            'name' => 'sometimes|string|max:120',
            'role' => 'sometimes|string|in:' . implode(',', StaffMember::ROLES),
            'phone' => 'nullable|string|max:32',
            'is_active' => 'sometimes|boolean',
        ]);

        $staff = $this->findOwned($request, $id);
        $staff->update($data);

        return response()->json(['success' => true, 'data' => $staff->fresh()->toApiArray()]);
    }

    public function destroy(Request $request, int $id)
    {
        $this->findOwned($request, $id)->delete();

        return response()->json(['success' => true]);
    }

    private function findOwned(Request $request, int $id): StaffMember
    {
        return $request->user()->staffMembers()->findOrFail($id);
    }
}
