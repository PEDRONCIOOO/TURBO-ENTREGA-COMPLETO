<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('delivery_man_pix_accounts', function (Blueprint $table) {
            $table->boolean('pix_reset_requested')->default(false)->after('is_verified');
            $table->timestamp('pix_reset_requested_at')->nullable()->after('pix_reset_requested');
        });
    }

    public function down(): void
    {
        Schema::table('delivery_man_pix_accounts', function (Blueprint $table) {
            $table->dropColumn(['pix_reset_requested', 'pix_reset_requested_at']);
        });
    }
};
