# Parcel Home Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign the ParcelCategoryScreen (parcel module home) with premium visual styling — gradient banner, PT-BR titles, gradient icon cards, and a "Why Choose" section replacing the drone GIF.

**Architecture:** Edit 2 existing files (parcel_category_screen.dart, deliver_item_card_widget.dart), create 1 new widget (why_choose_section_widget.dart), delete 1 obsolete file (user_location_map_widget.dart), add i18n keys to messages.php. All changes are visual/UI — no business logic changes.

**Tech Stack:** Flutter/Dart, GetX state management, CarouselSlider package

**Spec:** `docs/superpowers/specs/2026-08-05-parcel-home-redesign-design.md`

---

### Task 1: Add i18n translation keys

**Files:**
- Modify: `Painel_API/resources/lang/pt/messages.php` (before closing `);`)

- [ ] **Step 1: Add new translation keys**

Add these 3 keys before the closing `);` in `messages.php`:

```php
'what_do_you_need_to_send' => 'O que você precisa enviar?',
'choose_your_delivery_category' => 'Escolha a categoria da sua entrega',
'why_choose_us' => 'Por que escolher a Turbo?',
```

- [ ] **Step 2: Commit**

```bash
git add Painel_API/resources/lang/pt/messages.php
git commit -m "feat: add PT-BR i18n keys for parcel home redesign"
```

---

### Task 2: Create WhyChooseSectionWidget

**Files:**
- Create: `Cliente/lib/features/parcel/widgets/why_choose_section_widget.dart`

**Context:**
- `ParcelController.whyChooseDetails` is of type `WhyChooseModel?`
- `WhyChooseModel` has `List<Banners>? banners`
- Each `Banners` has: `String? title`, `String? shortDescription`, `String? imageFullUrl`

- [ ] **Step 1: Create the widget file**

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/parcel/controllers/parcel_controller.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';

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

      return Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'why_choose_us'.tr,
              style: robotoBold.copyWith(fontSize: 14),
            ),
            const SizedBox(height: 12),
            ...banners.map((banner) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  banner.imageFullUrl != null && banner.imageFullUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: CustomImage(
                            image: banner.imageFullUrl!,
                            height: 32,
                            width: 32,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Container(
                          height: 32,
                          width: 32,
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_rounded,
                            size: 18,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (banner.title != null)
                          Text(
                            banner.title!,
                            style: robotoBold.copyWith(fontSize: 13),
                          ),
                        if (banner.shortDescription != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            banner.shortDescription!,
                            style: robotoRegular.copyWith(
                              fontSize: 11,
                              color: Theme.of(context).disabledColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      );
    });
  }
}
```

- [ ] **Step 2: Verify build compiles**

Run: `cd Cliente && C:/flutter/bin/flutter build web --no-pub 2>&1 | tail -5`
Expected: No errors related to `why_choose_section_widget.dart`

- [ ] **Step 3: Commit**

```bash
git add Cliente/lib/features/parcel/widgets/why_choose_section_widget.dart
git commit -m "feat: create WhyChooseSectionWidget with API-driven content"
```

---

### Task 3: Update DeliverItemCardWidget — gradient icon container

**Files:**
- Modify: `Cliente/lib/features/parcel/widgets/deliver_item_card_widget.dart:23-46`

- [ ] **Step 1: Update border color logic**

In `deliver_item_card_widget.dart`, replace the border in the card's BoxDecoration (line 23-26):

```dart
// OLD
        border: Border.all(
          color: isDeliverItem
              ? primaryColor.withValues(alpha: 0.08)
              : Colors.grey.shade200,
        ),

// NEW
        border: Border.all(
          color: isDeliverItem
              ? primaryColor.withValues(alpha: 0.15)
              : primaryColor.withValues(alpha: 0.06),
        ),
```

- [ ] **Step 2: Update icon container to use gradient**

Replace the icon container's `decoration` (line 43-45):

```dart
// OLD
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),

