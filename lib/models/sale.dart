class Sale {
  final String id;
  final double amount;
  final DateTime date;
  final String category;
  final String? customer; // <- opcional

  Sale({
    required this.id,
    required this.amount,
    required this.date,
    required this.category,
    this.customer,
  });

  factory Sale.fromMap(Map<String, dynamic> map) { //Convierte los datos para que sean funcionales en la clase
    return Sale(
      id: map['id'],
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date']),
      category: map['category'],
      customer: map['customer'],
    );
  }

  Map<String, dynamic> toMap() { //diccionario para buscar el dato por su nombre y no por su posicion
    return {
      'id': id,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': category,
      'customer': customer,
    };
  }
}
