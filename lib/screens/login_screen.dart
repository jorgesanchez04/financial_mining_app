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
      appBar: AppBar(title: const Text('Iniciar sesión')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Correo electrónico'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Contraseña'),
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

                  if (e.message.toLowerCase().contains('invalid login credentials')) {
                    msg = 'Correo o contraseña incorrectos';
                  } else if (e.message.toLowerCase().contains('email not confirmed')) {
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

            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                );
              },
              child: const Text('Crear cuenta'),
            ),
          ],
        ),
      ),
    );
  }
}
