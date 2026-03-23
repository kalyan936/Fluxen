import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/currency_service.dart';

class StatsWidget extends StatelessWidget {
  final HistoryResult? history;
  final bool isDark;
  final Color surface, border, muted, text, accent;

  const StatsWidget({
    super.key, required this.history, required this.isDark,
    required this.surface, required this.border, required this.muted,
    required this.text, required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    if (history == null) return const SizedBox.shrink();
    final isUp = history!.changePct >= 0;
    final changeColor = isUp ? const Color(0xFFC8F542) : const Color(0xFFFF4D6D);

    return Row(children: [
      _card('30d low',  history!.min.toStringAsFixed(4), text),
      const SizedBox(width: 8),
      _card('30d high', history!.max.toStringAsFixed(4), text),
      const SizedBox(width: 8),
      _card('30d avg',  history!.avg.toStringAsFixed(4), text),
      const SizedBox(width: 8),
      _card('Change', '${isUp?"+":""}${history!.changePct.toStringAsFixed(2)}%', changeColor),
    ]);
  }

  Widget _card(String label, String value, Color valColor) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label.toUpperCase(),
          style: GoogleFonts.dmMono(fontSize: 8, letterSpacing: 1, color: muted)),
        const SizedBox(height: 4),
        Text(value,
          style: GoogleFonts.dmMono(fontSize: 11, fontWeight: FontWeight.w500, color: valColor)),
      ]),
    ),
  );
}
