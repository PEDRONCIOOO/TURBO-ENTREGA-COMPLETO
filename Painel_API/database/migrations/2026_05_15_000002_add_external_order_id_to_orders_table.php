<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->string('external_reference_id')->nullable()->after('id')
                ->comment('ID do pedido gerado pelo sistema externo (remetente)');
            $table->foreignId('api_token_id')->nullable()->after('external_reference_id')
                ->constrained('user_api_tokens')->onDelete('set null')
                ->comment('Token de API usado para criar o pedido');
        });
    }

    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->dropForeign(['api_token_id']);
            $table->dropColumn(['external_reference_id', 'api_token_id']);
        });
    }
};
