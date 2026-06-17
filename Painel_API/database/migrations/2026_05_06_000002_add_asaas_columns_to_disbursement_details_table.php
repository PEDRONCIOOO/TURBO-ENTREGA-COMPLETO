<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('disbursement_details', function (Blueprint $table) {
            $table->string('payout_provider', 30)->nullable()->after('payment_method');
            $table->string('payout_status', 30)->nullable()->after('payout_provider');
            $table->string('asaas_transfer_id', 191)->nullable()->after('payout_status');
            $table->text('payout_error')->nullable()->after('asaas_transfer_id');
            $table->timestamp('payout_processed_at')->nullable()->after('payout_error');
        });
    }

    public function down(): void
    {
        Schema::table('disbursement_details', function (Blueprint $table) {
            $table->dropColumn([
                'payout_provider',
                'payout_status',
                'asaas_transfer_id',
                'payout_error',
                'payout_processed_at',
            ]);
        });
    }
};
