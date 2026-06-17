<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('delivery_man_pix_accounts', function (Blueprint $table) {
            $table->id();
            $table->foreignId('delivery_man_id')->unique();
            $table->string('pix_key', 191);
            $table->string('pix_key_type', 20)->nullable();
            $table->string('holder_name', 191)->nullable();
            $table->string('holder_document', 30)->nullable();
            $table->tinyInteger('is_verified')->default(0);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('delivery_man_pix_accounts');
    }
};
