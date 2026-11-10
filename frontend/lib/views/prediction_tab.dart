import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/prediction_viewmodel.dart';
import 'widgets/common.dart';

class PredictionTab extends StatelessWidget {
  const PredictionTab({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PredictionViewModel>();
    if (vm.error != null && vm.prediction == null) return ErrorBanner(vm.error!, onRetry: () => vm.load());
    final p = vm.prediction;
    if (p == null) return const Center(child: CircularProgressIndicator());
    if (!p.ready) {
      return RefreshIndicator(
        onRefresh: () => vm.load(),
        child: ListView(children: [
          Padding(padding: const EdgeInsets.all(32), child: Column(children: [
            const Icon(Icons.hourglass_empty, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(p.message ?? 'Sin datos suficientes', textAlign: TextAlign.center),
          ])),
        ]),
      );
    }
    final color = switch (p.alertLevel) { 'danger' => Colors.red.shade700, 'warning' => Colors.orange.shade800, _ => Colors.green.shade700 };
    final icon = switch (p.alertLevel) { 'danger' => Icons.warning_amber_rounded, 'warning' => Icons.error_outline, _ => Icons.check_circle_outline };
    final labels = [...p.history.map((e) => e.key.substring(2)), '${p.month.substring(2)}*'];
    final values = [...p.history.map((e) => e.value), p.predictedSpend];

    return RefreshIndicator(
      onRefresh: () => vm.load(),
      child: ListView(padding: const EdgeInsets.all(16), children: [
        Card(
          color: color.withOpacity(0.08),
          child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Icon(icon, color: color), const SizedBox(width: 8), Text('Alerta de gasto', style: TextStyle(fontWeight: FontWeight.bold, color: color))]),
            const SizedBox(height: 6),
            for (final a in p.alerts) Padding(padding: const EdgeInsets.only(top: 2), child: Text('• $a')),
          ])),
        ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 1.7,
          children: [
            StatCard(label: 'Gasto esperado (${p.month})', value: money(p.predictedSpend), icon: Icons.auto_graph, color: Colors.orange),
            StatCard(label: 'Ahorro estimado', value: money(p.predictedSavings), icon: Icons.savings_outlined, color: p.predictedSavings >= 0 ? Colors.green.shade600 : Colors.red),
            StatCard(label: 'Llevas gastado', value: money(p.spentSoFar), icon: Icons.shopping_bag_outlined),
            StatCard(label: 'Proyección al cierre', value: p.projectedSpend == null ? 'Calculando…' : money(p.projectedSpend!), icon: Icons.timeline),
          ],
        ),
        sectionTitle('Historial de gasto y predicción (*)'),
        SimpleBarChart(labels: labels, values: values, highlightLast: true),
        sectionTitle('Gasto esperado por categoría'),
        for (final c in p.categories)
          ListTile(dense: true, title: Text(c.key), trailing: Text(money(c.value), style: const TextStyle(fontWeight: FontWeight.w600))),
        sectionTitle('¿Cómo se calculó?'),
        Text('Modelo de regresión entrenado con los datos de la comunidad. Error medio en pruebas: ${money(p.mae)} · R² = ${p.r2.toStringAsFixed(2)}.\nVariables: ${p.features.join(', ')}.',
            style: const TextStyle(color: Colors.black54, fontSize: 12)),
        const SizedBox(height: 24),
      ]),
    );
  }
}
