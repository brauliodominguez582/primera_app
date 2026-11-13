import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'post_detail_screen.dart';
import 'post_form_screen.dart';
import 'attendance_screen.dart';

class PostsScreen extends StatefulWidget {
  final String baseUrl;
  const PostsScreen({super.key, required this.baseUrl});

  @override
  State<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> {
  List<dynamic> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('${widget.baseUrl}/posts'));
      if (response.statusCode == 200) {
        setState(() {
          _posts = jsonDecode(response.body);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar posts: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deletePost(int id) async {
    try {
      final response =
          await http.delete(Uri.parse('${widget.baseUrl}/posts/$id'));
      if (response.statusCode == 200 || response.statusCode == 204) {
        _fetchPosts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar post: $e')),
        );
      }
    }
  }

  Future<void> _confirmDelete(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar publicación'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok == true) _deletePost(id);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
      title: const Text('Blog'),
      actions: [
        IconButton(
          tooltip: 'Actualizar',
          icon: const Icon(Icons.refresh),
          onPressed: _fetchPosts,
        ),
        const SizedBox(width: 8),
        
        //  para asistectencia y gps
        IconButton(
          tooltip: 'Pase de Lista y GPS',
          icon: const Icon(Icons.location_pin),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
              
              builder: (context) => AttendanceScreen(idUsr: 3),
              ),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _posts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.article_outlined,
                          size: 56, color: Colors.black38),
                      const SizedBox(height: 12),
                      Text('Aún no hay publicaciones',
                          style: textTheme.titleMedium),
                      const SizedBox(height: 4),
                      const Text('Toca + para crear la primera'),
                    ],
                  ),
                )
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                      itemCount: _posts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final post = _posts[index];
                        return Card(
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PostDetailScreen(
                                    baseUrl: widget.baseUrl,
                                    postId: post['id'],
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 14, 8, 14),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          post['titulo'] ??
                                              post['title'] ??
                                              'Sin título',
                                          style: textTheme.titleMedium
                                              ?.copyWith(
                                                  fontWeight: FontWeight.w700),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          post['contenido'] ??
                                              post['body'] ??
                                              '',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: textTheme.bodyMedium
                                              ?.copyWith(
                                                  color: Colors.black54),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Editar',
                                    icon: const Icon(Icons.edit_outlined),
                                    onPressed: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => PostFormScreen(
                                            baseUrl: widget.baseUrl,
                                            post: post,
                                          ),
                                        ),
                                      );
                                      if (result == true) _fetchPosts();
                                    },
                                  ),
                                  IconButton(
                                    tooltip: 'Eliminar',
                                    icon: const Icon(Icons.delete_outline,
                                        color: Colors.red),
                                    onPressed: () =>
                                        _confirmDelete(post['id']),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Nuevo post'),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostFormScreen(baseUrl: widget.baseUrl),
            ),
          );
          if (result == true) _fetchPosts();
        },
      ),
    );
  }
}