<?php

namespace App\Http\Controllers\Admin;

use App\CentralLogics\Helpers;
use App\Http\Controllers\Controller;
use App\Models\ParcelCategory;
use App\Models\Translation;
use Illuminate\Http\Request;
use Brian2694\Toastr\Facades\Toastr;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Config;

class ParcelCategoryController extends Controller
{
    /**
     * Display a listing of the resource.
     *
     * @return \Illuminate\Http\Response
     */
    public function index(Request $request)
    {
        $module_id = Config::get('module.current_module_id');
        $taxData = Helpers::getTaxSystemType(getTaxVatList: true, tax_payer: 'parcel');
        $categoryWiseTax = $taxData['categoryWiseTax'];
        $parcel_categories = ParcelCategory::
        when($module_id, function($query)use($module_id){
            $query->Module($module_id);
        })
        ->with($categoryWiseTax ? ['taxVats.tax'] : [])
        ->orderBy('name')->paginate(config('default_pagination'));
        $taxVats = $taxData['taxVats'];

        return view('admin-views.parcel.category.index',compact('parcel_categories','categoryWiseTax','taxVats'));
    }

    /**
     * Show the form for creating a new resource.
     *
     * @return \Illuminate\Http\Response
     */
    public function create()
    {
        //
    }

    /**
     * Store a newly created resource in storage.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\Response
     */
    public function store(Request $request)
{
    $request->validate([
        'name'      => 'required|array',
        'name.0'    => 'unique:parcel_categories,name',
        'name.*'    => 'max:191|unique:parcel_categories,name',
        'image'     => 'required|image',
        'description'   => 'required|array',
        'description.0' => 'required',

        'parcel_per_km_shipping_charge'   => 'required_with:parcel_minimum_shipping_charge|numeric|min:0',
        'parcel_minimum_shipping_charge'  => 'required_with:parcel_per_km_shipping_charge|numeric|min:0',

        'minimum_shipping_distance_km'    => 'nullable|numeric|min:0',

        'km_from'      => 'nullable|array',
        'km_from.*'    => 'nullable|numeric|min:0',
        'km_to'        => 'nullable|array',
        'km_to.*'      => 'nullable|numeric|min:0',
        'km_price'     => 'nullable|array',
        'km_price.*'   => 'nullable|numeric|min:0',

        'fractional_rounding' => 'nullable|in:floor,ceil',

        'name.0'        => 'required',
        'description.0' => 'required',
    ],[
        'name.0.required'        => translate('default_name_is_required'),
        'description.0.required' => translate('default_description_is_required'),
    ]);

    // Montar regras por faixa de km
    $distanceRules = [];
    $froms  = $request->km_from ?? [];
    $tos    = $request->km_to ?? [];
    $prices = $request->km_price ?? [];
    $returnPrices = $request->km_return_price ?? [];

    foreach ($froms as $index => $fromKm) {
        $toKm        = $tos[$index]          ?? null;
        $priceKm     = $prices[$index]       ?? null;
        $returnPrice = $returnPrices[$index] ?? null;

        // Ignora linha totalmente vazia
        if ($fromKm === null && $toKm === null && $priceKm === null && $returnPrice === null) {
            continue;
        }

        $distanceRules[] = [
            'from'               => $fromKm !== null ? (float)$fromKm : null,
            'to'                 => $toKm   !== null ? (float)$toKm   : null,
            'price_per_km'       => $priceKm !== null ? (float)$priceKm : 0,
            'return_price_per_km'=> $returnPrice !== null ? (float)$returnPrice : 0,
        ];
    }

    $parcel_category = new ParcelCategory;
    $parcel_category->module_id = Config::get('module.current_module_id');
    $parcel_category->name = $request->name[array_search('default', $request->lang)];
    $parcel_category->description =  $request->description[array_search('default', $request->lang)];
    $parcel_category->image = Helpers::upload('parcel_category/', 'png', $request->file('image'));

    $parcel_category->parcel_per_km_shipping_charge  = $request->parcel_per_km_shipping_charge;
    $parcel_category->parcel_minimum_shipping_charge = $request->parcel_minimum_shipping_charge;

    // NOVOS CAMPOS
    $parcel_category->minimum_shipping_distance_km = $request->minimum_shipping_distance_km ?? 0;
    $parcel_category->distance_pricing_rules       = $distanceRules;
    $parcel_category->charge_fractional_km         = $request->has('charge_fractional_km');
    $parcel_category->fractional_rounding          = $request->fractional_rounding ?? 'ceil';
    $parcel_category->extra_stop_percentage        = $request->extra_stop_percentage ?? 40;
    $parcel_category->extra_stop_fee_basis         = in_array($request->extra_stop_fee_basis, ['main_fee', 'extra_distance'])
        ? $request->extra_stop_fee_basis
        : 'main_fee';

    $parcel_category->save();

    if(addon_published_status('TaxModule')){
        $SystemTaxVat= \Modules\TaxModule\Entities\SystemTaxSetup::where('is_active',1)
            ->where('tax_payer','parcel')->where('is_default',1)->first();
        if($SystemTaxVat?->tax_type == 'category_wise'){
            foreach($request['tax_ids'] ?? [] as $tax_ids){
                \Modules\TaxModule\Entities\Taxable::create(
                    [
                        'taxable_type'       => ParcelCategory::class,
                        'taxable_id'         => $parcel_category->id,
                        'system_tax_setup_id'=> $SystemTaxVat->id,
                        'tax_id'             => $tax_ids
                    ],
                );
            }
        }
    }

    $data = [];
    $default_lang = str_replace('_', '-', app()->getLocale());
    foreach ($request->lang as $index => $key) {
        if($default_lang == $key && !($request->name[$index])){
            if ($key != 'default') {
                array_push($data, array(
                    'translationable_type' => 'App\Models\ParcelCategory',
                    'translationable_id'   => $parcel_category->id,
                    'locale'               => $key,
                    'key'                  => 'name',
                    'value'                => $parcel_category->name,
                ));
            }
        }else{
            if ($request->name[$index] && $key != 'default') {
                array_push($data, array(
                    'translationable_type' => 'App\Models\ParcelCategory',
                    'translationable_id'   => $parcel_category->id,
                    'locale'               => $key,
                    'key'                  => 'name',
                    'value'                => $request->name[$index],
                ));
            }
        }

        if($default_lang == $key && !($request->description[$index])){
            if (isset($parcel_category->description) && $key != 'default') {
                array_push($data, array(
                    'translationable_type' => 'App\Models\ParcelCategory',
                    'translationable_id'   => $parcel_category->id,
                    'locale'               => $key,
                    'key'                  => 'description',
                    'value'                => $parcel_category->description,
                ));
            }
        }else{
            if ($request->description[$index] && $key != 'default') {
                array_push($data, array(
                    'translationable_type' => 'App\Models\ParcelCategory',
                    'translationable_id'   => $parcel_category->id,
                    'locale'               => $key,
                    'key'                  => 'description',
                    'value'                => $request->description[$index],
                ));
            }
        }
    }
    Translation::insert($data);

    Toastr::success(translate('messages.parcel_category_added_successfully'));
    return back();
}


