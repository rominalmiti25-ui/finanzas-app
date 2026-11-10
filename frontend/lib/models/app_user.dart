class AppUser {
  final int id;
  final String name;
  final String email;
  final String role;
  final int age;
  final double monthlyIncome;
  final double monthlyBudget;

  AppUser({required this.id, required this.name, required this.email, required this.role,
      required this.age, required this.monthlyIncome, required this.monthlyBudget});

  bool get isAdmin => role == 'admin';

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'] as int,
        name: j['name'] as String,
        email: j['email'] as String,
        role: j['role'] as String,
        age: j['age'] as int,
        monthlyIncome: (j['monthly_income'] as num).toDouble(),
        monthlyBudget: (j['monthly_budget'] as num).toDouble(),
      );
}
