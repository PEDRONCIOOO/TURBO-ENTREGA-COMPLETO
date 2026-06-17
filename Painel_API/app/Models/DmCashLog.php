<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class DmCashLog extends Model
{
    protected $table = 'dm_cash_logs';

    protected $fillable = [
        'delivery_man_id',
        'order_id',
        'type',
        'amount',
        'order_amount',
        'collected_cash_after',
        'digital_balance_after',
        'note',
    ];

    protected $casts = [
        'amount'                => 'float',
        'order_amount'          => 'float',
        'collected_cash_after'  => 'float',
        'digital_balance_after' => 'float',
    ];

    // ─── Relacionamentos ──────────────────────────────────────────────────────

    public function delivery_man()
    {
        return $this->belongsTo(DeliveryMan::class, 'delivery_man_id');
    }

    public function order()
    {
        return $this->belongsTo(Order::class, 'order_id');
    }

    // ─── Labels para exibição ────────────────────────────────────────────────

    public function getTypeLabelAttribute(): string
    {
        return match ($this->type) {
            'cash_assigned'      => 'Dinheiro Atribuído',
            'adjustment_partial' => 'Ajuste Parcial',
            'adjustment_full'    => 'Ajuste Completo',
            default              => $this->type,
        };
    }

    public function getTypeBadgeAttribute(): string
    {
        return match ($this->type) {
            'cash_assigned'      => 'warning',
            'adjustment_partial' => 'info',
            'adjustment_full'    => 'success',
            default              => 'secondary',
        };
    }
}
