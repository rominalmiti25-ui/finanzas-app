import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/admin_viewmodel.dart';
import 'widgets/common.dart';

class AdminUsersTab extends StatelessWidget {
  final int currentUserId;
  const AdminUsersTab({super.key, required this.currentUserId});

  Future<void> _promote(BuildContext context, int id, String name) async {
    final vm = context.read<AdminViewModel>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Convertir en administrador'),
        content: Text('¿Dar permisos de administrador a $name?'),
        actions: [TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('Confirmar'))],
      ),
    );
    if (ok != true) return;
    final err = await vm.promote(id);
    if (context.mounted) showSnack(context, err ?? '$name ahora es administrador', error: err != null);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminViewModel>();
    if (vm.error != null && vm.users.isEmpty) return ErrorBanner(vm.error!, onRetry: () => vm.loadUsers());
    if (vm.loading && vm.users.isEmpty) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: () => vm.loadUsers(),
      child: ListView.separated(
        itemCount: vm.users.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (ctx, i) {
          final u = vm.users[i];
          return ListTile(
            leading: CircleAvatar(child: Icon(u.isAdmin ? Icons.admin_panel_settings : Icons.person)),
            title: Text(u.name),
            subtitle: Text('${u.email} · ${u.role}'),
            trailing: u.isAdmin
                ? const Chip(label: Text('Admin'))
                : OutlinedButton(onPressed: () => _promote(ctx, u.id, u.name), child: const Text('Hacer admin')),
          );
        },
      ),
    );
  }
}
