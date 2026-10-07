<?php

namespace App\Http\Controllers;

use App\Models\HaccpLog;
use Illuminate\Http\Request;

/**
 * Digital HACCP checklist — temperature and hygiene entries a Restaurant Pro
 * kitchen keeps for inspections. Entries are an append-only log, not an
 * editable record, matching how a physical inspection binder works.
 */
class HaccpController extends Controller
{
    public function index(Request $request)
    {
        $request->validate(['store_id' => 'nullable|integer']);

        $query = $request->user()->haccpLogs()->latest();

        if ($request->filled('store_id')) {
            $query->where('store_id', $request->integer('store_id'));
        }

        $logs = $query->limit(200)->get();

        return response()->json([
            'success' => true,
            'data' => $logs->map->toApiArray()->values(),
            'fail_count' => $logs->where('status', 'fail')->count(),
        ]);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'type' => 'required|string|in:' . implode(',', HaccpLog::TYPES),
            'label' => 'required|string|max:120',
            'value' => 'nullable|string|max:64',
            'status' => 'required|string|in:' . implode(',', HaccpLog::STATUSES),
            'logged_by' => 'nullable|string|max:120',
            'notes' => 'nullable|string|max:500',
            'store_id' => 'nullable|integer',
        ]);

        $user = $request->user();

        if (! empty($data['store_id']) && ! $user->stores()->whereKey($data['store_id'])->exists()) {
            return response()->json([
                'success' => false,
                'message' => 'That location does not belong to this account.',
            ], 422);
        }

        $log = $user->haccpLogs()->create($data);

        return response()->json(['success' => true, 'data' => $log->toApiArray()], 201);
    }
}
