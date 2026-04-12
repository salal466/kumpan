import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';

/// Expandable teaching guide with step-by-step pairing instructions.
class TeachingGuide extends StatelessWidget {
  final AppStrings strings;

  const TeachingGuide({super.key, required this.strings});

  @override
  Widget build(BuildContext context) {
    final steps = [
      strings.step1,
      strings.step2,
      strings.step3,
      strings.step4,
      strings.step5,
      strings.step6,
      strings.step7,
    ];

    final stepIcons = [
      Icons.power_settings_new_rounded,
      Icons.menu_rounded,
      Icons.key_rounded,
      Icons.toggle_on_rounded,
      Icons.touch_app_rounded,
      Icons.hourglass_top_rounded,
      Icons.check_circle_rounded,
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.white10,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          childrenPadding:
              const EdgeInsets.only(left: 20, right: 20, bottom: 16),
          leading: const Icon(
            Icons.help_outline_rounded,
            color: Colors.white38,
          ),
          title: Text(
            strings.teachingGuide,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          iconColor: Colors.white38,
          collapsedIconColor: Colors.white38,
          children: [
            Text(
              strings.teachingTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(steps.length, (index) {
              final isLast = index == steps.length - 1;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isLast
                            ? const Color(0xFF4CAF50).withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.08),
                        border: Border.all(
                          color: isLast
                              ? const Color(0xFF4CAF50).withValues(alpha: 0.4)
                              : Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Center(
                        child: isLast
                            ? Icon(
                                stepIcons[index],
                                size: 18,
                                color: const Color(0xFF4CAF50),
                              )
                            : Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          steps[index],
                          style: TextStyle(
                            color: isLast
                                ? const Color(0xFF4CAF50)
                                : Colors.white70,
                            fontSize: 14,
                            fontWeight: isLast
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
