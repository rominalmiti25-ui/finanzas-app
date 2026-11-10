import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/transactions_viewmodel.dart';
import 'widgets/common.dart';

class TransactionsTab extends StatelessWidget {
  const TransactionsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TransactionsViewModel>();
    if (vm.error != null && vm.items.isEmpty) return ErrorBanner(vm.error!, onRetry: () => vm.load());
    if (vm.loading && vm.items.isEmpty) return const Center(child: CircularProgressIndicator());
    if (vm.items.isEmpty) return const Center(child: Text('Sin movimientos. Toca "Agregar" para registrar el primero.'));
    return RefreshIndicator(
      onRefresh: () => vm.load(),
      child: ListView.separated(
        padding: const EdgeInsets.only(bottom: 90),
        itemCount: vm.items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (ctx, i) {
          final t = vm.items[i];
          return Dismissible(
            key: ValueKey(t.id),
            direction: DismissDirection.endToStart,
            background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete, color: Colors.white)),
            confirmDismiss: (_) async {
              final ok = await showDialog<bool>(
                context: ctx,
                builder: (d) => AlertDialog(
                  title: const Text('Eliminar movimiento'),
                  content: Text('¿Eliminar "${t.description.isEmpty ? t.category : t.description}" por ${money(t.amount)}?'),
                  actions: [TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('Eliminar'))],
                ),
              );
              if (ok != true) return false;
              final err = await vm.remove(t.id);
              if (err != null && ctx.mounted) showSnack(ctx, err, error: true);
              return false; // la lista ya se actualizó en el viewmodel
            },
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: t.isExpense ? Colors.red.shade50 : Colors.green.shade50,
                child: Icon(t.isExpense ? Icons.arrow_downward : Icons.arrow_upward, color: t.isExpense ? Colors.red : Colors.green),
              ),
              title: Text(t.description.isEmpty ? t.category : t.description),
              subtitle: Text('${t.category} · ${t.date}'),
              trailing: Text('${t.isExpense ? '-' : '+'}${money(t.amount)}', style: TextStyle(fontWeight: FontWeight.bold, color: t.isExpense ? Colors.red.shade700 : Colors.green.shade700)),
            ),
          );
        },
      ),
    );
  }
}
