<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\BusinessSetting;
use App\Models\CustomerAddress;
use App\Models\User;
use App\Models\UserApiToken;
use App\Models\Zone;
use Brian2694\Toastr\Facades\Toastr;
use Illuminate\Http\Request;
use MatanYadaev\EloquentSpatial\Objects\Point;

class UserApiTokenController extends Controller
{
    public function index(Request $request)
    {
        $search = $request->input('search');

        $tokens = UserApiToken::with(['user', 'user.addresses' => function ($q) {
                $q->where('address_type', 'pickup')->latest();
            }])
            ->when($search, function ($q) use ($search) {
                $q->whereHas('user', function ($uq) use ($search) {
                    $uq->where('f_name', 'like', "%$search%")
                       ->orWhere('l_name', 'like', "%$search%")
                       ->orWhere('email', 'like', "%$search%")
                       ->orWhere('phone', 'like', "%$search%");
                })->orWhere('label', 'like', "%$search%");
            })
            ->latest()
            ->paginate(config('default_pagination', 20));

        $apiBaseUrl = BusinessSetting::where('key', 'external_api_base_url')->value('value') ?? '';

        return view('admin-views.api-tokens.index', compact('tokens', 'search', 'apiBaseUrl'));
    }

    public function store(Request $request)
    {
        $request->validate([
            'user_id' => 'required|exists:users,id',
            'label'   => 'nullable|string|max:100',
        ]);

        $user = User::findOrFail($request->user_id);

        // Gera token único
        do {
            $token = UserApiToken::generateToken();
        } while (UserApiToken::where('token', $token)->exists());

        UserApiToken::create([
            'user_id'  => $user->id,
            'token'    => $token,
            'label'    => $request->label ?? 'Token de ' . $user->f_name,
            'is_active'=> true,
        ]);

        Toastr::success(translate('Token de API criado com sucesso!'));
        return back();
    }

    public function toggleStatus(UserApiToken $apiToken)
    {
        $apiToken->update(['is_active' => !$apiToken->is_active]);
        $status = $apiToken->is_active ? 'ativado' : 'desativado';
        Toastr::success("Token $status com sucesso.");
        return back();
    }

    public function destroy(UserApiToken $apiToken)
    {
        // Só permite excluir se não houver saldo reservado
        if ($apiToken->reserved_balance > 0) {
            Toastr::error('Não é possível excluir: token possui saldo reservado em pedidos pendentes (' . number_format($apiToken->reserved_balance, 2, ',', '.') . ').');
            return back();
        }

        $apiToken->delete();
        Toastr::success('Token excluído com sucesso.');
        return back();
    }

    public function searchUsers(Request $request)
    {
        $q = $request->input('q', '');
        $users = User::where(function ($query) use ($q) {
            $query->where('f_name', 'like', "%$q%")
                  ->orWhere('l_name', 'like', "%$q%")
                  ->orWhere('email', 'like', "%$q%")
                  ->orWhere('phone', 'like', "%$q%");
        })->select('id', 'f_name', 'l_name', 'email', 'phone')
          ->limit(15)
          ->get()
          ->map(fn($u) => [
              'id'   => $u->id,
              'text' => $u->f_name . ' ' . $u->l_name . ' (' . ($u->email ?: $u->phone) . ')',
          ]);

        return response()->json(['results' => $users]);
    }

    public function saveBaseUrl(Request $request)
    {
        $request->validate([
            'api_base_url' => 'required|url|max:255',
        ]);

        $url = rtrim($request->api_base_url, '/');

        BusinessSetting::updateOrCreate(
            ['key' => 'external_api_base_url'],
            ['value' => $url]
        );

        Toastr::success(translate('URL base da API salva com sucesso!'));
        return back();
    }

    public function geocodeAddress(Request $request)
    {
        $address = $request->input('address', '');
        if (!$address) {
            return response()->json(['error' => 'Endereço não informado.'], 422);
        }

        $mapKey = \App\Models\BusinessSetting::where('key', 'map_api_key_server')->value('value');
        if (!$mapKey) {
            return response()->json(['error' => 'Chave do Google Maps não configurada no painel.'], 422);
        }

        $response = \Illuminate\Support\Facades\Http::timeout(10)->get(
            'https://maps.googleapis.com/maps/api/geocode/json',
            ['address' => $address, 'key' => $mapKey, 'region' => 'br', 'language' => 'pt-BR']
        );

        $location = data_get($response->json(), 'results.0.geometry.location');

        if (!$location) {
            return response()->json(['error' => 'Endereço não encontrado. Tente ser mais específico.'], 404);
        }

        return response()->json([
            'lat' => round((float) $location['lat'], 7),
            'lng' => round((float) $location['lng'], 7),
        ]);
    }

    public function updatePickupAddress(Request $request, UserApiToken $apiToken)
    {
        $request->validate([
            'pickup_address' => 'required|string|max:500',
            'pickup_lat'     => 'nullable|numeric|between:-90,90',
            'pickup_lng'     => 'nullable|numeric|between:-180,180',
        ]);

        $user = $apiToken->user;

        // Busca a zona geográfica correspondente às coordenadas
        $zoneId = null;
        if ($request->filled('pickup_lat') && $request->filled('pickup_lng')) {
            $zone = Zone::whereContains('coordinates', new Point(
                (float) $request->pickup_lat,
                (float) $request->pickup_lng,
                POINT_SRID
            ))->first(['id']);
            $zoneId = $zone?->id;
        }

        CustomerAddress::updateOrCreate(
            [
                'user_id'      => $user->id,
                'address_type' => 'pickup',
            ],
            [
                'address'   => $request->pickup_address,
                'latitude'  => $request->filled('pickup_lat')  ? (float) $request->pickup_lat  : null,
                'longitude' => $request->filled('pickup_lng')  ? (float) $request->pickup_lng  : null,
                'zone_id'   => $zoneId,
                'contact_person_name'   => $user->f_name . ' ' . $user->l_name,
                'contact_person_number' => $user->phone,
            ]
        );

        Toastr::success(translate('Endereço de retirada atualizado com sucesso!'));
        return back();
    }
}
