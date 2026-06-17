<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('order_additional_stops', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('order_id');
            $table->unsignedTinyInteger('sequence')->default(1);
            $table->json('delivery_address');
            $table->string('delivery_instruction', 500)->nullable();
            $table->decimal('distance_km', 10, 4)->default(0);
            $table->decimal('extra_delivery_charge', 10, 2)->default(0);
            $table->string('status', 20)->default('pending'); // pending, delivered, failed
            $table->timestamp('delivered_at')->nullable();
            $table->timestamps();

            $table->foreign('order_id')
                ->references('id')
                ->on('orders')
                ->onDelete('cascade');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('order_additional_stops');
    }
};
