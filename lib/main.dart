import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_gate.dart';
import 'state/selected_month.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://zldzzabppzzbxtqrcasi.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpsZHp6YWJwcHp6Ynh0cXJjYXNpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg0MDYzMzIsImV4cCI6MjA4Mzk4MjMzMn0.71SKnrsQSpUuJ0LCuulrVDi4pF_QoN5DRcTZNsWRS4g',
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) {
        final now = DateTime.now();
        return SelectedMonth(
          month: now.month,
          year: now.year,
        );
      },
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Prospera',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}
