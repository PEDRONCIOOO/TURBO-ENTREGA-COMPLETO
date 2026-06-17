<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('disbursement_details', function (Blueprint $table) {
            // payment_method era NOT NULL; entregadores PIX não possuem
            // método de saque — o INSERT falhava com constraint violation.
            $table->unsignedBigInteger('payment_method')->nullable()->default(null)->change();
        });
    }

    public function down(): void
    {
        Schema::table('disbursement_details', function (Blueprint $table) {
            $table->unsignedBigInteger('payment_method')->nullable(false)->change();
        });
    }
};
