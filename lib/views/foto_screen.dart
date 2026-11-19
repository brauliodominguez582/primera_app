import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';

class FotoScreen extends StatefulWidget {
  final String baseUrl;
  const FotoScreen({super.key, required this.baseUrl});

  @override
  State<FotoScreen> createState() => _FotoScreenState();
}

class _FotoScreenState extends State<FotoScreen> {
  final _descController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  XFile? _pickedFile;
  Uint8List? _imageBytes;
  bool _isUploading = false;
  bool _isLoadingFotos = true;
  List<dynamic> _fotos = [];

  @override
  void initState() {
    super.initState();
    _cargarFotos();
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  void _mostrarMensaje(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _seleccionarFoto(ImageSource source) async {
    try {
      final XFile? archivo = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (archivo != null) {
        final bytes = await archivo.readAsBytes();
        setState(() {
          _pickedFile = archivo;
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      _mostrarMensaje('No se pudo obtener la imagen: $e');
    }
  }

  void _mostrarOpcionesFoto() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tomar Foto (Cámara)'),
              onTap: () {
                Navigator.pop(ctx);
                _seleccionarFoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Elegir de Galería / Archivo'),
              onTap: () {
                Navigator.pop(ctx);
                _seleccionarFoto(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _subirFoto() async {
    final descripcion = _descController.text.trim();
    if (_pickedFile == null || _imageBytes == null) {
      _mostrarMensaje('Primero selecciona o toma una foto');
      return;
    }
    if (descripcion.isEmpty) {
      _mostrarMensaje('Escribe una descripción');
      return;
    }

    setState(() => _isUploading = true);
    try {
      final uri = Uri.parse('${widget.baseUrl}/fotos');
      final request = http.MultipartRequest('POST', uri)
        ..fields['descripcion'] = descripcion
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            _imageBytes!,
            filename: _pickedFile!.name.isNotEmpty
                ? _pickedFile!.name
                : 'foto.jpg',
            contentType: MediaType('image', 'jpeg'), 
          ),
        );
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        _descController.clear();
        setState(() {
          _pickedFile = null;
          _imageBytes = null;
        });
        _mostrarMensaje('Foto subida correctamente');
        await _cargarFotos();
      } else {
        _mostrarMensaje(
            'Error al subir (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      _mostrarMensaje('Error de conexión: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _cargarFotos() async {
    setState(() => _isLoadingFotos = true);
    try {
      final resp = await http.get(Uri.parse('${widget.baseUrl}/fotos'));
      if (resp.statusCode == 200) {
        setState(() {
          _fotos = jsonDecode(resp.body);
        });
      }
    } catch (e) {
      _mostrarMensaje('Error al cargar fotos: $e');
    } finally {
      if (mounted) setState(() => _isLoadingFotos = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subir Foto'),
        actions: [
          IconButton(
            tooltip: 'Actualizar galería',
            icon: const Icon(Icons.refresh),
            onPressed: _cargarFotos,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: _imageBytes != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      _imageBytes!,
                      height: 190,
                      fit: BoxFit.cover,
                    ),
                  )
                : const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'No hay imagen seleccionada',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descController,
            decoration: const InputDecoration(
              labelText: 'Descripción',
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _isUploading ? null : _mostrarOpcionesFoto,
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('Tomar Foto'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _isUploading ? null : _subirFoto,
            icon: _isUploading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.cloud_upload_outlined),
            label: Text(_isUploading ? 'Subiendo...' : 'Subir a API'),
          ),
          const Divider(height: 36),
          Text(
            'Fotos en el servidor (${_fotos.length})',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          if (_isLoadingFotos)
            const Center(child: CircularProgressIndicator())
          else if (_fotos.isEmpty)
            const Text(
              'Aún no hay fotos registradas.',
              style: TextStyle(color: Colors.black54),
            )
          else
            ..._fotos.map((foto) {
              final ruta = (foto['ruta_foto'] ?? '')
                  .toString()
                  .replaceFirst(RegExp(r'^/'), '');
              final urlImagen = '${widget.baseUrl}/$ruta';
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        urlImagen,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.broken_image),
                      ),
                    ),
                    title: Text(foto['descripcion'] ?? 'Sin descripción'),
                    subtitle: Text(foto['fecha']?.toString() ?? ''),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}