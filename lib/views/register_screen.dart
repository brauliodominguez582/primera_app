import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterScreen extends StatefulWidget {
  final String baseUrl;
  const RegisterScreen({super.key, required this.baseUrl});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _dirController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _dirController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final dir = _dirController.text.trim();

      final response = await http.post(
        Uri.parse('${widget.baseUrl}/registro'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nom_usr': _nameController.text.trim(),
          'mail': _emailController.text.trim(),
          'passw': _passwordController.text,
          'dir_usr': dir.isEmpty ? null : dir,
          'biografia': '',
          'tip_usu': 1, 
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registro exitoso')),
        );
        Navigator.pop(context);
      } else {
        String mensaje = 'Error al registrarse (${response.statusCode})';
        try {
          final body = jsonDecode(response.body);
          if (body['detail'] is String) {
            mensaje = body['detail'];
          }
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensaje)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de conexión: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre completo',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'Ingresa tu nombre'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'Ingresa tu correo'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    obscureText: true,
                    validator: (val) => val == null || val.isEmpty
                        ? 'Ingresa tu contraseña'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _dirController,
                    decoration: const InputDecoration(
                      labelText: 'Dirección (opcional)',
                      prefixIcon: Icon(Icons.home_outlined),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _isLoading ? null : _register,
                    child: _isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.white),
                          )
                        : const Text('Registrarse'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}