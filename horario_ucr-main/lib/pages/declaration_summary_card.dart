import 'package:flutter/material.dart';
import '../theme/ucr_colors.dart';

/// Pending follows the existing dashboard count, including drafts.
bool matchesDeclarationStatus(String status, String filter) => switch (filter) {
      'TODOS' => true,
      'PENDIENTES' => status != 'FINALIZADA' && status != 'ANULADA',
      _ => status == filter,
    };

class DeclarationSummaryCard extends StatelessWidget {
  final String label;
  final int count;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;
  const DeclarationSummaryCard(
      {super.key,
      required this.label,
      required this.count,
      required this.accent,
      required this.onTap,
      this.selected = false});

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        onTap: onTap,
        label: '$label: $count. Abrir trámites con este filtro',
        excludeSemantics: true,
        child: Material(
          color: selected ? UcrColors.background : UcrColors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
              side: BorderSide(
                  color: accent.withValues(alpha: selected ? 0.9 : 0.38),
                  width: selected ? 2 : 1.35)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(children: [
                CircleAvatar(
                    radius: 22,
                    backgroundColor: accent,
                    child: Text('$count',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 23,
                            fontWeight: FontWeight.w800))),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                      Text(label,
                          style: const TextStyle(
                              color: UcrColors.blue,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                      const Text('Ver trámites',
                          style:
                              TextStyle(color: UcrColors.muted, fontSize: 14)),
                    ])),
                const Icon(Icons.chevron_right, color: UcrColors.blue),
              ]),
            ),
          ),
        ),
      );
}
