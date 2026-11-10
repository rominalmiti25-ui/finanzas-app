import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/admin_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'admin_dashboard_tab.dart';
import 'admin_users_tab.dart';

class AdminHomeView extends StatefulWidget {
  const AdminHomeView({super.key});
  @override
  State<AdminHomeView> createState() => _AdminHomeViewState();
}

class _AdminHomeViewState extends State<AdminHomeView> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<AdminViewModel>();
      vm.loadStats(reset: true);
      vm.loadUsers(reset: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().user!;
    return Scaffold(
      appBar: AppBar(
        title: Text(_index == 0 ? 'Panel de administración' : 'Usuarios'),
        actions: [IconButton(tooltip: 'Cerrar sesión', icon: const Icon(Icons.logout), onPressed: () => context.read<AuthViewModel>().logout())],
      ),
      body: IndexedStack(index: _index, children: [const AdminDashboardTab(), AdminUsersTab(currentUserId: user.id)]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights), label: 'Estadísticas'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Usuarios'),
        ],
      ),
    );
  }
}
