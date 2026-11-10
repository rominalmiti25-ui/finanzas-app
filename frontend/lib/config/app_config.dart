/// URL base del backend. Se puede cambiar al compilar:
///   flutter build apk --release --dart-define=API_URL=https://mi-backend.onrender.com
/// Por defecto apunta al emulador de Android (10.0.2.2 = localhost de tu PC).
const String kApiUrl = String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:3000');

const List<String> kExpenseCategories = [
  'Alimentación', 'Transporte', 'Vivienda', 'Servicios', 'Salud',
  'Entretenimiento', 'Educación', 'Ropa', 'Otros',
];
