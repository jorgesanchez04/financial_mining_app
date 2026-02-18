import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return Scaffold(
      appBar: AppBar(title: const Text('Registro')),
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
            const SizedBox(height: 12),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration:
                  const InputDecoration(labelText: 'Confirmar contraseña'),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: () async {
                if (emailController.text.isEmpty ||
                    passwordController.text.isEmpty ||
                    confirmPasswordController.text.isEmpty) {
                  _showMessage('Completa todos los campos');
                  return;
                }

                if (!_isValidEmail(emailController.text)) {
                  _showMessage('Correo electrónico no válido');
                  return;
                }

                if (passwordController.text.length < 6) {
                  _showMessage('La contraseña debe tener al menos 6 caracteres');
                  return;
                }

                if (passwordController.text !=
                    confirmPasswordController.text) {
                  _showMessage('Las contraseñas no coinciden');
                  return;
                }

                try {
                  await supabase.auth.signUp(
                    email: emailController.text.trim(),
                    password: passwordController.text.trim(),
                  );

                  _showMessage(
                      'Cuenta creada. Revisa tu correo para confirmar.');
                  if (mounted) Navigator.pop(context);
                } on AuthException catch (e) {
                  String msg = 'Error al registrar';

                  if (e.message.toLowerCase().contains('already registered')) {
                    msg = 'Este correo ya está registrado';
                  }

                  _showMessage(msg);
                } catch (_) {
                  _showMessage('Error inesperado, intenta más tarde');
                }
              },
              child: const Text('Registrarse'),
            ),
          ],
        ),
      ),
    );
  }
}
