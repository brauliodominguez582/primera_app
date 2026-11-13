import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class AttendanceScreen extends StatefulWidget {
  final int idUsr;
  const AttendanceScreen({super.key, required this.idUsr});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  bool _isLoading = false;
  List<dynamic> _historial = [];

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  // dar el GPS 
Future<void> _registrarAsistencia() async {
    setState(() => _isLoading = true);
    try {
      // erificar y pedir permisos
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Los permisos de ubicación fueron denegados.';
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw 'Los permisos están denegados permanentemente, cámbialos en la configuración del navegador.';
      }

      // (timeout) de 10 segundos
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );

      // enviar a FastAPI
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/attendance/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "id_usr": widget.idUsr,
          "latitud": position.latitude,
          "longitud": position.longitude,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Asistencia registrada con éxito!')),
        );
        _cargarHistorial();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error del servidor: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print("Error detallado GPS: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  //cargar historial
  Future<void> _cargarHistorial() async {
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/attendance/?id_usr=${widget.idUsr}'),
      );
      if (response.statusCode == 200) {
        setState(() {
          _historial = json.decode(response.body);
        });
      }
    } catch (e) {
      print("Error al cargar historial: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro de Asistencia con GPS')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _registrarAsistencia,
              icon: const Icon(Icons.location_pin),
              label: const Text('Registrar asistencia'),
            ),
            const SizedBox(height: 20),
            if (_isLoading) const CircularProgressIndicator(),
            const Text('Historial de Asistencias:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: _historial.length,
                itemBuilder: (context, index) {
                  final item = _historial[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.check_circle, color: Colors.green),
                      title: Text(item['direccion'] ?? 'Sin dirección'),
                      subtitle: Text('Fecha: ${item['fecha_hora']}'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}