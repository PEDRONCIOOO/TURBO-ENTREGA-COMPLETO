<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Str;

class UserApiToken extends Model
{
    use HasFactory;

    protected $table = 'user_api_tokens';

    protected $guarded = ['id'];

    protected $casts = [
        'is_active'        => 'boolean',
        'reserved_balance' => 'float',
    ];

    protected $hidden = [];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function orders()
    {
        return $this->hasMany(Order::class, 'api_token_id');
    }

    /**
     * Gera um novo token seguro de 64 caracteres.
     */
    public static function generateToken(): string
    {
        return Str::random(64);
    }
}
