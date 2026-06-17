<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Adiciona coluna que define a base de cálculo da taxa da parada extra:
     *   'main_fee'       → percentual sobre a taxa da ENTREGA PRINCIPAL (padrão)
     *   'extra_distance' → percentual sobre o valor calculado para a DISTÂNCIA DA PARADA EXTRA
     */
    public function up(): void
    {
        Schema::table('parcel_categories', function (Blueprint $table) {
            if (!Schema::hasColumn('parcel_categories', 'extra_stop_fee_basis')) {
                $table->enum('extra_stop_fee_basis', ['main_fee', 'extra_distance'])
                    ->default('main_fee')
                    ->after('extra_stop_percentage');
            }
        });
    }

    public function down(): void
    {
        Schema::table('parcel_categories', function (Blueprint $table) {
            if (Schema::hasColumn('parcel_categories', 'extra_stop_fee_basis')) {
                $table->dropColumn('extra_stop_fee_basis');
            }
        });
    }
};
