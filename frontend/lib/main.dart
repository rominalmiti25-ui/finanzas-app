import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/api_client.dart';
import 'viewmodels/admin_viewmodel.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/prediction_viewmodel.dart';
import 'viewmodels/transactions_viewmodel.dart';
import 'views/admin_home_view.dart';
import 'views/client_home_view.dart';
import 'views/login_view.dart';

final ApiClient _api = ApiClient();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FinanzasApp());
}

class FinanzasApp extends StatelessWidget {
  const FinanzasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel(_api)..restore()),
        ChangeNotifierProvider(create: (_) => TransactionsViewModel(_api)),
        ChangeNotifierProvider(create: (_) => PredictionViewModel(_api)),
        ChangeNotifierProvider(create: (_) => AdminViewModel(_api)),
      ],
      child: MaterialApp(
        title: 'Finanzas Personales',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0B7A75)),
          inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
        ),
        home: const RootView(),
      ),
    );
  }
}

/// Decide qué pantalla mostrar según la sesión y el rol.
class RootView extends StatelessWidget {
  const RootView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    if (!auth.initialized) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final u = auth.user;
    if (u == null) return const LoginView();
    return u.isAdmin ? const AdminHomeView() : const ClientHomeView();
  }
}