    /**
     * Display the specified resource.
     *
     * @param  int  $id
     * @return \Illuminate\Http\Response
     */
    public function show($id)
    {
        //
    }

    /**
     * Show the form for editing the specified resource.
     *
     * @param  int  $id
     * @return \Illuminate\Http\Response
     */
    public function edit($id)
    {
        $parcel_category= ParcelCategory::withoutGlobalScope('translate')->findOrFail($id);

        $taxData = Helpers::getTaxSystemType(getTaxVatList: true, tax_payer: 'parcel');
        $categoryWiseTax = $taxData['categoryWiseTax'];
        $taxVats = $taxData['taxVats'];
        $taxVatIds =  $categoryWiseTax ? $parcel_category->taxVats()->pluck('tax_id')->toArray(): [];
        return view('admin-views.parcel.category.edit',compact('parcel_category','categoryWiseTax','taxVats','taxVatIds'));
    }

    /**
     * Update the specified resource in storage.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  int  $id
     * @return \Illuminate\Http\Response
     */
  public function update(Request $request, $id)
{
    $request->validate([
        'name'      => 'required|array',
        'name.0'    => 'unique:parcel_categories,name,'.$id,
        'name.*'    => 'max:191',
        'description'   => 'required|array',

        'parcel_per_km_shipping_charge'   => 'required_with:parcel_minimum_shipping_charge|numeric|min:0',
        'parcel_minimum_shipping_charge'  => 'required_with:parcel_per_km_shipping_charge|numeric|min:0',

        // GLOBAL retorno (topo)
        'parcel_per_km_return_shipping_charge' => 'nullable|numeric|min:0',

        'minimum_shipping_distance_km'    => 'nullable|numeric|min:0',

        'km_from'      => 'nullable|array',
        'km_from.*'    => 'nullable|numeric|min:0',
        'km_to'        => 'nullable|array',
        'km_to.*'      => 'nullable|numeric|min:0',
        'km_price'     => 'nullable|array',
        'km_price.*'   => 'nullable|numeric|min:0',

        // NOVO: retorno por faixa
        'km_return_price'     => 'nullable|array',
        'km_return_price.*'   => 'nullable|numeric|min:0',

        'fractional_rounding' => 'nullable|in:floor,ceil',

        'name.0'        => 'required',
        'description.0' => 'required',
    ],[
        'name.0.required'        => translate('default_name_is_required'),
        'description.0.required' => translate('default_description_is_required'),
    ]);

    // Montar regras por faixa de km
    $distanceRules = [];
    $froms  = $request->km_from ?? [];
    $tos    = $request->km_to ?? [];
    $prices = $request->km_price ?? [];

    // NOVO: retorno por faixa
    $returnPrices = $request->km_return_price ?? [];

    foreach ($froms as $index => $fromKm) {
        $toKm        = $tos[$index] ?? null;
        $priceKm     = $prices[$index] ?? null;
        $returnPrice = $returnPrices[$index] ?? null;

        if ($fromKm === null && $toKm === null && $priceKm === null && $returnPrice === null) {
            continue;
        }

        $distanceRules[] = [
            'from'               => $fromKm !== null ? (float)$fromKm : null,
            'to'                 => $toKm   !== null ? (float)$toKm   : null,
            'price_per_km'       => $priceKm !== null ? (float)$priceKm : 0,

            // NOVO: retorno por faixa
            'return_price_per_km'=> $returnPrice !== null ? (float)$returnPrice : 0,
        ];
    }

    $parcel_category = ParcelCategory::findOrFail($id);
    $parcel_category->name = $request->name[array_search('default', $request->lang)];
    $parcel_category->description =  $request->description[array_search('default', $request->lang)];
    $parcel_category->image = Helpers::update('parcel_category/', $parcel_category->image, 'png', $request->file('image'));

    $parcel_category->parcel_per_km_shipping_charge  = $request->parcel_per_km_shipping_charge;

    // GLOBAL retorno (topo)
    $parcel_category->parcel_per_km_return_shipping_charge = $request->parcel_per_km_return_shipping_charge ?? 0;

    $parcel_category->parcel_minimum_shipping_charge = $request->parcel_minimum_shipping_charge;

    // CAMPOS EXISTENTES
    $parcel_category->minimum_shipping_distance_km = $request->minimum_shipping_distance_km ?? 0;

    // JSON das faixas (agora com return_price_per_km)
    $parcel_category->distance_pricing_rules       = $distanceRules;

    $parcel_category->charge_fractional_km         = $request->has('charge_fractional_km');
    $parcel_category->fractional_rounding          = $request->fractional_rounding ?? 'ceil';

    // ENTREGA ADICIONAL
    $parcel_category->extra_stop_percentage        = $request->extra_stop_percentage ?? 40;
    $parcel_category->extra_stop_fee_basis         = in_array($request->extra_stop_fee_basis, ['main_fee', 'extra_distance'])
        ? $request->extra_stop_fee_basis
        : 'main_fee';

    $parcel_category->save();

    if(addon_published_status('TaxModule') && $parcel_category['position'] == 0){
        $taxVatIds   = $parcel_category->taxVats()->pluck('tax_id')->toArray() ?? [];
        $newTaxVatIds = array_map('intval', $request['tax_ids'] ?? []);
        sort($newTaxVatIds);
        sort($taxVatIds);
        if( $newTaxVatIds != $taxVatIds ){
            $parcel_category->taxVats()->delete();
            $SystemTaxVat= \Modules\TaxModule\Entities\SystemTaxSetup::where('is_active',1)
                ->where('tax_payer','parcel')->where('is_default',1)->first();
            if($SystemTaxVat?->tax_type == 'category_wise'){
                foreach($request['tax_ids'] ?? [] as $tax_ids){
                    \Modules\TaxModule\Entities\Taxable::create(
                        [
                            'taxable_type'       => ParcelCategory::class,
                            'taxable_id'         => $parcel_category->id,
                            'system_tax_setup_id'=> $SystemTaxVat->id,
                            'tax_id'             => $tax_ids
                        ],
                    );
                }
            }
        }
    }

    $default_lang = str_replace('_', '-', app()->getLocale());

    foreach ($request->lang as $index => $key) {
        if($default_lang == $key && !($request->name[$index])){
            if ($key != 'default') {
                Translation::updateOrInsert(
                    [
                        'translationable_type' => 'App\Models\ParcelCategory',
                        'translationable_id'   => $parcel_category->id,
                        'locale'               => $key,
                        'key'                  => 'name'
                    ],
                    ['value' => $parcel_category->name]
                );
            }
        }else{
            if ($request->name[$index] && $key != 'default') {
                Translation::updateOrInsert(
                    [
                        'translationable_type' => 'App\Models\ParcelCategory',
                        'translationable_id'   => $parcel_category->id,
                        'locale'               => $key,
                        'key'                  => 'name'
                    ],
                    ['value' => $request->name[$index]]
                );
            }
        }

        if($default_lang == $key && !($request->description[$index])){
            if (isset($parcel_category->description) && $key != 'default') {
                Translation::updateOrInsert(
                    [
                        'translationable_type' => 'App\Models\ParcelCategory',
                        'translationable_id'   => $parcel_category->id,
                        'locale'               => $key,
                        'key'                  => 'description'
                    ],
                    ['value' => $parcel_category->description]
                );
            }

        }else{

            if ($request->description[$index] && $key != 'default') {
                Translation::updateOrInsert(
                    [
                        'translationable_type' => 'App\Models\ParcelCategory',
                        'translationable_id'   => $parcel_category->id,
                        'locale'               => $key,
                        'key'                  => 'description'
                    ],
                    ['value' => $request->description[$index]]
                );
            }
        }
    }

    Toastr::success(translate('messages.parcel_category_updated_successfully'));
    return back();
}

    /**
     * Remove the specified resource from storage.
     *
     * @param  int  $id
     * @return \Illuminate\Http\Response
     */
    public function destroy($id)
    {
        $parcel_category = ParcelCategory::findOrFail($id);
        if($parcel_category->image)
        {
            Helpers::check_and_delete('parcel_category/' , $parcel_category['image']);
        }
        $parcel_category?->taxVats()->delete();
        $parcel_category->translations()->delete();
        $parcel_category->delete();
        Toastr::success(translate('messages.parcel_category_deleted_successfully'));
        return back();
    }

    public function status(Request $request)
    {
        $parcel_category = ParcelCategory::findOrFail($request->id);
        $parcel_category->status = $request->status;
        $parcel_category->save();
        Toastr::success(translate('messages.parcel_category_status_updated'));
        return back();
    }
}
