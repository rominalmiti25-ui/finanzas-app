import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'widgets/common.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});
  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _age = TextEditingController();
  final _income = TextEditingController();
  final _budget = TextEditingController();

  @override
  void dispose() {
    for (final c in [_name, _email, _pass, _age, _income, _budget]) { c.dispose(); }
    super.dispose();
  }

  double _num(TextEditingController c) => double.parse(c.text.trim().replaceAll(',', '.'));

  Future<void> _submit() async {
    final vm = context.read<AuthViewModel>();
    if (!_form.currentState!.validate()) return;
    final ok = await vm.register(
      name: _name.text, email: _email.text, password: _pass.text,
      age: int.parse(_age.text.trim()), income: _num(_income), budget: _num(_budget),
    );
    if (!mounted) return;
    if (ok) { Navigator.of(context).popUntil((r) => r.isFirst); }
    else { showSnack(context, vm.error ?? 'No se pudo registrar', error: true); }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _form,
          child: Column(children: [
            TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Nombre completo'), validator: vm.validateName),
            const SizedBox(height: 12),
            TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Correo electrónico'), validator: vm.validateEmail),
            const SizedBox(height: 12),
            TextFormField(controller: _pass, obscureText: true, decoration: const InputDecoration(labelText: 'Contraseña', helperText: 'Mínimo 8 caracteres, con letras y números'), validator: vm.validateNewPassword),
            const SizedBox(height: 12),
            TextFormField(controller: _age, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Edad'), validator: vm.validateAge),
            const SizedBox(height: 12),
            TextFormField(controller: _income, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Ingreso mensual (\$)'), validator: (v) => vm.validateMoney(v, label: 'El ingreso')),
            const SizedBox(height: 12),
            TextFormField(controller: _budget, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Presupuesto mensual de gastos (\$)'), validator: (v) => vm.validateMoney(v, label: 'El presupuesto')),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity, height: 48,
              child: FilledButton(onPressed: vm.loading ? null : _submit, child: vm.loading ? const CircularProgressIndicator(strokeWidth: 2) : const Text('Registrarme')),
            ),
          ]),
        ),
      ),
    );
  }
}
