<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\DeliveryMan;
use App\Models\DMReview;
use App\Models\Order;
use Illuminate\Support\Facades\Cache;

class PlatformStatsController extends Controller
{
    public function index()
    {
        $stats = Cache::remember('platform_stats', 300, function () {
            $activeDeliverymen = DeliveryMan::active()->count();
            $totalDeliveries = Order::delivered()->count();
            $avgRating = DMReview::avg('rating');

            return [
                'active_deliverymen' => $activeDeliverymen,
                'total_deliveries' => $totalDeliveries,
                'avg_rating' => round($avgRating ?? 0, 1),
            ];
        });

        return response()->json($stats);
    }
}
