import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/transactions_viewmodel.dart';
import 'widgets/common.dart';

class SummaryTab extends StatelessWidget {
  final String userName;
  final double budget;
  const SummaryTab({super.key, required this.userName, required this.budget});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TransactionsViewModel>();
    if (vm.error != null && vm.items.isEmpty) return ErrorBanner(vm.error!, onRetry: () => vm.load());
    final spent = vm.monthExpenses, income = vm.monthIncome;
    final pct = budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;
    final cats = vm.monthByCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return RefreshIndicator(
      onRefresh: () => vm.load(),
      child: ListView(padding: const EdgeInsets.all(16), children: [
        Text('Hola, ${userName.split(' ').first} 👋', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const Text('Así va tu mes actual', style: TextStyle(color: Colors.black54)),
        const SizedBox(height: 12),
        if (vm.loading && vm.items.isEmpty) const LinearProgressIndicator(),
        GridView.count(
          crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 1.7,
          children: [
            StatCard(label: 'Gastos del mes', value: money(spent), icon: Icons.trending_down, color: Colors.red.shade400),
            StatCard(label: 'Ingresos del mes', value: money(income), icon: Icons.trending_up, color: Colors.green.shade600),
            StatCard(label: 'Balance', value: money(income - spent), icon: Icons.account_balance_wallet_outlined),
            StatCard(label: 'Presupuesto', value: money(budget), icon: Icons.flag_outlined),
          ],
        ),
        sectionTitle('Uso del presupuesto'),
        LinearProgressIndicator(value: pct, minHeight: 10, borderRadius: BorderRadius.circular(6), color: pct >= 1 ? Colors.red : (pct > 0.8 ? Colors.orange : null)),
        const SizedBox(height: 4),
        Text(budget > 0 ? '${(spent / budget * 100).toStringAsFixed(0)} % de ${money(budget)}' : 'Sin presupuesto definido'),
        sectionTitle('Gasto por categoría (este mes)'),
        if (cats.isEmpty) const Padding(padding: EdgeInsets.all(8), child: Text('Aún no hay gastos este mes.')),
        for (final c in cats)
          ListTile(dense: true, title: Text(c.key), trailing: Text(money(c.value), style: const TextStyle(fontWeight: FontWeight.w600))),
        const SizedBox(height: 80),
      ]),
    );
  }
}
