import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'register_view.dart';
import 'widgets/common.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});
  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _hide = true;

  @override
  void dispose() { _email.dispose(); _pass.dispose(); super.dispose(); }

  Future<void> _submit() async {
    final vm = context.read<AuthViewModel>();
    if (!_form.currentState!.validate()) return; // datos inválidos: no se envía
    final ok = await vm.login(_email.text, _pass.text);
    if (!ok && mounted) showSnack(context, vm.error ?? 'No se pudo iniciar sesión', error: true);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _form,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.savings_outlined, size: 72, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 8),
                const Text('Finanzas Personales', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                const Text('Controla tus gastos y predice tu ahorro', style: TextStyle(color: Colors.black54)),
                const SizedBox(height: 28),
                TextFormField(
                  controller: _email, keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Correo electrónico', prefixIcon: Icon(Icons.email_outlined)),
                  validator: vm.validateEmail,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _pass, obscureText: _hide,
                  decoration: InputDecoration(
                    labelText: 'Contraseña', prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(icon: Icon(_hide ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => _hide = !_hide)),
                  ),
                  validator: vm.validateLoginPassword,
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity, height: 48,
                  child: FilledButton(
                    onPressed: vm.loading ? null : _submit,
                    child: vm.loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Iniciar sesión'),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterView())),
                  child: const Text('¿No tienes cuenta? Regístrate'),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
