import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/admin_viewmodel.dart';
import 'widgets/common.dart';

class AdminDashboardTab extends StatelessWidget {
  const AdminDashboardTab({super.key});

  double _d(dynamic v) => (v as num).toDouble();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminViewModel>();
    if (vm.error != null && vm.stats == null) return ErrorBanner(vm.error!, onRetry: () => vm.loadStats());
    final s = vm.stats;
    if (s == null) return const Center(child: CircularProgressIndicator());
    final sum = s.summary;
    final cats = s.categories.where((c) => _d(c['avgMonthlyPerUser']) > 0).toList();
    final sp = s.spendingModel, cl = s.classifierModel;

    return RefreshIndicator(
      onRefresh: () => vm.loadStats(),
      child: ListView(padding: const EdgeInsets.all(16), children: [
        GridView.count(
          crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 1.7,
          children: [
            StatCard(label: 'Clientes', value: '${sum['clients']}', icon: Icons.people),
            StatCard(label: 'Administradores', value: '${sum['admins']}', icon: Icons.admin_panel_settings_outlined),
            StatCard(label: 'Transacciones', value: '${sum['totalTransactions']}', icon: Icons.receipt_long),
            StatCard(label: 'Gasto total', value: moneyShort(_d(sum['totalSpend'])), icon: Icons.trending_down, color: Colors.red.shade400),
          ],
        ),
        sectionTitle('Gasto promedio mensual por usuario y categoría'),
        SimpleBarChart(labels: [for (final c in cats) (c['category'] as String).substring(0, 4)], values: [for (final c in cats) _d(c['avgMonthlyPerUser'])], height: 220),
        sectionTitle('Distribución del gasto de la comunidad'),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 20, headingRowHeight: 40, dataRowMinHeight: 36, dataRowMaxHeight: 40,
            columns: const [DataColumn(label: Text('Categoría')), DataColumn(label: Text('Total'), numeric: true), DataColumn(label: Text('%'), numeric: true), DataColumn(label: Text('Prom./usuario/mes'), numeric: true)],
            rows: [for (final c in s.categories) DataRow(cells: [DataCell(Text(c['category'] as String)), DataCell(Text(money(_d(c['total'])))), DataCell(Text('${c['share']}')), DataCell(Text(money(_d(c['avgMonthlyPerUser']))))])],
          ),
        ),
        sectionTitle('Usuarios por rango de presupuesto'),
        SimpleBarChart(labels: [for (final r in s.budgetRanges) (r['range'] as String).replaceAll(' ', '')], values: [for (final r in s.budgetRanges) _d(r['users'])], height: 180),
        sectionTitle('Actividad por mes'),
        DualLineChart(
          labels: [for (final m in s.monthly) (m['month'] as String).substring(2)],
          a: [for (final m in s.monthly) _d(m['spend'])], b: [for (final m in s.monthly) _d(m['income'])],
          nameA: 'Gastos', nameB: 'Ingresos',
        ),
        sectionTitle('Registros por cliente'),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 18, headingRowHeight: 40, dataRowMinHeight: 36, dataRowMaxHeight: 40,
            columns: const [DataColumn(label: Text('Cliente')), DataColumn(label: Text('Rol')), DataColumn(label: Text('Reg.'), numeric: true), DataColumn(label: Text('Gasto'), numeric: true), DataColumn(label: Text('Última act.'))],
            rows: [for (final c in s.clients.take(25)) DataRow(cells: [DataCell(Text(c['name'] as String)), DataCell(Text(c['role'] as String)), DataCell(Text('${c['transactions']}')), DataCell(Text(money(_d(c['totalSpend'])))), DataCell(Text('${c['lastActivity'] ?? '-'}'))])],
          ),
        ),
        sectionTitle('Efectividad de las predicciones (ML)'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (sp != null) ...[
                const Text('Regresión de gasto mensual', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Error medio (MAE): ${money(_d(sp['mae']))}  ·  R²: ${_d(sp['r2']).toStringAsFixed(2)}'),
                Text('Mejora vs. "repetir mes anterior": ${(_d(sp['improvementVsBaseline']) * 100).toStringAsFixed(1)} %'),
                Text('Entrenamiento: ${sp['nTrain']} · Prueba: ${sp['nTest']} registros', style: const TextStyle(color: Colors.black54, fontSize: 12)),
              ] else const Text('Modelo de regresión sin entrenar.'),
              const Divider(height: 22),
              if (cl != null) ...[
                const Text('Clasificador de categorías (NLP)', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Exactitud: ${(_d(cl['accuracy']) * 100).toStringAsFixed(1)} %  ·  ${cl['classes']} clases'),
                Text('Entrenamiento: ${cl['nTrain']} · Prueba: ${cl['nTest']} descripciones', style: const TextStyle(color: Colors.black54, fontSize: 12)),
              ] else const Text('Clasificador sin entrenar.'),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  icon: const Icon(Icons.model_training),
                  label: const Text('Reentrenar modelos'),
                  onPressed: () async {
                    final msg = await vm.retrain();
                    if (context.mounted) showSnack(context, msg);
                  },
                ),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 24),
      ]),
    );
  }
}
