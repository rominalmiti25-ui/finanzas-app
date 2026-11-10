import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../viewmodels/transactions_viewmodel.dart';
import 'widgets/common.dart';

class AddTransactionView extends StatefulWidget {
  const AddTransactionView({super.key});
  @override
  State<AddTransactionView> createState() => _AddTransactionViewState();
}

class _AddTransactionViewState extends State<AddTransactionView> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _desc = TextEditingController();
  String _type = 'gasto';
  String? _category;
  DateTime _date = DateTime.now();
  bool _saving = false;
  bool _suggesting = false;

  String get _dateStr => DateFormat('yyyy-MM-dd').format(_date);

  @override
  void dispose() { _amount.dispose(); _desc.dispose(); super.dispose(); }

  Future<void> _pickDate() async {
    final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime.now());
    if (d != null) setState(() => _date = d);
  }

  Future<void> _suggest() async {
    final vm = context.read<TransactionsViewModel>();
    if ((_desc.text.trim()).length < 2) { showSnack(context, 'Escribe una descripción para sugerir la categoría', error: true); return; }
    setState(() => _suggesting = true);
    final c = await vm.suggestCategory(_desc.text);
    if (!mounted) return;
    setState(() { _suggesting = false; if (c != null && kExpenseCategories.contains(c)) _category = c; });
    showSnack(context, c == null ? 'No se pudo obtener una sugerencia' : 'Categoría sugerida por IA: $c', error: c == null);
  }

  Future<void> _save() async {
    final vm = context.read<TransactionsViewModel>();
    if (!_form.currentState!.validate()) return; // impide el envío si hay datos inválidos
    setState(() => _saving = true);
    final err = await vm.add(
      type: _type, amount: double.parse(_amount.text.trim().replaceAll(',', '.')),
      category: _category, description: _desc.text, date: _dateStr,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (err == null) { Navigator.pop(context, true); } else { showSnack(context, err, error: true); }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.read<TransactionsViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo movimiento')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _form,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'gasto', label: Text('Gasto'), icon: Icon(Icons.arrow_downward)),
                ButtonSegment(value: 'ingreso', label: Text('Ingreso'), icon: Icon(Icons.arrow_upward)),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() { _type = s.first; if (_type == 'ingreso') _category = null; }),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amount, keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Monto (\$)', prefixIcon: Icon(Icons.attach_money)),
              validator: vm.validateAmount,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _desc, maxLength: 200,
              decoration: InputDecoration(labelText: _type == 'gasto' ? 'Descripción (ej. "gasolina")' : 'Descripción', prefixIcon: const Icon(Icons.notes)),
              validator: vm.validateDescription,
            ),
            if (_type == 'gasto') ...[
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(labelText: 'Categoría', prefixIcon: Icon(Icons.category_outlined)),
                items: [for (final c in kExpenseCategories) DropdownMenuItem(value: c, child: Text(c))],
                onChanged: (v) => setState(() => _category = v),
                validator: (v) => vm.validateCategory(v, _type),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _suggesting ? null : _suggest,
                  icon: _suggesting ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.auto_awesome),
                  label: const Text('Sugerir categoría con IA'),
                ),
              ),
            ],
            const SizedBox(height: 6),
            FormField<String>(
              initialValue: _dateStr,
              validator: (_) => vm.validateDate(_dateStr),
              builder: (state) => InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: InputDecoration(labelText: 'Fecha', prefixIcon: const Icon(Icons.calendar_today), errorText: state.errorText),
                  child: Text(_dateStr),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(height: 48, child: FilledButton(onPressed: _saving ? null : _save, child: _saving ? const CircularProgressIndicator(strokeWidth: 2) : const Text('Guardar'))),
          ]),
        ),
      ),
    );
  }
}
