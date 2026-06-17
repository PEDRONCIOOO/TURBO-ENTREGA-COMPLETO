import 'package:flutter/material.dart';

class BottomNavItemWidget extends StatelessWidget {
  final String selectedIcon;
  final String unSelectedIcon;
  final String title;
  final Function? onTap;
  final bool isSelected;
  const BottomNavItemWidget({
    super.key,
    this.onTap,
    this.isSelected = false,
    required this.title,
    required this.selectedIcon,
    required this.unSelectedIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap as void Function()?,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFF4870C).withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: title == 'Início'
                    ? Icon(
                        Icons.home_rounded,
                        size: 22,
                        color: isSelected
                            ? const Color(0xFFF4870C)
                            : const Color(0xFF9E9E9E),
                      )
                    : Image.asset(
                        isSelected ? selectedIcon : unSelectedIcon,
                        height: 22,
                        width: 22,
                        color: isSelected
                            ? const Color(0xFFF4870C)
                            : const Color(0xFF9E9E9E),
                      ),
              ),
              const SizedBox(height: 3),
              Text(
                title,
                style: TextStyle(
                  color: isSelected
                      ? const Color(0xFFF4870C)
                      : const Color(0xFF9E9E9E),
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
