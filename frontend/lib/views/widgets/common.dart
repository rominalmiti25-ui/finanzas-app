import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

final NumberFormat _money = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
String money(num v) => _money.format(v);
String moneyShort(num v) => NumberFormat.compactCurrency(symbol: '\$', decimalDigits: 1).format(v);

void showSnack(BuildContext context, String msg, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.red.shade700 : null,
      behavior: SnackBarBehavior.floating,
    ));
}

class ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const ErrorBanner(this.message, {super.key, this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, size: 40, color: Colors.red),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) TextButton(onPressed: onRetry, child: const Text('Reintentar')),
          ]),
        ),
      );
}

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;
  const StatCard({super.key, required this.label, required this.value, required this.icon, this.color});
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, color: color ?? Theme.of(context).colorScheme.primary),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ]),
        ),
      );
}

Widget sectionTitle(String t) => Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Text(t, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );

const _noTitles = AxisTitles(sideTitles: SideTitles(showTitles: false));

Widget _bottomLabel(List<String> labels, double v) {
  final i = v.toInt();
  if (i < 0 || i >= labels.length) return const SizedBox.shrink();
  return Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Text(labels[i], style: const TextStyle(fontSize: 9)),
  );
}

/// Gráfica de barras sencilla. [highlightLast] pinta la última barra de otro color (p. ej. predicción).
class SimpleBarChart extends StatelessWidget {
  final List<String> labels;
  final List<double> values;
  final bool highlightLast;
  final double height;
  const SimpleBarChart({super.key, required this.labels, required this.values, this.highlightLast = false, this.height = 200});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: height,
      child: BarChart(BarChartData(
        alignment: BarChartAlignment.spaceAround,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: _noTitles, rightTitles: _noTitles, topTitles: _noTitles,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 28, getTitlesWidget: (v, m) => _bottomLabel(labels, v)),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, gi, rod, ri) => BarTooltipItem(moneyShort(rod.toY), const TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ),
        barGroups: [
          for (var i = 0; i < values.length; i++)
            BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: values[i], width: 16, borderRadius: BorderRadius.circular(4),
                color: (highlightLast && i == values.length - 1) ? Colors.orange : cs.primary,
              ),
            ]),
        ],
      )),
    );
  }
}

/// Gráfica de líneas para dos series (gasto e ingreso por mes).
class DualLineChart extends StatelessWidget {
  final List<String> labels;
  final List<double> a;
  final List<double> b;
  final String nameA;
  final String nameB;
  const DualLineChart({super.key, required this.labels, required this.a, required this.b, required this.nameA, required this.nameB});

  LineChartBarData _line(List<double> v, Color c) => LineChartBarData(
        spots: [for (var i = 0; i < v.length; i++) FlSpot(i.toDouble(), v[i])],
        isCurved: true, color: c, barWidth: 3, dotData: const FlDotData(show: true),
      );

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SizedBox(
        height: 200,
        child: LineChart(LineChartData(
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            rightTitles: _noTitles, topTitles: _noTitles,
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 46, getTitlesWidget: (v, m) => Text(moneyShort(v), style: const TextStyle(fontSize: 9)))),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, interval: 1, getTitlesWidget: (v, m) => _bottomLabel(labels, v))),
          ),
          lineBarsData: [_line(a, Colors.red.shade400), _line(b, Colors.green.shade600)],
        )),
      ),
      const SizedBox(height: 6),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.circle, size: 10, color: Colors.red.shade400), Text(' $nameA   ', style: const TextStyle(fontSize: 12)),
        Icon(Icons.circle, size: 10, color: Colors.green.shade600), Text(' $nameB', style: const TextStyle(fontSize: 12)),
      ]),
    ]);
  }
}
