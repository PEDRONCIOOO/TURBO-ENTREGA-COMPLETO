import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/parcel/controllers/parcel_controller.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/styles.dart';

class WhyChooseSectionWidget extends StatelessWidget {
  const WhyChooseSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ParcelController>(builder: (parcelController) {
      final whyChoose = parcelController.whyChooseDetails;
      if (whyChoose == null || whyChoose.banners == null || whyChoose.banners!.isEmpty) {
        return const SizedBox.shrink();
      }

      final banners = whyChoose.banners!;
      final bool isDesktop = ResponsiveHelper.isDesktop(context);

      return Container(
        margin: EdgeInsets.only(top: isDesktop ? 24 : 16),
        padding: EdgeInsets.all(isDesktop ? 20 : 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: Theme.of(context).brightness == Brightness.dark
                ? [
                    Theme.of(context).cardColor,
                    Theme.of(context).cardColor.withValues(alpha: 0.8),
                  ]
                : [
                    Theme.of(context).primaryColor.withValues(alpha: 0.06),
                    Theme.of(context).primaryColor.withValues(alpha: 0.02),
                  ],
          ),
          borderRadius: BorderRadius.circular(isDesktop ? 20 : 16),
          border: Theme.of(context).brightness == Brightness.dark
              ? Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.1))
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Por que escolher a Turbo?',
              style: robotoBold.copyWith(fontSize: isDesktop ? 16 : 15, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Entrega simples em ${banners.length} passos',
              style: robotoRegular.copyWith(fontSize: isDesktop ? 12 : 11, color: Theme.of(context).disabledColor),
            ),
            SizedBox(height: isDesktop ? 16 : 12),
            isDesktop
                ? Row(
                    children: List.generate(banners.length, (index) {
                      final banner = banners[index];
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: index < banners.length - 1 ? 12 : 0),
                          child: _StepCard(
                            stepNumber: index + 1,
                            title: banner.title ?? '',
                            description: banner.shortDescription ?? '',
                          ),
                        ),
                      );
                    }),
                  )
                : Column(
                    children: List.generate(banners.length, (index) {
                      final banner = banners[index];
                      return Padding(
                        padding: EdgeInsets.only(bottom: index < banners.length - 1 ? 10 : 0),
                        child: _StepCardMobile(
                          stepNumber: index + 1,
                          title: banner.title ?? '',
                          description: banner.shortDescription ?? '',
                        ),
                      );
                    }),
                  ),
          ],
        ),
      );
    });
  }
}

class _StepCard extends StatelessWidget {
  final int stepNumber;
  final String title;
  final String description;

  const _StepCard({
    required this.stepNumber,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).scaffoldBackgroundColor : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.08)) : null,
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$stepNumber',
                style: robotoBold.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: robotoBold.copyWith(fontSize: 12),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: robotoRegular.copyWith(
              fontSize: 10,
              color: Theme.of(context).disabledColor,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _StepCardMobile extends StatelessWidget {
  final int stepNumber;
  final String title;
  final String description;

  const _StepCardMobile({
    required this.stepNumber,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).scaffoldBackgroundColor : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: isDark ? Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.08)) : null,
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$stepNumber',
                style: robotoBold.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: robotoBold.copyWith(fontSize: 13, height: 1.3),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: robotoRegular.copyWith(
                    fontSize: 11,
                    color: Theme.of(context).disabledColor,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
