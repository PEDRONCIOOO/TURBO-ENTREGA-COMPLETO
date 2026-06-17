<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('user_api_tokens', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->onDelete('cascade');
            $table->string('token', 64)->unique();
            $table->string('label')->nullable()->comment('Descrição/nome do token');
            $table->boolean('is_active')->default(true);
            $table->decimal('reserved_balance', 20, 2)->default(0)->comment('Saldo bloqueado por pedidos pendentes');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('user_api_tokens');
    }
};
