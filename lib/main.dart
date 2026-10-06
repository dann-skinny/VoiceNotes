import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MiNotasApp());
}

class MiNotasApp extends StatelessWidget {
  const MiNotasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Voice Notes Pro',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const PantallaNotas(),
    );
  }
}

// Modelo de datos para las notas
class Nota {
  String texto;
  String categoria;
  DateTime fecha;

  Nota({required this.texto, required this.categoria, required this.fecha});

  Map<String, dynamic> toMap() {
    return {
      'texto': texto,
      'categoria': categoria,
      'fecha': fecha.toIso8601String(),
    };
  }

  factory Nota.fromMap(Map<String, dynamic> map) {
    return Nota(
      texto: map['texto'],
      categoria: map['categoria'] ?? 'General',
      fecha: DateTime.parse(map['fecha']),
    );
  }
}

class PantallaNotas extends StatefulWidget {
  const PantallaNotas({super.key});

  @override
  State<PantallaNotas> createState() => _PantallaNotasState();
}

class _PantallaNotasState extends State<PantallaNotas> {
  late stt.SpeechToText _speech;
  late FlutterTts _tts;

  bool _estaEscuchando = false;
  String _textoEscuchado = 'Presiona el micrófono para hablar...';
  String _categoriaSeleccionada = 'Escuela';
  String _filtroCategoria = 'Todas';

  List<Nota> _listaNotas = [];
  final List<String> _categorias = ['Escuela', 'Personal', 'Ideas', 'General'];

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _tts = FlutterTts();
    _configurarTTS();
    _cargarNotas();
  }

  // Configuración de la voz para que suene más natural
  void _configurarTTS() async {
    await _tts.setLanguage('es-MX');
    await _tts.setSpeechRate(0.45); // Velocidad más natural (0.0 a 1.0)
    await _tts.setPitch(1.0);      // Tono normal
    await _tts.setVolume(1.0);
  }

  // Cargar notas guardadas en memoria
  void _cargarNotas() async {
    final prefs = await SharedPreferences.getInstance();
    final String? notasString = prefs.getString('notas_guardadas');
    if (notasString != null) {
      final List<dynamic> jsonList = jsonDecode(notasString);
      setState(() {
        _listaNotas = jsonList.map((item) => Nota.fromMap(item)).toList();
      });
    }
  }

  // Guardar notas en memoria
  void _guardarNotasEnMemoria() async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonNotas = jsonEncode(_listaNotas.map((n) => n.toMap()).toList());
    await prefs.setString('notas_guardadas', jsonNotas);
  }

  void _escucharVoz() async {
    if (!_estaEscuchando) {
      bool disponible = await _speech.initialize();
      if (disponible) {
        setState(() => _estaEscuchando = true);
        _speech.listen(
          localeId: 'es_MX',
          onResult: (val) {
            setState(() {
              _textoEscuchado = val.recognizedWords;
            });
          },
        );
      }
    } else {
      setState(() => _estaEscuchando = false);
      _speech.stop();
      if (_textoEscuchado.isNotEmpty && !_textoEscuchado.startsWith('Presiona')) {
        final nuevaNota = Nota(
          texto: _textoEscuchado,
          categoria: _categoriaSeleccionada,
          fecha: DateTime.now(),
        );
        setState(() {
          _listaNotas.insert(0, nuevaNota);
          _textoEscuchado = 'Presiona el micrófono para hablar...';
        });
        _guardarNotasEnMemoria();
        _leerEnVozAlta('Nota guardada');
      }
    }
  }

  void _eliminarNota(int index) {
    setState(() {
      _listaNotas.removeAt(index);
    });
    _guardarNotasEnMemoria();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nota eliminada')),
    );
  }

  void _leerEnVozAlta(String texto) async {
    await _tts.stop();
    await _tts.speak(texto);
  }

  List<Nota> get _notasFiltradas {
    if (_filtroCategoria == 'Todas') {
      return _listaNotas;
    }
    return _listaNotas.where((n) => n.categoria == _filtroCategoria).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notas: $_filtroCategoria'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      // Menú de navegación lateral (Drawer)
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.deepPurple),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mic, size: 48, color: Colors.white),
                  SizedBox(height: 10),
                  Text('Gestor de Notas', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  Text('Proyecto Universitario', style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.all_inbox),
              title: const Text('Todas las notas'),
              selected: _filtroCategoria == 'Todas',
              onTap: () {
                setState(() => _filtroCategoria = 'Todas');
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ..._categorias.map((cat) => ListTile(
                  leading: Icon(_obtenerIconoCategoria(cat)),
                  title: Text(cat),
                  selected: _filtroCategoria == cat,
                  onTap: () {
                    setState(() => _filtroCategoria = cat);
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      ),
      body: Column(
        children: [
          // Selector de categoría para la nueva nota
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.deepPurple.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Categoría al dictar:', style: TextStyle(fontWeight: FontWeight.bold)),
                DropdownButton<String>(
                  value: _categoriaSeleccionada,
                  items: _categorias.map((cat) {
                    return DropdownMenuItem(value: cat, child: Text(cat));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _categoriaSeleccionada = val);
                  },
                ),
              ],
            ),
          ),
          // Área de vista previa del dictado
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            color: Colors.grey.shade100,
            child: Text(
              _textoEscuchado,
              style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ),
          const Divider(height: 1),
          // Lista de notas guardadas
          Expanded(
            child: _notasFiltradas.isEmpty
                ? const Center(child: Text('No hay notas en esta sección'))
                : ListView.builder(
                    itemCount: _notasFiltradas.length,
                    itemBuilder: (context, index) {
                      final nota = _notasFiltradas[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.deepPurple.shade100,
                            child: Icon(_obtenerIconoCategoria(nota.categoria), color: Colors.deepPurple),
                          ),
                          title: Text(nota.texto, style: const TextStyle(fontWeight: FontWeight.w500)),
                          subtitle: Text('${nota.categoria} • ${_formatearFecha(nota.fecha)}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.volume_up, color: Colors.deepPurple),
                                onPressed: () => _leerEnVozAlta(nota.texto),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent),
                                onPressed: () => _eliminarNota(_listaNotas.indexOf(nota)),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _escucharVoz,
        backgroundColor: _estaEscuchando ? Colors.red : Colors.deepPurple,
        foregroundColor: Colors.white,
        icon: Icon(_estaEscuchando ? Icons.stop : Icons.mic),
        label: Text(_estaEscuchando ? 'Detener y Guardar' : 'Dictar Nota'),
      ),
    );
  }

  IconData _obtenerIconoCategoria(String cat) {
    switch (cat) {
      case 'Escuela': return Icons.school;
      case 'Personal': return Icons.person;
      case 'Ideas': return Icons.lightbulb;
      default: return Icons.note;
    }
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day}/${fecha.month} ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}';
  }
}