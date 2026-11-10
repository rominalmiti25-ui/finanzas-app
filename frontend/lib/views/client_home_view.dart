import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/prediction_viewmodel.dart';
import '../viewmodels/transactions_viewmodel.dart';
import 'add_transaction_view.dart';
import 'prediction_tab.dart';
import 'summary_tab.dart';
import 'transactions_tab.dart';

class ClientHomeView extends StatefulWidget {
  const ClientHomeView({super.key});
  @override
  State<ClientHomeView> createState() => _ClientHomeViewState();
}

class _ClientHomeViewState extends State<ClientHomeView> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionsViewModel>().load(reset: true);
      context.read<PredictionViewModel>().load(reset: true);
    });
  }

  Future<void> _openAdd() async {
    final added = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const AddTransactionView()));
    if (added == true && mounted) context.read<PredictionViewModel>().load();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().user!;
    const titles = ['Resumen', 'Movimientos', 'Predicción (IA)'];
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_index]),
        actions: [
          IconButton(tooltip: 'Cerrar sesión', icon: const Icon(Icons.logout), onPressed: () => context.read<AuthViewModel>().logout()),
        ],
      ),
      body: IndexedStack(index: _index, children: [
        SummaryTab(userName: user.name, budget: user.monthlyBudget),
        const TransactionsTab(),
        const PredictionTab(),
      ]),
      floatingActionButton: _index == 2 ? null : FloatingActionButton.extended(onPressed: _openAdd, icon: const Icon(Icons.add), label: const Text('Agregar')),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Resumen'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Movimientos'),
          NavigationDestination(icon: Icon(Icons.auto_graph_outlined), selectedIcon: Icon(Icons.auto_graph), label: 'Predicción'),
        ],
      ),
    );
  }
}
