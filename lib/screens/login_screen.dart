import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/logo.png',
              height: 28,
              width: 28,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.show_chart, size: 24),
            ),
            const SizedBox(width: 8),
            const Text('Prospera'),
          ],
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // --- SECCIÓN LOGO Y TITULO PRINCIPAL ---
              Image.asset(
                'assets/logo.png',
                height: 80,
                width: 80,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.show_chart, size: 70, color: Colors.blue),
              ),
              const SizedBox(height: 12),
              const Text(
                'Prospera',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 32),

              // --- FORMULARIO DE INGRESO ---
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 24),

              // LOGIN NORMAL
              ElevatedButton(
                onPressed: () async {
                  if (emailController.text.isEmpty ||
                      passwordController.text.isEmpty) {
                    _showMessage('Completa todos los campos');
                    return;
                  }

                  try {
                    await supabase.auth.signInWithPassword(
                      email: emailController.text.trim(),
                      password: passwordController.text.trim(),
                    );
                  } on AuthException catch (e) {
                    String msg = 'Error al iniciar sesión';

                    if (e.message
                        .toLowerCase()
                        .contains('invalid login credentials')) {
                      msg = 'Correo o contraseña incorrectos';
                    } else if (e.message
                        .toLowerCase()
                        .contains('email not confirmed')) {
                      msg = 'Debes confirmar tu correo';
                    }

                    _showMessage(msg);
                  } catch (_) {
                    _showMessage('Error inesperado, intenta más tarde');
                  }
                },
                child: const Text('Ingresar'),
              ),

              const SizedBox(height: 16),

              // LOGIN GOOGLE
              ElevatedButton.icon(
                icon: const Icon(Icons.login),
                label: const Text('Ingresar con Google'),
                onPressed: () async {
                  try {
                    await supabase.auth.signInWithOAuth(
                      OAuthProvider.google,
                      queryParams: {
                        'prompt': 'select_account',
                      },
                    );
                  } catch (_) {
                    _showMessage('No se pudo iniciar sesión con Google');
                  }
                },
              ),

              const SizedBox(height: 12),

              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const RegisterScreen()),
                  );
                },
                child: const Text('Crear cuenta'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}