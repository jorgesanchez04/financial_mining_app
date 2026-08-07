class Expense {
  final String id;
  final double amount;
  final String category;
  final DateTime date;

  Expense({
    required this.id,
    required this.amount,
    required this.category,
    required this.date,
  });

  factory Expense.fromMap(Map<String, dynamic> map) { //Convierte los datos para que sean funcionales en la clase
    return Expense(
      id: map['id'],
      amount: (map['amount'] as num).toDouble(),
      category: map['category'],
      date: DateTime.parse(map['date']),
    );
  }

  Map<String, dynamic> toMap() { //diccionario para buscar el dato por su nombre y no por su posicion
    return {
      'id': id,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
    };
}
}

