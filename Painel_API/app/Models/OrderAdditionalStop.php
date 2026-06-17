<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class OrderAdditionalStop extends Model
{
    use HasFactory;

    protected $fillable = [
        'order_id',
        'sequence',
        'delivery_address',
        'delivery_instruction',
        'distance_km',
        'extra_delivery_charge',
        'status',
        'delivered_at',
    ];

    protected $casts = [
        'delivery_address'      => 'array',
        'sequence'              => 'integer',
        'distance_km'           => 'float',
        'extra_delivery_charge' => 'float',
        'delivered_at'          => 'datetime',
    ];

    public function order()
    {
        return $this->belongsTo(Order::class);
    }
}
