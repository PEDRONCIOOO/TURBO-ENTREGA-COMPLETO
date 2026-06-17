<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class DeliveryManPixAccount extends Model
{
    use HasFactory;

    protected $fillable = [
        'delivery_man_id',
        'pix_key',
        'pix_key_type',
        'holder_name',
        'holder_document',
        'is_verified',
        'pix_reset_requested',
        'pix_reset_requested_at',
    ];

    protected $casts = [
        'delivery_man_id'        => 'integer',
        'is_verified'            => 'boolean',
        'pix_reset_requested'    => 'boolean',
        'pix_reset_requested_at' => 'datetime',
    ];

    public function deliveryMan()
    {
        return $this->belongsTo(DeliveryMan::class, 'delivery_man_id');
    }
}
