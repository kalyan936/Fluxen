import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/currency_service.dart';

class ChartWidget extends StatelessWidget {
  final HistoryResult? history;
  final bool loading;
  final String from, to;
  final bool isDark;
  final Color accent, surface, border, muted, text;

  const ChartWidget({
    super.key, required this.history, required this.loading,
    required this.from, required this.to, required this.isDark,
    required this.accent, required this.surface, required this.border,
    required this.muted, required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surface, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Rate history', style: GoogleFonts.syne(
            fontSize: 13, fontWeight: FontWeight.w700, color: text,
          )),
          Text('$from / $to', style: GoogleFonts.dmMono(fontSize: 11, color: muted)),
        ]),
        const SizedBox(height: 14),
        Expanded(child: loading
          ? Center(child: CircularProgressIndicator(color: accent, strokeWidth: 2))
          : history == null || history!.series.isEmpty
            ? Center(child: Text('No history data', style: GoogleFonts.dmMono(fontSize: 12, color: muted)))
            : _buildChart(),
        ),
      ]),
    );
  }

  Widget _buildChart() {
    final spots = history!.series.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.rate))
        .toList();

    final vals = history!.series.map((p) => p.rate).toList();
    final mn = vals.reduce((a,b) => a < b ? a : b);
    final mx = vals.reduce((a,b) => a > b ? a : b);
    final pad = (mx - mn) * 0.1;
    final grid = isDark ? const Color(0xFF222232) : const Color(0xFFEEEEF5);

    return LineChart(LineChartData(
      minY: mn - pad, maxY: mx + pad,
      gridData: FlGridData(
        show: true, drawVerticalLine: false,
        horizontalInterval: (mx - mn) / 4,
        getDrawingHorizontalLine: (_) => FlLine(color: grid, strokeWidth: 0.5),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true, reservedSize: 56,
          getTitlesWidget: (v, _) => Text(v.toStringAsFixed(3),
            style: GoogleFonts.dmMono(fontSize: 9, color: muted)),
        )),
        bottomTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true,
          interval: (spots.length / 4).ceilToDouble(),
          getTitlesWidget: (v, _) {
            final i = v.toInt();
            if (i < 0 || i >= history!.series.length) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(history!.series[i].date.substring(5),
                style: GoogleFonts.dmMono(fontSize: 9, color: muted)),
            );
          },
        )),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (spots) => spots.map((s) => LineTooltipItem(
            s.y.toStringAsFixed(6),
            GoogleFonts.dmMono(fontSize: 12, fontWeight: FontWeight.w500, color: text),
          )).toList(),
        ),
      ),
      lineBarsData: [LineChartBarData(
        spots: spots,
        isCurved: true, curveSmoothness: 0.3,
        color: accent, barWidth: 2,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [accent.withOpacity(0.15), accent.withOpacity(0)],
          ),
        ),
      )],
    ));
  }
}
