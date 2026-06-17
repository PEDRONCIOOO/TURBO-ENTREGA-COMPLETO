<?php

namespace App\Http\Controllers\Admin;

use App\Models\DmCashLog;
use App\Models\DeliveryMan;
use Illuminate\Http\Request;
use App\Http\Controllers\Controller;

class DmCashLogController extends Controller
{
    /**
     * Listagem paginada dos logs de dinheiro em mãos.
     */
    public function index(Request $request)
    {
        $dm_id    = $request->dm_id;
        $type     = $request->type;
        $dateFrom = $request->date_from;
        $dateTo   = $request->date_to;

        $logs = DmCashLog::with(['delivery_man', 'order'])
            ->when($dm_id, fn($q) => $q->where('delivery_man_id', $dm_id))
            ->when($type,  fn($q) => $q->where('type', $type))
            ->when($dateFrom, fn($q) => $q->whereDate('created_at', '>=', $dateFrom))
            ->when($dateTo,   fn($q) => $q->whereDate('created_at', '<=', $dateTo))
            ->latest()
            ->paginate(config('default_pagination', 25))
            ->appends(request()->query());

        $delivery_men = DeliveryMan::select('id', 'f_name', 'l_name')->orderBy('f_name')->get();

        // Totais do filtro atual (sem paginação)
        $totals = DmCashLog::when($dm_id, fn($q) => $q->where('delivery_man_id', $dm_id))
            ->when($type,  fn($q) => $q->where('type', $type))
            ->when($dateFrom, fn($q) => $q->whereDate('created_at', '>=', $dateFrom))
            ->when($dateTo,   fn($q) => $q->whereDate('created_at', '<=', $dateTo))
            ->selectRaw("
                SUM(CASE WHEN type = 'cash_assigned'      THEN amount ELSE 0 END) as total_assigned,
                SUM(CASE WHEN type LIKE 'adjustment_%'    THEN amount ELSE 0 END) as total_adjusted,
                COUNT(*)                                                           as total_records
            ")
            ->first();

        return view('admin-views.dm-cash-log.index', compact('logs', 'delivery_men', 'totals'));
    }

    /**
     * Detalhes de um entregador específico.
     */
    public function show(Request $request, $dm_id)
    {
        $dm = DeliveryMan::with('wallet')->findOrFail($dm_id);

        $logs = DmCashLog::with('order')
            ->where('delivery_man_id', $dm_id)
            ->latest()
            ->paginate(config('default_pagination', 25));

        return view('admin-views.dm-cash-log.show', compact('dm', 'logs'));
    }
}
