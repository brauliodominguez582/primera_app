import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PostDetailScreen extends StatefulWidget {
  final String baseUrl;
  final int postId;

  const PostDetailScreen(
      {super.key, required this.baseUrl, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  Map<String, dynamic>? _post;
  List<dynamic> _comentarios = [];
  bool _isLoading = true;
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final postResp = await http
          .get(Uri.parse('${widget.baseUrl}/posts/${widget.postId}'));
      final commResp = await http.get(
          Uri.parse('${widget.baseUrl}/posts/${widget.postId}/comentarios'));

      if (postResp.statusCode == 200) {
        _post = jsonDecode(postResp.body);
      }
      if (commResp.statusCode == 200) {
        _comentarios = jsonDecode(commResp.body);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar detalle: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;
    try {
      final response = await http.post(
        Uri.parse('${widget.baseUrl}/comentarios'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'post_id': widget.postId,
          'texto': _commentController.text.trim(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _commentController.clear();
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al agregar comentario: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Publicación')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _post == null
              ? const Center(child: Text('No se encontró el contenido'))
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      children: [
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.all(20),
                            children: [
                              Text(
                                _post!['titulo'] ?? _post!['title'] ?? '',
                                style: textTheme.headlineMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _post!['contenido'] ?? _post!['body'] ?? '',
                                style:
                                    textTheme.bodyLarge?.copyWith(height: 1.5),
                              ),
                              const Divider(height: 40),
                              Text(
                                'Comentarios (${_comentarios.length})',
                                style: textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 12),
                              if (_comentarios.isEmpty)
                                const Text('Sé el primero en comentar',
                                    style: TextStyle(color: Colors.black54)),
                              ..._comentarios.map((comm) => Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 8),
                                    child: Card(
                                      child: Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Icon(
                                                Icons.chat_bubble_outline,
                                                size: 18,
                                                color: Colors.black45),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(comm['texto'] ??
                                                  comm['contenido'] ??
                                                  ''),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  )),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            border: Border(
                                top: BorderSide(color: Color(0xFFE3E7E4))),
                          ),
                          child: SafeArea(
                            top: false,
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _commentController,
                                    decoration: const InputDecoration(
                                      hintText: 'Escribe un comentario...',
                                      isDense: true,
                                    ),
                                    onSubmitted: (_) => _addComment(),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                IconButton.filled(
                                  icon: const Icon(Icons.send),
                                  onPressed: _addComment,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}