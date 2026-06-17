<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Adiciona coluna que define o percentual cobrado por parada adicional de entrega.
     * Ex.: 40 = cobra 40% do valor base por cada parada extra.
     */
    public function up(): void
    {
        Schema::table('parcel_categories', function (Blueprint $table) {
            if (!Schema::hasColumn('parcel_categories', 'extra_stop_percentage')) {
                $table->decimal('extra_stop_percentage', 5, 2)
                    ->default(40.00)
                    ->comment('Percentual da taxa principal cobrado por parada adicional (ex: 40 = 40%)')
                    ->after('fractional_rounding');
            }
        });
    }

    public function down(): void
    {
        Schema::table('parcel_categories', function (Blueprint $table) {
            if (Schema::hasColumn('parcel_categories', 'extra_stop_percentage')) {
                $table->dropColumn('extra_stop_percentage');
            }
        });
    }
};
