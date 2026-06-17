import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart_delivery/features/disbursement/controllers/disbursement_controller.dart';
import 'package:sixam_mart_delivery/features/disbursement/domain/models/disbursement_report_model.dart';
import 'package:sixam_mart_delivery/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart_delivery/features/profile/domain/models/profile_model.dart';
import 'package:sixam_mart_delivery/helper/date_converter_helper.dart';
import 'package:sixam_mart_delivery/helper/price_converter_helper.dart';
import 'package:sixam_mart_delivery/util/dimensions.dart';
import 'package:sixam_mart_delivery/util/styles.dart';
import 'package:sixam_mart_delivery/common/widgets/custom_app_bar_widget.dart';

class AsaasSaqueScreen extends StatefulWidget {
  const AsaasSaqueScreen({super.key});

  @override
  State<AsaasSaqueScreen> createState() => _AsaasSaqueScreenState();
}

class _AsaasSaqueScreenState extends State<AsaasSaqueScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final ctrl = Get.find<DisbursementController>();
    ctrl.getPixAccount();
    ctrl.getDisbursementReport(1);
    Get.find<ProfileController>().getProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomAppBarWidget(title: 'Financeiro', isBackButtonExist: true),
      body: GetBuilder<DisbursementController>(builder: (ctrl) {
        return GetBuilder<ProfileController>(builder: (profileCtrl) {
          final profile = profileCtrl.profileModel;
          final available       = profile?.withDrawableBalance ?? 0.0;
          final cashInHand      = profile?.payableBalance ?? 0.0;
          final totalEarning    = profile?.totalEarning ?? 0.0;
          final totalWithdrawn  = profile?.totalWithdrawn ?? 0.0;
          final pendingWithdraw = profile?.pendingWithdraw ?? 0.0;
          final balance         = profile?.balance ?? 0.0;
          final commissionPct   = profile?.dmCommissionPercentage ?? 0.0;
          final parcelPct       = profile?.parcelDmPercentage ?? 0.0;
          final totalCommission = profile?.totalCommissionPaid ?? 0.0;
          final adjustable      = profile?.adjustable ?? false;
          final adjCashToPay    = profile?.adjustmentCashToPay ?? 0.0;
          final adjPixAfter     = profile?.adjustmentPixAfter ?? 0.0;
          final adjRemCash      = profile?.adjustmentRemainingCash ?? 0.0;
          final adjType         = profile?.adjustmentType ?? 'none';

          return RefreshIndicator(
            onRefresh: () async {
              await ctrl.getPixAccount();
              await ctrl.getDisbursementReport(1);
              await profileCtrl.getProfile();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Resumo do dinheiro ─────────────────────────────────
                  _buildMoneyBreakdown(context, ctrl, profileCtrl,
                    available: available,
                    cashInHand: cashInHand,
                    totalEarning: totalEarning,
                    totalWithdrawn: totalWithdrawn,
                    pendingWithdraw: pendingWithdraw,
                    balance: balance,
                    totalCommission: totalCommission,
                    adjustable: adjustable,
                    adjCashToPay: adjCashToPay,
                    adjPixAfter: adjPixAfter,
                    adjRemCash: adjRemCash,
                    adjType: adjType,
                  ),
                  const SizedBox(height: Dimensions.paddingSizeDefault),

                  // ── Taxas da Plataforma ────────────────────────────────
                  _buildCommissionCard(context, commissionPct, parcelPct),
                  const SizedBox(height: Dimensions.paddingSizeDefault),

                  // ── PIX Key Section ────────────────────────────────────
                  _buildPixSection(context, ctrl),
                  const SizedBox(height: Dimensions.paddingSizeDefault),

                  // ── Request Saque Section ──────────────────────────────
                  if (ctrl.pixAccount?.hasAccount == true)
                    _buildSaqueSection(context, ctrl, available),

                  const SizedBox(height: Dimensions.paddingSizeDefault),

                  // ── History ───────────────────────────────────────────
                  _buildHistory(context, ctrl),
                ],
              ),
            ),
          );
        });
      }),
    );
  }

  // ── Resumo do dinheiro + ajuste ──────────────────────────────────────────
  Widget _buildMoneyBreakdown(
    BuildContext context,
    DisbursementController ctrl,
    ProfileController profileCtrl, {
    required double available,
    required double cashInHand,
    required double totalEarning,
    required double totalWithdrawn,
    required double pendingWithdraw,
    required double balance,
    required double totalCommission,
    required bool adjustable,
    required double adjCashToPay,
    required double adjPixAfter,
    required double adjRemCash,
    required String adjType,
  }) {
    final dmEarnPct = (profile(profileCtrl)?.dmCommissionPercentage ?? 0);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Header ──────────────────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeDefault,
              vertical: Dimensions.paddingSizeSmall),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(Dimensions.radiusDefault),
              topRight: Radius.circular(Dimensions.radiusDefault),
            ),
          ),
          child: Row(children: [
            const Icon(Icons.account_balance_wallet, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('Meu Dinheiro',
                style: robotoBold.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeDefault)),
          ]),
        ),

        Padding(
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ── Saldo líquido no sistema ───────────────────────────────────
            _summaryRow(context, label: 'Total ganho (acumulado)', value: PriceConverterHelper.convertPrice(totalEarning), icon: Icons.trending_up, iconColor: Colors.green),
            const Divider(height: 16),
            _summaryRow(context, label: 'Total sacado', value: PriceConverterHelper.convertPrice(totalWithdrawn), icon: Icons.done_all, iconColor: Colors.blue, isNegative: true),
            _summaryRow(context, label: 'Saques em processo', value: PriceConverterHelper.convertPrice(pendingWithdraw), icon: Icons.hourglass_empty, iconColor: Colors.orange, isNegative: true),
            if (totalCommission > 0)
              _summaryRow(context, label: 'Taxas pagas (estimado)', value: PriceConverterHelper.convertPrice(totalCommission), icon: Icons.percent, iconColor: Colors.red.shade400, isNegative: true),
            const Divider(height: 16),
            _summaryRow(context, label: 'Saldo no sistema', value: PriceConverterHelper.convertPrice(balance), icon: Icons.savings, iconColor: Theme.of(context).primaryColor, bold: true),
            const SizedBox(height: 14),

            // ── Três cards: PIX, Dinheiro em mãos, Taxas ─────────────────
            Row(children: [

              // Disponível para saque PIX
              Expanded(
                child: _highlightCard(context,
                  label: 'Disponível\npara saque PIX',
                  value: available,
                  color: Theme.of(context).primaryColor,
                  icon: Icons.pix,
                  subtitle: available > 0 ? 'Pode sacar via PIX' : null,
                ),
              ),
              const SizedBox(width: 10),

              // Dinheiro em mãos
              Expanded(
                child: _highlightCard(context,
                  label: 'Dinheiro\nem mãos',
                  value: cashInHand,
                  color: cashInHand > 0 ? Colors.red.shade600 : Colors.grey,
                  icon: Icons.payments,
                  subtitle: cashInHand > 0 ? 'A repassar\nà plataforma' : null,
                ),
              ),

            ]),

            // Explicação: por que não pode sacar se cashInHand >= available
            if (cashInHand > 0 && available == 0 && balance > 0) ...[
              const SizedBox(height: 10),
              _infoBox(context,
                color: Colors.red.shade600,
                icon: Icons.info_outline,
                message:
                  'Você está com ${PriceConverterHelper.convertPrice(cashInHand)} em dinheiro em mãos. '
                  'Todo o seu saldo (${PriceConverterHelper.convertPrice(balance)}) é compensado pelo dinheiro que você possui. '
                  'Faça o Ajuste de Pagamento para liberar o saque via PIX.',
              ),
            ] else if (cashInHand > 0 && available > 0) ...[
              const SizedBox(height: 10),
              _infoBox(context,
                color: Colors.amber.shade700,
                icon: Icons.warning_amber_rounded,
                message:
                  'Você tem ${PriceConverterHelper.convertPrice(cashInHand)} em dinheiro. '
                  'Isso já foi descontado do seu saldo disponível.\n'
                  'Para quitar o dinheiro em mãos e ajustar a conta, use o botão abaixo.',
              ),
            ],

            // ── Botão Ajuste de Pagamento ─────────────────────────────────
            if (adjustable) ...[
              const SizedBox(height: 14),
              const Divider(),
              const SizedBox(height: 10),
              Text('Ajuste de Pagamento',
                  style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault)),
              const SizedBox(height: 8),

              // Explicação do que vai acontecer
              _buildAdjustmentPreview(context, adjCashToPay, adjPixAfter, adjRemCash, adjType, cashInHand, balance),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: ctrl.isAdjustLoading
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.swap_horiz),
                  label: Text(
                    ctrl.isAdjustLoading ? 'Processando...' : 'Realizar ajuste de pagamento',
                    style: robotoMedium.copyWith(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
                  ),
                  onPressed: ctrl.isAdjustLoading
                      ? null
                      : () => _confirmAdjustment(context, ctrl, profileCtrl,
                            adjCashToPay: adjCashToPay,
                            adjPixAfter: adjPixAfter,
                            adjRemCash: adjRemCash,
                            adjType: adjType,
                          ),
                ),
              ),
            ],

          ]),
        ),
      ]),
    );
  }

  ProfileModel? profile(ProfileController c) => c.profileModel;

  Widget _buildAdjustmentPreview(
    BuildContext context,
    double adjCashToPay,
    double adjPixAfter,
    double adjRemCash,
    String adjType,
    double cashInHand,
    double balance,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
        border: Border.all(color: Colors.orange.withOpacity(0.4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.info_outline, color: Colors.orange.shade800, size: 16),
          const SizedBox(width: 6),
          Text('O que vai acontecer:',
              style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Colors.orange.shade900)),
        ]),
        const SizedBox(height: 8),

        // Step 1: entregar dinheiro
        _adjustStep(context, '1', Icons.payments,
          'Você entrega ${PriceConverterHelper.convertPrice(adjCashToPay)} em dinheiro para a plataforma.',
          Colors.red.shade700),
        const SizedBox(height: 6),

        // Step 2: resultado
        if (adjType == 'full' || adjPixAfter > 0)
          _adjustStep(context, '2', Icons.pix,
            'Seu saldo disponível para saque PIX fica em ${PriceConverterHelper.convertPrice(adjPixAfter)}.',
            Theme.of(context).primaryColor)
        else if (adjRemCash > 0)
          _adjustStep(context, '2', Icons.warning_amber_rounded,
            'Você ainda terá ${PriceConverterHelper.convertPrice(adjRemCash)} de dinheiro em mãos para quitar depois.',
            Colors.orange.shade700),

        // Commission note
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 28),
          child: Text(
            '⚠️ Taxa da plataforma já foi descontada no cálculo do seu saldo.',
            style: robotoRegular.copyWith(
                fontSize: Dimensions.fontSizeExtraSmall,
                color: Theme.of(context).disabledColor),
          ),
        ),
      ]),
    );
  }

  Widget _adjustStep(BuildContext context, String step, IconData icon, String text, Color color) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      CircleAvatar(
        radius: 10,
        backgroundColor: color.withOpacity(0.15),
        child: Text(step, style: robotoMedium.copyWith(fontSize: 10, color: color)),
      ),
      const SizedBox(width: 8),
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 6),
      Expanded(
        child: Text(text,
            style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: color)),
      ),
    ]);
  }

  void _confirmAdjustment(
    BuildContext context,
    DisbursementController ctrl,
    ProfileController profileCtrl, {
    required double adjCashToPay,
    required double adjPixAfter,
    required double adjRemCash,
    required String adjType,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar Ajuste de Pagamento'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.swap_horiz, color: Colors.orange, size: 48),
          const SizedBox(height: 12),
          _dialogRow('Você entrega em dinheiro:', PriceConverterHelper.convertPrice(adjCashToPay), Colors.red.shade700),
          if (adjPixAfter > 0)
            _dialogRow('Saldo PIX após ajuste:', PriceConverterHelper.convertPrice(adjPixAfter), Colors.green.shade700),
          if (adjRemCash > 0)
            _dialogRow('Dinheiro restante a quitar:', PriceConverterHelper.convertPrice(adjRemCash), Colors.orange.shade700),
          const SizedBox(height: 10),
          Text('A taxa da plataforma já está descontada do cálculo.',
              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).disabledColor),
              textAlign: TextAlign.center),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: Text('Cancelar', style: robotoMedium.copyWith(color: Theme.of(context).disabledColor))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade700),
            onPressed: () async {
              Navigator.pop(context);
              await ctrl.makeWalletAdjustment();
              await profileCtrl.getProfile();
            },
            child: Text('Confirmar', style: robotoMedium.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _dialogRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall)),
        Text(value, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: valueColor)),
      ]),
    );
  }

  Widget _infoBox(BuildContext context, {required Color color, required IconData icon, required String message}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Expanded(
          child: Text(message,
              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: color)),
        ),
      ]),
    );
  }

  // ── Resumo Financeiro Completo (old full summary) ────────────────────────
  Widget _buildFullSummary(
    BuildContext context,
    double totalEarning,
    double totalWithdrawn,
    double pendingWithdraw,
    double balance,
    double available,
    double cashInHand,
  ) {
    // Kept for internal reference — not used in main build anymore
    return const SizedBox.shrink();
  }
  Widget _summaryRow(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    bool isNegative = false,
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label,
              style: (bold ? robotoBold : robotoRegular).copyWith(
                  fontSize: Dimensions.fontSizeSmall)),
        ),
        Text(
          '${isNegative ? '- ' : ''}$value',
          style: (bold ? robotoBold : robotoMedium).copyWith(
            fontSize: Dimensions.fontSizeSmall,
            color: isNegative
                ? Colors.red.shade600
                : (bold ? Theme.of(context).primaryColor : null),
          ),
        ),
      ]),
    );
  }

  Widget _highlightCard(
    BuildContext context, {
    required String label,
    required double value,
    required Color color,
    required IconData icon,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: Text(label,
                  style: robotoRegular.copyWith(
                      fontSize: Dimensions.fontSizeExtraSmall,
                      color: Theme.of(context).disabledColor)),
            ),
          ]),
          const SizedBox(height: 6),
          Text(
            PriceConverterHelper.convertPrice(value),
            style: robotoBold.copyWith(
                fontSize: Dimensions.fontSizeDefault, color: color),
          ),
          if (subtitle != null)
            Text(subtitle,
                style: robotoRegular.copyWith(
                    fontSize: Dimensions.fontSizeExtraSmall,
                    color: color.withOpacity(0.8))),
        ],
      ),
    );
  }

  // ── Taxas da Plataforma ─────────────────────────────────────────────────
  Widget _buildCommissionCard(
      BuildContext context, double commissionPct, double parcelPct) {
    final dmEarnsPct = parcelPct > 0 ? parcelPct : (100 - commissionPct).clamp(0.0, 100.0);
    final platformEarnsPct = (100 - dmEarnsPct).clamp(0.0, 100.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        border: Border.all(
            color: Theme.of(context).disabledColor.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.percent, color: Theme.of(context).primaryColor, size: 18),
          const SizedBox(width: 8),
          Text('Taxas da Plataforma',
              style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault)),
        ]),
        const SizedBox(height: 12),

        _commissionRow(
          context,
          title: 'Encomenda',
          subtitle: 'Sua parte do valor total',
          platformPct: platformEarnsPct,
          dmPct: dmEarnsPct,
        ),

        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.06),
            borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
          ),
          child: Row(children: [
            const Icon(Icons.lightbulb_outline, color: Colors.blue, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Exemplo: para uma encomenda de ${PriceConverterHelper.convertPrice(100)}, '
                'você recebe ${PriceConverterHelper.convertPrice(100 * dmEarnsPct / 100)} '
                '(${dmEarnsPct.toStringAsFixed(0)}%).',
                style: robotoRegular.copyWith(
                    fontSize: Dimensions.fontSizeExtraSmall,
                    color: Colors.blue.shade800),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _commissionRow(
    BuildContext context, {
    required String title,
    required String subtitle,
    required double platformPct,
    required double dmPct,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: robotoMedium.copyWith(
                  fontSize: Dimensions.fontSizeSmall)),
          Text(subtitle,
              style: robotoRegular.copyWith(
                  fontSize: Dimensions.fontSizeExtraSmall,
                  color: Theme.of(context).disabledColor)),
        ]),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(
          flex: dmPct.round().clamp(1, 99),
          child: Container(
            height: 28,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                bottomLeft: Radius.circular(4),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              'Você ${dmPct.toStringAsFixed(0)}%',
              style: robotoMedium.copyWith(
                  color: Colors.white,
                  fontSize: Dimensions.fontSizeExtraSmall),
            ),
          ),
        ),
        Expanded(
          flex: platformPct.round().clamp(1, 99),
          child: Container(
            height: 28,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.25),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              'Plataforma ${platformPct.toStringAsFixed(0)}%',
              style: robotoRegular.copyWith(
                  color: Theme.of(context).disabledColor,
                  fontSize: Dimensions.fontSizeExtraSmall),
            ),
          ),
        ),
      ]),
    ]);
  }

  // ── PIX Section ──────────────────────────────────────────────────────────
  Widget _buildPixSection(BuildContext context, DisbursementController ctrl) {
    // Still loading
    if (ctrl.isPixLoading) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(16),
        child: CircularProgressIndicator(),
      ));
    }

    // Not loaded yet (initial state before first API call returns)
    if (!ctrl.pixLoaded && !ctrl.pixLoadError) {
      return const SizedBox.shrink();
    }

    // API failed — show retry instead of the registration form
    if (ctrl.pixLoadError) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.05),
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Column(children: [
          const Icon(Icons.cloud_off_outlined, color: Colors.red, size: 36),
          const SizedBox(height: 8),
          Text('Não foi possível carregar os dados da chave PIX.',
              style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => ctrl.getPixAccount(),
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar novamente'),
          ),
        ]),
      );
    }

    final hasAccount = ctrl.pixAccount?.hasAccount == true;
    final data = ctrl.pixAccount?.data;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Chave PIX',
          style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
      const SizedBox(height: Dimensions.paddingSizeSmall),

      if (hasAccount && data != null) ...[
        // ── Registered & Locked ──────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.07),
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            border: Border.all(color: Colors.green.withOpacity(0.4)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.lock, color: Colors.green, size: 18),
              const SizedBox(width: 6),
              Text('Chave registrada',
                  style: robotoMedium.copyWith(color: Colors.green)),
            ]),
            const SizedBox(height: 8),
            _pixInfoRow(context, 'Chave', data.pixKey ?? ''),
            if (data.pixKeyType != null)
              _pixInfoRow(context, 'Tipo', data.pixKeyType!),
            if (data.holderName != null && data.holderName!.isNotEmpty)
              _pixInfoRow(context, 'Titular', data.holderName!),
            if (data.holderDocument != null && data.holderDocument!.isNotEmpty)
              _pixInfoRow(context, 'Documento', data.holderDocument!),
            const Divider(height: 16),
            Text(
              '🔒 Esta chave não pode ser alterada. Para redefinir, solicite ao administrador.',
              style: robotoRegular.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: Theme.of(context).disabledColor),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: ctrl.isPixResetLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(
                        ctrl.pixResetRequested
                            ? Icons.check_circle_outline
                            : Icons.help_outline,
                        color: ctrl.pixResetRequested
                            ? Colors.green
                            : Colors.orange,
                        size: 18,
                      ),
                label: Text(
                  ctrl.pixResetRequested
                      ? 'Solicitação enviada ✓'
                      : 'Pedir alteração da chave PIX',
                  style: robotoMedium.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                    color: ctrl.pixResetRequested
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: ctrl.pixResetRequested
                        ? Colors.green.shade400
                        : Colors.orange.shade400,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onPressed: (ctrl.isPixResetLoading || ctrl.pixResetRequested)
                    ? null
                    : () => ctrl.requestPixReset(),
              ),
            ),
          ]),
        ),
      ] else ...[
        // ── Registration Form ────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            border: Border.all(
                color: Theme.of(context).disabledColor.withOpacity(0.3)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Warning banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.15),
                borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                border: Border.all(color: Colors.amber.withOpacity(0.6)),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '⚠️ ATENÇÃO: Após cadastrar a chave PIX, ela NÃO poderá ser alterada. '
                    'Certifique-se de que os dados estão corretos antes de confirmar. '
                    'Apenas o administrador poderá redefinir sua chave PIX.',
                    style: robotoMedium.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: Colors.amber[900]),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 14),

            // Tipo da chave
            Text('Tipo de chave PIX',
                style: robotoMedium.copyWith(
                    fontSize: Dimensions.fontSizeSmall)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingSizeSmall),
              decoration: BoxDecoration(
                border: Border.all(
                    color: Theme.of(context).disabledColor.withOpacity(0.4)),
                borderRadius:
                    BorderRadius.circular(Dimensions.radiusSmall),
              ),
              child: DropdownButton<String>(
                value: ctrl.selectedPixKeyType,
                isExpanded: true,
                underline: const SizedBox(),
                items: ctrl.pixKeyTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => ctrl.setPixKeyType(v!),
              ),
            ),
            const SizedBox(height: 10),

            // Chave
            _buildField('Chave PIX', ctrl.pixKeyController,
                hint: _pixKeyHint(ctrl.selectedPixKeyType),
                focusNode: ctrl.pixKeyFocusNode,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.next),
            const SizedBox(height: 10),

            // Nome do titular (opcional)
            _buildField('Nome do titular (opcional)',
                ctrl.pixHolderNameController,
                focusNode: ctrl.pixHolderNameFocusNode,
                textInputAction: TextInputAction.next),
            const SizedBox(height: 10),

            // Documento (opcional)
            _buildField('CPF/CNPJ do titular (opcional)',
                ctrl.pixHolderDocController,
                focusNode: ctrl.pixHolderDocFocusNode,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: ctrl.isPixLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.check),
                label: Text(
                  ctrl.isPixLoading
                      ? 'Cadastrando...'
                      : 'Cadastrar chave PIX',
                  style: robotoMedium.copyWith(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(Dimensions.radiusSmall)),
                ),
                onPressed: ctrl.isPixLoading
                    ? null
                    : () => _confirmAndRegister(context, ctrl),
              ),
            ),
          ]),
        ),
      ],
    ]);
  }

  Widget _pixInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        Text('$label: ',
            style: robotoMedium.copyWith(
                fontSize: Dimensions.fontSizeSmall)),
        Expanded(
          child: Text(value,
              style: robotoRegular.copyWith(
                  fontSize: Dimensions.fontSizeSmall)),
        ),
      ]),
    );
  }

  String _pixKeyHint(String type) {
    switch (type) {
      case 'CPF':
        return '000.000.000-00';
      case 'CNPJ':
        return '00.000.000/0000-00';
      case 'EMAIL':
        return 'email@exemplo.com';
      case 'PHONE':
        return '+5511999999999';
      case 'EVP':
        return 'chave aleatória';
      default:
        return '';
    }
  }

  Widget _buildField(String label, TextEditingController controller,
      {String? hint, FocusNode? focusNode, TextInputType? keyboardType, TextInputAction? textInputAction}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall)),
      const SizedBox(height: 6),
      TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: robotoRegular.copyWith(
              fontSize: Dimensions.fontSizeSmall,
              color: Get.theme.disabledColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
          ),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeSmall, vertical: 12),
        ),
      ),
    ]);
  }

  void _confirmAndRegister(
      BuildContext context, DisbursementController ctrl) {
    final key = ctrl.pixKeyController.text.trim();
    if (key.isEmpty) {
      showCustomSnackBar(context, 'Informe a chave PIX');
      return;
    }
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar cadastro'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.warning_amber_rounded,
              color: Colors.amber, size: 48),
          const SizedBox(height: 12),
          Text(
            'Você está prestes a cadastrar a chave PIX:\n\n'
            '"$key" (${ctrl.selectedPixKeyType})\n\n'
            'Após confirmar, esta chave NÃO poderá ser alterada sem intervenção do administrador.',
            textAlign: TextAlign.center,
            style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar',
                  style: robotoMedium.copyWith(
                      color: Theme.of(context).disabledColor))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor),
            onPressed: () {
              Navigator.pop(context);
              ctrl.registerPixAccount();
            },
            child: Text('Confirmar',
                style: robotoMedium.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void showCustomSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // ── Saque Request ────────────────────────────────────────────────────────
  Widget _buildSaqueSection(
      BuildContext context, DisbursementController ctrl, double available) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Solicitar saque',
          style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
      const SizedBox(height: Dimensions.paddingSizeSmall),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          border: Border.all(
              color: Theme.of(context).disabledColor.withOpacity(0.3)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            'Saldo disponível: ${PriceConverterHelper.convertPrice(available)}',
            style: robotoMedium.copyWith(
                fontSize: Dimensions.fontSizeDefault,
                color: Theme.of(context).primaryColor),
          ),
          const SizedBox(height: 12),
          Text('Valor do saque',
              style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall)),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(
              child: TextFormField(
                controller: ctrl.saqueAmountController,
                focusNode: ctrl.saqueAmountFocusNode,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: '0,00',
                  prefixText: 'R\$ ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.paddingSizeSmall, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {
                ctrl.saqueAmountController.text =
                    available.toStringAsFixed(2).replaceAll('.', ',');
              },
              child: Text('Máximo',
                  style: robotoMedium.copyWith(
                      color: Theme.of(context).primaryColor)),
            ),
          ]),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: ctrl.isSaqueLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.send),
              label: Text(
                ctrl.isSaqueLoading ? 'Enviando...' : 'Solicitar saque',
                style: robotoMedium.copyWith(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: available > 0
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).disabledColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(Dimensions.radiusSmall)),
              ),
              onPressed: (ctrl.isSaqueLoading || available <= 0)
                  ? null
                  : () => ctrl.requestSaque(availableBalance: available),
            ),
          ),
          if (available <= 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(children: [
                Text(
                  'Você não tem saldo disponível para saque.',
                  style: robotoRegular.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: Theme.of(context).disabledColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Se você tem dinheiro em mãos, realize o Ajuste de Pagamento acima para liberar o saldo.',
                  style: robotoRegular.copyWith(
                      fontSize: Dimensions.fontSizeExtraSmall,
                      color: Colors.orange.shade700),
                  textAlign: TextAlign.center,
                ),
              ]),
            ),
        ]),
      ),
    ]);
  }

  // ── History Tabs ─────────────────────────────────────────────────────────
  Widget _buildHistory(BuildContext context, DisbursementController ctrl) {
    final disbursements = ctrl.disbursementReportModel?.disbursements ?? [];
    final pending =
        disbursements.where((d) => d.status == 'pending').toList();
    final completed =
        disbursements.where((d) => d.status == 'completed').toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Histórico de saques',
          style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
      const SizedBox(height: Dimensions.paddingSizeSmall),
      TabBar(
        controller: _tabController,
        labelStyle: robotoMedium,
        unselectedLabelStyle: robotoRegular,
        labelColor: Theme.of(context).primaryColor,
        unselectedLabelColor: Theme.of(context).disabledColor,
        indicatorColor: Theme.of(context).primaryColor,
        tabs: [
          Tab(text: 'Pendentes (${pending.length})'),
          Tab(text: 'Concluídos (${completed.length})'),
        ],
      ),
      const SizedBox(height: 8),
      SizedBox(
        height: 300,
        child: TabBarView(
          controller: _tabController,
          children: [
            _disbursementList(context, pending, Colors.orange),
            _disbursementList(context, completed, Colors.green),
          ],
        ),
      ),
    ]);
  }

  Widget _disbursementList(
      BuildContext context, List<Disbursements> items, Color statusColor) {
    if (items.isEmpty) {
      return Center(
        child: Text('Nenhum registro',
            style: robotoRegular.copyWith(
                color: Theme.of(context).disabledColor)),
      );
    }
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => Divider(
          height: 1,
          color: Theme.of(context).disabledColor.withOpacity(0.4)),
      itemBuilder: (context, index) {
        final d = items[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: statusColor.withOpacity(0.12),
            child: Icon(
              d.status == 'completed'
                  ? Icons.check
                  : Icons.hourglass_bottom,
              color: statusColor,
              size: 18,
            ),
          ),
          title: Text(
            PriceConverterHelper.convertPrice(d.disbursementAmount ?? 0),
            style: robotoMedium,
          ),
          subtitle: Text(
            d.createdAt != null
                ? DateConverterHelper.dateTimeStringForDisbursement(d.createdAt!)
                : '',
            style: robotoRegular.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: Theme.of(context).disabledColor),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
            ),
            child: Text(
              d.status == 'pending' ? 'Pendente' : 'Concluído',
              style: robotoMedium.copyWith(
                  fontSize: Dimensions.fontSizeExtraSmall,
                  color: statusColor),
            ),
          ),
        );
      },
    );
  }
}