// NEW
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryColor.withValues(alpha: 0.12),
                  primaryColor.withValues(alpha: 0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
```

- [ ] **Step 3: Verify build**

Run: `cd Cliente && C:/flutter/bin/flutter build web --no-pub 2>&1 | tail -5`
Expected: No errors

- [ ] **Step 4: Commit**

```bash
git add Cliente/lib/features/parcel/widgets/deliver_item_card_widget.dart
git commit -m "feat: add gradient icon container and refined borders to delivery cards"
```

---

### Task 4: Update ParcelCategoryScreen — scaffold, banner, titles, wire WhyChoose

**Files:**
- Modify: `Cliente/lib/features/parcel/screens/parcel_category_screen.dart:1-163`

This is the main task. Multiple edits in sequence.

- [ ] **Step 1: Update imports**

Replace the `user_location_map_widget` import (line 22):

```dart
// OLD
import 'package:sixam_mart/features/parcel/widgets/user_location_map_widget.dart';

// NEW
import 'package:sixam_mart/features/parcel/widgets/why_choose_section_widget.dart';
```

- [ ] **Step 2: Add scaffold background color**

Change the Scaffold at line 56:

```dart
// OLD
    return Scaffold(
      appBar: ResponsiveHelper.isDesktop(context) ? null : const ParcelAppBarWidget(),

// NEW
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: ResponsiveHelper.isDesktop(context) ? null : const ParcelAppBarWidget(),
```

- [ ] **Step 3: Replace banner section with premium styling**

Replace the entire banner block (lines 76-109) with:

```dart
                      // Banner carousel with premium styling
                      bannerController.parcelOtherBannerModel != null && bannerController.parcelOtherBannerModel!.banners != null
                          ? bannerController.parcelOtherBannerModel!.banners!.isNotEmpty
                              ? Column(children: [
                                  CarouselSlider.builder(
                                    itemCount: bannerController.parcelOtherBannerModel!.banners!.length,
                                    options: CarouselOptions(
                                      autoPlay: true,
                                      height: ResponsiveHelper.isDesktop(context) ? 395 : 140,
                                      enlargeCenterPage: true,
                                      disableCenter: true,
                                      viewportFraction: 1,
                                      autoPlayInterval: const Duration(seconds: 5),
                                      onPageChanged: (index, reason) {
                                        bannerController.setCurrentIndex(index, false);
                                      },
                                    ),
                                    itemBuilder: (context, index, realIndex) {
                                      return ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Stack(children: [
                                          CustomImage(
                                            image: '${bannerController.parcelOtherBannerModel!.banners![index].imageFullUrl}',
                                            height: ResponsiveHelper.isDesktop(context) ? 395 : 140,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                          ),
                                          Positioned.fill(
                                            child: DecoratedBox(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: [
                                                    Colors.transparent,
                                                    Colors.black.withValues(alpha: 0.4),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ]),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(
                                      bannerController.parcelOtherBannerModel!.banners!.length,
                                      (index) => AnimatedContainer(
                                        duration: const Duration(milliseconds: 300),
                                        margin: const EdgeInsets.symmetric(horizontal: 2),
                                        height: 6,
                                        width: bannerController.currentIndex == index ? 20 : 6,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(3),
                                          color: bannerController.currentIndex == index
                                              ? Theme.of(context).primaryColor
                                              : Theme.of(context).primaryColor.withValues(alpha: 0.3),
                                        ),
                                      ),
                                    ),
                                  ),
                                ])
                              // Fallback: gradient hero when no banners
                              : Container(
                                  height: ResponsiveHelper.isDesktop(context) ? 395 : 140,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [Color(0xFFF4870C), Color(0xFFFF6B35)],
                                    ),
                                  ),
                                  child: Stack(children: [
                                    Positioned(right: -10, top: -10, child: Container(
                                      width: 80, height: 80,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withValues(alpha: 0.12),
                                      ),
                                    )),
                                    Positioned(right: 20, bottom: -15, child: Container(
                                      width: 50, height: 50,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withValues(alpha: 0.08),
                                      ),
                                    )),
                                    Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text('Envie qualquer\ncoisa, agora.',
                                            style: robotoBold.copyWith(fontSize: 18, color: Colors.white, height: 1.2)),
                                          const SizedBox(height: 4),
                                          Text('Entrega rápida e segura na sua cidade',
                                            style: robotoRegular.copyWith(fontSize: 12, color: Colors.white.withValues(alpha: 0.85))),
                                        ],
                                      ),
                                    ),
                                  ]),
                                )
                          : Shimmer(
                              duration: const Duration(seconds: 2),
                              enabled: true,
                              child: Container(
                                width: MediaQuery.of(context).size.width,
                                height: ResponsiveHelper.isDesktop(context) ? 395 : 140,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
```

- [ ] **Step 4: Replace title section**

Replace the title/subtitle text (lines 113-117):

```dart
// OLD
                      Text('bringing_happiness_from_door_to_door'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
                      const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                      Text('ready_to_send_something_special'.tr, style: robotoRegular.copyWith(color: Theme.of(context).disabledColor)),
                      const SizedBox(height: Dimensions.paddingSizeLarge),

// NEW
                      Text('what_do_you_need_to_send'.tr, style: robotoBold.copyWith(fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                      Text('choose_your_delivery_category'.tr, style: robotoRegular.copyWith(fontSize: 13, color: Theme.of(context).disabledColor)),
                      const SizedBox(height: Dimensions.paddingSizeLarge),
```

- [ ] **Step 5: Replace UserLocationMapWidget with WhyChooseSectionWidget**

Replace line 148-149:

```dart
// OLD
                          // Adicionando o mapa de localizaÃ§Ã£o do usuÃ¡rio
                          const UserLocationMapWidget(),

// NEW
                          const WhyChooseSectionWidget(),
```

- [ ] **Step 6: Verify build**

Run: `cd Cliente && C:/flutter/bin/flutter build web --no-pub 2>&1 | tail -5`
Expected: No errors

- [ ] **Step 7: Commit**

```bash
git add Cliente/lib/features/parcel/screens/parcel_category_screen.dart
git commit -m "feat: redesign ParcelCategoryScreen with premium banner, PT-BR titles, and WhyChoose section"
```

---

### Task 5: Delete obsolete user_location_map_widget.dart

**Files:**
- Delete: `Cliente/lib/features/parcel/widgets/user_location_map_widget.dart`

- [ ] **Step 1: Verify no other files import it**

Run: `grep -r "user_location_map_widget" Cliente/lib/ --include="*.dart"`
Expected: No results (the only import was in parcel_category_screen.dart, already updated in Task 4)

- [ ] **Step 2: Delete the file**

```bash
rm Cliente/lib/features/parcel/widgets/user_location_map_widget.dart
```

- [ ] **Step 3: Verify build still compiles**

Run: `cd Cliente && C:/flutter/bin/flutter build web --no-pub 2>&1 | tail -5`
Expected: No errors

- [ ] **Step 4: Commit**

```bash
git add Cliente/lib/features/parcel/widgets/user_location_map_widget.dart
git commit -m "chore: remove obsolete user_location_map_widget (was only drone GIF)"
```

---

### Task 6: Visual verification

- [ ] **Step 1: Start the app locally**

Run in separate terminals:
- Terminal 1: `cd Painel_API && C:/xampp/php/php.exe artisan serve --port=8005`
- Terminal 2: `cd Cliente && C:/flutter/bin/flutter run -d chrome --web-port=7878 --web-browser-flag="--disable-web-security"`

- [ ] **Step 2: Verify visually**

Check these on the parcel home screen:
1. Scaffold background is light gray (#FAFAFA)
2. Banner carousel has rounded corners (16px) and gradient overlay
3. Page indicators show below carousel (animated dots, active=wide orange, inactive=small)
4. If no banners: orange gradient hero with motivational text appears
5. Title reads "O que você precisa enviar?" in bold
6. Subtitle reads "Escolha a categoria da sua entrega" in gray
7. Category cards have gradient icon backgrounds (subtle top-left to bottom-right)
8. Card borders are refined (0.15 when deliver item, 0.06 otherwise)
9. "Por que escolher a Turbo?" section appears below categories (if API data exists)
10. No drone GIF anywhere

- [ ] **Step 3: Final commit with all changes**

If any visual tweaks were needed, commit them:
```bash
git add -A
git commit -m "feat: parcel home redesign - visual polish"
```
