import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/features/location/domain/models/prediction_model.dart';
import 'package:sixam_mart/features/parcel/controllers/parcel_controller.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class ExtraDeliveryDialogWidget extends StatefulWidget {
  final double mainDistanceKm;
  final int categoryId;
  final int zoneId;
  final AddressModel pickupAddress;

  const ExtraDeliveryDialogWidget({
    super.key,
    required this.mainDistanceKm,
    required this.categoryId,
    required this.zoneId,
    required this.pickupAddress,
  });

  @override
  State<ExtraDeliveryDialogWidget> createState() =>
      _ExtraDeliveryDialogWidgetState();
}

class _ExtraDeliveryDialogWidgetState
    extends State<ExtraDeliveryDialogWidget> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _houseController   = TextEditingController();
  final TextEditingController _nameController    = TextEditingController();
  final TextEditingController _phoneController   = TextEditingController();

  bool _isCalculating = false;
  String? _errorMessage;
  PredictionModel? _selectedSuggestion;

  @override
  void dispose() {
    _addressController.dispose();
    _houseController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _onConfirm() async {
    if (_selectedSuggestion == null) {
      setState(() => _errorMessage = 'Selecione um endereco.');
      return;
    }

    setState(() {
      _isCalculating = true;
      _errorMessage  = null;
    });

    try {
      final errorBuffer = StringBuffer();
      final entry = await Get.find<ParcelController>().resolveExtraDelivery(
        placeId:             _selectedSuggestion!.placeId ?? '',
        description:         _selectedSuggestion!.description ??
                             _selectedSuggestion!.mainText ??
                             'Endereco',
        mainDistanceKm:      widget.mainDistanceKm,
        categoryId:          widget.categoryId,
        zoneId:              widget.zoneId,
        pickupAddress:       widget.pickupAddress,
        houseNumber:         _houseController.text.trim(),
        contactPersonName:   _nameController.text.trim(),
        contactPersonNumber: _phoneController.text.trim(),
        errorOut:            errorBuffer,
      );

      if (!mounted) return;

      if (entry != null) {
        Get.find<ParcelController>().addExtraDelivery(entry);
        Get.back();
      } else {
        setState(() {
          _isCalculating = false;
          _errorMessage  = errorBuffer.isNotEmpty
              ? errorBuffer.toString()
              : 'Nao foi possivel calcular a entrega extra.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCalculating = false;
          _errorMessage  = 'Erro inesperado. Tente novamente.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabecalho
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Entrega extra',
                    style: robotoBold.copyWith(
                      fontSize: Dimensions.fontSizeLarge,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Taxa calculada de acordo com a distancia e categoria',
                style: robotoMedium.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: Theme.of(context).hintColor,
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeDefault),

              // Rua / Avenida (busca Google Places)
              TypeAheadField<PredictionModel>(
                textFieldConfiguration: TextFieldConfiguration(
                  controller: _addressController,
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.streetAddress,
                  decoration: InputDecoration(
                    hintText: 'Rua / Avenida...',
                    hintStyle: robotoRegular.copyWith(
                        color: Theme.of(context).hintColor),
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(Dimensions.radiusDefault),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.paddingSizeSmall,
                      vertical: 10,
                    ),
                    isDense: true,
                  ),
                ),
                suggestionsCallback: (pattern) async {
                  if (pattern.length < 3) return [];
                  return await Get.find<LocationController>()
                      .searchLocation(context, pattern);
                },
                itemBuilder: (context, PredictionModel suggestion) {
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.location_on, size: 18),
                    title: Text(
                      suggestion.mainText ?? suggestion.description ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: robotoMedium.copyWith(
                          fontSize: Dimensions.fontSizeSmall),
                    ),
                    subtitle: suggestion.secondaryText?.isNotEmpty == true
                        ? Text(
                            suggestion.secondaryText!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: robotoRegular.copyWith(
                              fontSize: Dimensions.fontSizeExtraSmall,
                              color: Theme.of(context).hintColor,
                            ),
                          )
                        : null,
                  );
                },
                onSuggestionSelected: (PredictionModel suggestion) {
                  _addressController.text =
                      suggestion.description ?? suggestion.mainText ?? '';
                  setState(() {
                    _selectedSuggestion = suggestion;
                    _errorMessage       = null;
                  });
                },
                noItemsFoundBuilder: (context) => Padding(
                  padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                  child: Text(
                    'Nenhum endereco encontrado',
                    style: robotoRegular.copyWith(
                        color: Theme.of(context).hintColor),
                  ),
                ),
              ),

              const SizedBox(height: Dimensions.paddingSizeSmall),

              // Numero / complemento
              TextField(
                controller: _houseController,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: 'Numero (ex: 123, Apto 4B)',
                  hintStyle: robotoRegular.copyWith(
                      color: Theme.of(context).hintColor),
                  prefixIcon: const Icon(Icons.pin, size: 20),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(Dimensions.radiusDefault),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeSmall,
                    vertical: 10,
                  ),
                  isDense: true,
                ),
              ),

              const SizedBox(height: Dimensions.paddingSizeSmall),

              // Nome do destinatario
              TextField(
                controller: _nameController,
                keyboardType: TextInputType.name,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'Nome do destinatario',
                  hintStyle: robotoRegular.copyWith(
                      color: Theme.of(context).hintColor),
                  prefixIcon: const Icon(Icons.person_outline, size: 20),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(Dimensions.radiusDefault),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeSmall,
                    vertical: 10,
                  ),
                  isDense: true,
                ),
              ),

              const SizedBox(height: Dimensions.paddingSizeSmall),

              // Telefone (opcional)
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: 'Telefone (opcional)',
                  hintStyle: robotoRegular.copyWith(
                      color: Theme.of(context).hintColor),
                  prefixIcon: const Icon(Icons.phone, size: 20),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(Dimensions.radiusDefault),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeSmall,
                    vertical: 10,
                  ),
                  isDense: true,
                ),
              ),

              const SizedBox(height: Dimensions.paddingSizeDefault),

              // Mensagem de erro
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius:
                        BorderRadius.circular(Dimensions.radiusSmall),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 16),
                      const SizedBox(
                          width: Dimensions.paddingSizeExtraSmall),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: robotoRegular.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeSmall),
              ],

              // Botao Adicionar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(Dimensions.radiusDefault),
                    ),
                    padding: const EdgeInsets.symmetric(
                        vertical: Dimensions.paddingSizeSmall),
                  ),
                  onPressed: _isCalculating ? null : _onConfirm,
                  child: _isCalculating
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Adicionar',
                          style: robotoBold.copyWith(color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
