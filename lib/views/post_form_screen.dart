import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PostFormScreen extends StatefulWidget {
  final String baseUrl;
  final dynamic post;
  final int? usuarioId;

  const PostFormScreen({
    super.key,
    required this.baseUrl,
    this.post,
    this.usuarioId,
  });

  @override
  State<PostFormScreen> createState() => _PostFormScreenState();
}

class _PostFormScreenState extends State<PostFormScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagsController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _mostrarMensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _savePost() async {
    if (_titleController.text.trim().isEmpty ||
        _descController.text.trim().isEmpty ||
        _contentController.text.trim().isEmpty) {
      _mostrarMensaje('Título, descripción y contenido son obligatorios');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final tags = _tagsController.text.trim();

      final response = await http.post(
        Uri.parse('${widget.baseUrl}/posts'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'titulo': _titleController.text.trim(),
          'desc': _descController.text.trim(),
          'contenido': _contentController.text.trim(),
          'tags': tags.isEmpty ? null : tags,
          'usr_id': widget.usuarioId ??
              (widget.post != null ? widget.post['usr_id'] : 1),
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.pop(context, true);
      } else {
        String mensaje = 'Error al crear el post (${response.statusCode})';
        try {
          final body = jsonDecode(response.body);
          if (body['detail'] is String) {
            mensaje = body['detail'];
          } else if (body['detail'] is List && body['detail'].isNotEmpty) {
            mensaje = 'Dato inválido: ${body['detail'][0]['loc'].last}';
          }
        } catch (_) {}
        _mostrarMensaje(mensaje);
      }
    } catch (e) {
      if (mounted) _mostrarMensaje('Error de conexión: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo post')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Título'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _descController,
                  decoration:
                      const InputDecoration(labelText: 'Descripción corta'),
                  maxLength: 500,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _contentController,
                  decoration: const InputDecoration(
                    labelText: 'Contenido',
                    alignLabelWithHint: true,
                  ),
                  maxLines: 8,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _tagsController,
                  decoration: const InputDecoration(
                    labelText: 'Tags (opcional)',
                    helperText: 'Sepáralos con coma',
                    prefixIcon: Icon(Icons.sell_outlined),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isLoading ? null : _savePost,
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Text('Publicar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}