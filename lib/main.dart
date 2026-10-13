// ==========================================
// 1. ARRANQUE DE LA APP
// ==========================================
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

// Aquí arranca todo: le decimos a Flutter que se prepare y lanzamos nuestra app.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LifeFlowApp());
}

// Configuramos el diseño general de la app, el tema y la pantalla con la que empezamos.
class LifeFlowApp extends StatelessWidget {
  const LifeFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LifeFlow',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        fontFamily: 'Roboto',
      ),
      home: const PantallaSeleccionPerfil(),
    );
  }
}

// ==========================================
// 2. NUESTRO MODELO DE DATOS (ElementoFlow)
// ==========================================
// Esta es la "plantilla" de cómo guardamos cada nota o recordatorio.
class ElementoFlow {
  final int id;
  final String texto;
  final String perfil;
  final String tipo;
  final DateTime fechaCreacion;
  final DateTime? fechaRecordatorio;

  ElementoFlow({
    required this.id,
    required this.texto,
    required this.perfil,
    required this.tipo,
    required this.fechaCreacion,
    this.fechaRecordatorio,
  });

  // Pasamos nuestro objeto a formato mapa (JSON) para poder guardarlo en el celu.
  Map<String, dynamic> toMap() => {
        'id': id,
        'texto': texto,
        'perfil': perfil,
        'tipo': tipo,
        'fechaCreacion': fechaCreacion.toIso8601String(),
        'fechaRecordatorio': fechaRecordatorio?.toIso8601String(),
      };

  // Reconstruimos el objeto cuando lo leemos de la memoria del teléfono.
  factory ElementoFlow.fromMap(Map<String, dynamic> map) {
    return ElementoFlow(
      id: (map['id'] as num?)?.toInt() ??
          DateTime.now().microsecondsSinceEpoch,
      texto: map['texto']?.toString() ?? '',
      perfil: map['perfil']?.toString() ?? 'Estudiante',
      tipo: map['tipo']?.toString() ?? 'Nota',
      fechaCreacion: DateTime.tryParse(
            map['fechaCreacion']?.toString() ?? '',
          ) ??
          DateTime.now(),
      fechaRecordatorio: DateTime.tryParse(
        map['fechaRecordatorio']?.toString() ?? '',
      ),
    );
  }
}

// ==========================================
// 3. PANTALLA DE INICIO (Elegir perfil)
// ==========================================
// Aquí dejamos que el usuario elija si entra como estudiante o adulto mayor.
class PantallaSeleccionPerfil extends StatelessWidget {
  const PantallaSeleccionPerfil({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'LifeFlow',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '¿Cómo quieres usar la app hoy?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 48),
              // Botón grandote para el Modo Estudiante
              _tarjeta(
                context,
                'Modo Estudiante',
                'Organiza apuntes, tareas y recordatorios de clase',
                Icons.school_rounded,
                const Color(0xFF0F172A),
                'Estudiante',
              ),
              const SizedBox(height: 20),
              // Botón grandote para el Modo Adulto Mayor
              _tarjeta(
                context,
                'Modo Adulto Mayor / Asistido',
                'Memoria digital, medicinas y apoyo de voz amigable',
                Icons.accessibility_new_rounded,
                const Color(0xFFC2410C),
                'Adulto Mayor',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Hicimos esta función para no repetir código al armar las tarjetas de los perfiles.
  Widget _tarjeta(
    BuildContext context,
    String titulo,
    String subtitulo,
    IconData icono,
    Color color,
    String perfil,
  ) {
    return Card(
      color: Colors.white,
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Nos movemos a la pantalla principal mandándole el perfil que eligieron.
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PantallaPrincipal(perfilInicial: perfil),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Icon(icono, size: 36, color: color),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(subtitulo),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 4. LA PANTALLA PRINCIPAL (El corazón de la app)
// ==========================================
class PantallaPrincipal extends StatefulWidget {
  final String perfilInicial;

  const PantallaPrincipal({
    super.key,
    required this.perfilInicial,
  });

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  // Canal para comunicarnos con Android y poder hacer llamadas telefónicas.
  static const MethodChannel _telefono =
      MethodChannel('lifeflow/telefono');

  // Nuestras herramientas de voz (hablar y escuchar) y los temporizadores para las alertas.
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final Map<int, Timer> _temporizadores = {};

  late String _perfilActivo;

  String _tipoActual = 'Nota';
  String _textoDictado = '';
  String _numeroEmergencia = '';

  bool _estaEscuchando = false;
  bool _finalizando = false;
  bool _cargando = true;

  DateTime? _horaSeleccionada;
  List<ElementoFlow> _elementos = [];

  @override
  void initState() {
    super.initState();
    _perfilActivo = widget.perfilInicial;
    _configurarTTS();
    _cargarDatos(); // Apenas abre, leemos lo que teníamos guardado antes.
  }

  @override
  void dispose() {
    // Limpiamos temporizadores y apagamos la voz para que no se consuma memoria de más al salir.
    for (final timer in _temporizadores.values) {
      timer.cancel();
    }
    _speech.cancel();
    _tts.stop();
    super.dispose();
  }

  // Configuramos la voz artificial (español de México, velocidad y tono).
  Future<void> _configurarTTS() async {
    await _tts.setLanguage('es-MX');
    await _tts.setVolume(1);
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1);
  }

  // Función sencilla para hacer que el celu hable y lea textos en voz alta.
  Future<void> _reproducirVoz(String mensaje) async {
    try {
      await _tts.stop();
      await _tts.speak(mensaje);
    } catch (e) {
      debugPrint('Error de voz: $e');
    }
  }

  // Mostramos un avisito flotante rápido (SnackBar) en la parte baja de la pantalla.
  void _mostrarMensaje(String mensaje) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  // ==========================================
  // 5. CARGAR Y GUARDAR DATOS (Memoria local)
  // ==========================================
  // Buscamos en la memoria del celu las notas y el número de emergencia guardados.
  Future<void> _cargarDatos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final datos = prefs.getString('lifeflow_items');
      final numero = prefs.getString('lifeflow_numero_emergencia') ?? '';

      List<ElementoFlow> cargados = [];

      if (datos != null && datos.isNotEmpty) {
        final decoded = jsonDecode(datos);

        if (decoded is List) {
          for (final item in decoded) {
            try {
              cargados.add(
                ElementoFlow.fromMap(
                  Map<String, dynamic>.from(item as Map),
                ),
              );
            } catch (e) {
              debugPrint('Registro no válido: $e');
            }
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _elementos = cargados;
        _numeroEmergencia = numero;
        _cargando = false;
      });

      // Volvemos a programar las alarmas si teníamos recordatorios pendientes.
      for (final item in cargados) {
        if (item.tipo == 'Recordatorio') {
          _programarTimerInterno(item);
        }
      }
    } catch (e) {
      debugPrint('Error cargando datos: $e');

      if (!mounted) return;

      setState(() {
        _cargando = false;
      });

      _mostrarMensaje('No se pudieron cargar los datos guardados.');
    }
  }

  // Guardamos nuestra lista completa de notas/recordatorios actualizados.
  Future<void> _guardarDatos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final datos = jsonEncode(
        _elementos.map((e) => e.toMap()).toList(),
      );

      final correcto = await prefs.setString(
        'lifeflow_items',
        datos,
      );

      if (!correcto) {
        _mostrarMensaje('No se pudieron guardar los datos.');
      }
    } catch (e) {
      debugPrint('Error guardando datos: $e');
      _mostrarMensaje('Error al guardar la información.');
    }
  }

  // ==========================================
  // 6. RECORDATORIOS Y ALERTAS
  // ==========================================
  // Programamos un temporizador para que avise exactamente a la hora que pidió el usuario.
  void _programarTimerInterno(ElementoFlow item) {
    final fecha = item.fechaRecordatorio;
    if (fecha == null) return;

    final diferencia = fecha.difference(DateTime.now());

    if (diferencia <= Duration.zero) return;

    _temporizadores[item.id]?.cancel();

    _temporizadores[item.id] = Timer(
      diferencia,
      () {
        _temporizadores.remove(item.id);
        if (mounted) _lanzarAlerta(item);
      },
    );
  }

  // Salta cuando llega la hora: abre un diálogo en pantalla y hace que el celu hable.
  void _lanzarAlerta(ElementoFlow item) {
    if (!mounted) return;

    final titulo = item.perfil == 'Adulto Mayor'
        ? 'Recordatorio importante'
        : 'Recordatorio pendiente';

    _reproducirVoz('$titulo: ${item.texto}');

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(titulo),
        content: Text(item.texto),
        actions: [
          TextButton(
            onPressed: () {
              _tts.stop();
              Navigator.pop(dialogContext);
            },
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 7. RECONOCIMIENTO DE VOZ (Dictado)
  // ==========================================
  // Prendemos el micrófono para empezar a escuchar lo que dice la persona.
  Future<void> _iniciarDictado() async {
    if (_finalizando || _cargando) return;

    try {
      final disponible = await _speech.initialize(
        onStatus: (estado) {
          debugPrint('Micrófono: $estado');

          if ((estado == 'done' || estado == 'notListening') &&
              _estaEscuchando &&
              !_finalizando) {
            _finalizarDictado();
          }
        },
        onError: (error) {
          debugPrint('Reconocimiento: $error');

          if (_estaEscuchando && !_finalizando) {
            _finalizarDictado();
          }
        },
      );

      if (!mounted) return;

      if (!disponible) {
        _mostrarMensaje('No se pudo activar el micrófono.');
        return;
      }

      setState(() {
        _textoDictado = '';
        _estaEscuchando = true;
      });

      await _speech.listen(
        localeId: 'es_MX',
        onResult: (resultado) {
          if (!mounted) return;

          setState(() {
            _textoDictado = resultado.recognizedWords;
          });
        },
      );
    } catch (e) {
      debugPrint('Error al iniciar micrófono: $e');

      if (!mounted) return;

      setState(() {
        _estaEscuchando = false;
      });

      _mostrarMensaje('No se pudo iniciar el dictado.');
    }
  }

  // Apagamos el micrófono y guardamos el texto que acaban de dictar.
  Future<void> _finalizarDictado() async {
    if (_finalizando) return;

    _finalizando = true;

    try {
      if (_speech.isListening) {
        await _speech.stop();
      }

      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      setState(() {
        _estaEscuchando = false;
      });

      if (_textoDictado.trim().isNotEmpty) {
        await _guardarRegistro();
      } else {
        _mostrarMensaje('No se reconoció texto. Inténtalo nuevamente.');
      }
    } catch (e) {
      debugPrint('Error al finalizar dictado: $e');
      _mostrarMensaje('No se pudo finalizar el dictado.');
    } finally {
      _finalizando = false;
    }
  }

  // Botón para alternar: si está escuchando lo detenemos, y si está callado nos ponemos a escuchar.
  Future<void> _toggleEscuchaVoz() async {
    if (_finalizando || _cargando) return;

    if (_estaEscuchando) {
      await _finalizarDictado();
    } else {
      await _iniciarDictado();
    }
  }

  // ==========================================
  // 8. ENTENDER FECHAS Y HORAS DEL DICTADO
  // ==========================================
  // Revisamos si el usuario dijo una fecha u hora en su voz para programar bien el recordatorio.
  Map<String, dynamic> _procesarDictadoRecordatorio(
    String textoOriginal,
  ) {
    final ahora = DateTime.now();
    String texto = textoOriginal.trim();
    DateTime fechaBase = DateTime(
      ahora.year,
      ahora.month,
      ahora.day,
    );

    bool fechaExplicita = false;
    bool horaExplicita = false;

    final meses = <String, int>{
      'enero': 1,
      'febrero': 2,
      'marzo': 3,
      'abril': 4,
      'mayo': 5,
      'junio': 6,
      'julio': 7,
      'agosto': 8,
      'septiembre': 9,
      'setiembre': 9,
      'octubre': 10,
      'noviembre': 11,
      'diciembre': 12,
    };

    final fechaRegex = RegExp(
      r'\b(\d{1,2})\s+de\s+'
      r'(enero|febrero|marzo|abril|mayo|junio|julio|'
      r'agosto|septiembre|setiembre|octubre|noviembre|diciembre)\b',
      caseSensitive: false,
    );

    final coincidenciaFecha = fechaRegex.firstMatch(texto);

    if (coincidenciaFecha != null) {
      final dia = int.parse(coincidenciaFecha.group(1)!);
      final mes = meses[coincidenciaFecha.group(2)!.toLowerCase()]!;

      var candidata = DateTime(ahora.year, mes, dia);

      if (candidata.month == mes && candidata.day == dia) {
        if (candidata.isBefore(fechaBase)) {
          candidata = DateTime(ahora.year + 1, mes, dia);
        }

        if (candidata.month == mes && candidata.day == dia) {
          fechaBase = candidata;
          fechaExplicita = true;
          texto = texto.replaceFirst(fechaRegex, '').trim();
        }
      }
    } else {
      final mananaRegex = RegExp(
        r'\b(mañana|día siguiente)\b',
        caseSensitive: false,
      );

      if (mananaRegex.hasMatch(texto)) {
        fechaBase = DateTime(
          ahora.year,
          ahora.month,
          ahora.day + 1,
        );
        fechaExplicita = true;
        texto = texto.replaceFirst(mananaRegex, '').trim();
      }
    }

    int hora = 9;
    int minuto = 0;

    final horaRegex = RegExp(
      r'\b(?:a\s+las?\s+|las\s+)'
      r'(\d{1,2})(?::(\d{2}))?'
      r'\s*(am|pm|de la mañana|de la tarde|de la noche)?\b',
      caseSensitive: false,
    );

    final coincidenciaHora = horaRegex.firstMatch(texto);

    if (coincidenciaHora != null) {
      int h = int.parse(coincidenciaHora.group(1)!);
      final m = int.tryParse(coincidenciaHora.group(2) ?? '0') ?? 0;
      final periodo = coincidenciaHora.group(3)?.toLowerCase() ?? '';

      if (h >= 1 && h <= 24 && m >= 0 && m <= 59) {
        if (periodo.contains('pm') ||
            periodo.contains('tarde') ||
            periodo.contains('noche')) {
          if (h < 12) h += 12;
        } else if (periodo.contains('am') ||
            periodo.contains('mañana')) {
          if (h == 12) h = 0;
        } else if (h < 7) {
          h += 12;
        }

        if (h == 24 && m == 0) h = 0;

        if (h <= 23) {
          hora = h;
          minuto = m;
          horaExplicita = true;
          texto = texto.replaceFirst(horaRegex, '').trim();
        }
      }
    }

    DateTime fechaFinal;

    if (_horaSeleccionada != null && !horaExplicita) {
      fechaFinal = DateTime(
        fechaBase.year,
        fechaBase.month,
        fechaBase.day,
        _horaSeleccionada!.hour,
        _horaSeleccionada!.minute,
      );
    } else {
      fechaFinal = DateTime(
        fechaBase.year,
        fechaBase.month,
        fechaBase.day,
        hora,
        minuto,
      );
    }

    if (!fechaExplicita && fechaFinal.isBefore(ahora)) {
      fechaFinal = fechaFinal.add(const Duration(days: 1));
    }

    texto = texto
        .replaceAll(
          RegExp(r'\b(para el|a las|a la)\b', caseSensitive: false),
          '',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (texto.isEmpty) {
      texto = textoOriginal.trim();
    }

    return {
      'fecha': fechaFinal,
      'texto': texto,
    };
  }

  // Creamos el objeto final, lo metemos a la lista, lo guardamos y confirmamos con voz.
  Future<void> _guardarRegistro() async {
    if (_cargando) return;

    final dictado = _textoDictado.trim();
    if (dictado.isEmpty) return;

    DateTime? fecha;
    String textoFinal = dictado;

    if (_tipoActual == 'Recordatorio') {
      final resultado = _procesarDictadoRecordatorio(dictado);
      fecha = resultado['fecha'] as DateTime;
      textoFinal = resultado['texto'] as String;
    }

    final nuevo = ElementoFlow(
      id: DateTime.now().microsecondsSinceEpoch,
      texto: textoFinal,
      perfil: _perfilActivo,
      tipo: _tipoActual,
      fechaCreacion: DateTime.now(),
      fechaRecordatorio: fecha,
    );

    if (!mounted) return;

    setState(() {
      _elementos.insert(0, nuevo);
      _textoDictado = '';
      _horaSeleccionada = null;
    });

    await _guardarDatos();

    if (fecha != null) {
      _programarTimerInterno(nuevo);
    }

    await _reproducirVoz(
      nuevo.tipo == 'Recordatorio'
          ? 'Recordatorio guardado'
          : 'Nota guardada',
    );
  }

  // Borramos la nota o recordatorio y cancelamos su alarma para que ya no suene.
  Future<void> _eliminarElemento(ElementoFlow item) async {
    _temporizadores[item.id]?.cancel();
    _temporizadores.remove(item.id);

    setState(() {
      _elementos.removeWhere((e) => e.id == item.id);
    });

    await _guardarDatos();
  }

  // ==========================================
  // 9. BOTÓN DE EMERGENCIA (SOS)
  // ==========================================
  // Ventana para que el usuario escriba su número de contacto de emergencia.
  Future<void> _configurarNumeroEmergencia() async {
    final controlador = TextEditingController(
      text: _numeroEmergencia,
    );

    final numero = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Contacto de emergencia'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Ingresa un número real autorizado para realizar '
              'llamadas de prueba. No utilices números de emergencia.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controlador,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Número telefónico',
                hintText: '10 dígitos',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(
                dialogContext,
                controlador.text.trim(),
              );
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    await Future.delayed(const Duration(milliseconds: 250));
    controlador.dispose();

    if (!mounted || numero == null) return;

    final limpio = numero.replaceAll(RegExp(r'[\s()-]'), '');

    if (!RegExp(r'^\+?[0-9]{7,15}$').hasMatch(limpio)) {
      _mostrarMensaje('Introduce un número telefónico válido.');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final guardado = await prefs.setString(
      'lifeflow_numero_emergencia',
      limpio,
    );

    if (!mounted) return;

    if (guardado) {
      setState(() {
        _numeroEmergencia = limpio;
      });
      _mostrarMensaje('Contacto guardado.');
    } else {
      _mostrarMensaje('No se pudo guardar el contacto.');
    }
  }

  // Disparamos la llamada telefónica usando el canal nativo del teléfono.
  Future<void> _hacerLlamadaEmergencia() async {
    if (_numeroEmergencia.isEmpty) {
      await _configurarNumeroEmergencia();
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar llamada'),
        content: Text(
          '¿Quieres llamar ahora al número $_numeroEmergencia?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Llamar'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    try {
      await _telefono.invokeMethod<void>(
        'llamar',
        {'numero': _numeroEmergencia},
      );
    } on PlatformException catch (e) {
      _mostrarMensaje(
        e.message ?? 'No se pudo iniciar la llamada.',
      );
    } on MissingPluginException {
      _mostrarMensaje(
        'La función de llamada requiere configurar Android.',
      );
    }
  }

  // ==========================================
  // 10. INTERFAZ VISUAL (Diseño y Pantallas)
  // ==========================================
  bool get _esAdultoMayor => _perfilActivo == 'Adulto Mayor';

  // Cambiamos de color según el perfil (Naranja si es adulto mayor, oscuro si es estudiante).
  Color get _colorPrincipal => _esAdultoMayor
      ? const Color(0xFFC2410C)
      : const Color(0xFF0F172A);

  Color get _colorAcento => _esAdultoMayor
      ? const Color(0xFFEA580C)
      : const Color(0xFF2563EB);

  // Formateamos la fecha para que se vea amigable ("Hoy", "Mañana" o la fecha exacta).
  String _formatearFecha(DateTime fecha) {
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final dia = DateTime(fecha.year, fecha.month, fecha.day);

    String etiqueta;

    if (dia == hoy) {
      etiqueta = 'Hoy';
    } else if (dia == hoy.add(const Duration(days: 1))) {
      etiqueta = 'Mañana';
    } else {
      etiqueta = '${fecha.day}/${fecha.month}/${fecha.year}';
    }

    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');

    return '$etiqueta · $hora:$minuto';
  }

  // Botón rápido para los accesos del modo asistido.
  Widget _botonRapido(
    String texto,
    VoidCallback accion,
    double escala, {
    bool sos = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: accion,
        style: ElevatedButton.styleFrom(
          backgroundColor: sos ? Colors.red.shade50 : Colors.white,
          foregroundColor:
              sos ? Colors.red.shade700 : _colorPrincipal,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          texto,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12 * escala,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // Pestañas de arriba para cambiar entre ver "Notas" o "Recordatorios".
  Widget _pestana(String tipo, IconData icono, double escala) {
    final seleccionada = _tipoActual == tipo;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _tipoActual = tipo;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: seleccionada ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: seleccionada
                  ? _colorPrincipal.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.05),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icono,
                size: 18 * escala,
                color: seleccionada
                    ? _colorPrincipal
                    : Colors.grey,
              ),
              const SizedBox(width: 7),
              Text(
                tipo,
                style: TextStyle(
                  fontSize: 13 * escala,
                  fontWeight: seleccionada
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Selector chiquito en la barra superior para cambiar de perfil al vuelo.
  Widget _selectorPerfil(String perfil, double escala) {
    final seleccionado = _perfilActivo == perfil;

    return InkWell(
      onTap: () {
        setState(() {
          _perfilActivo = perfil;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: seleccionado ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          perfil == 'Adulto Mayor' ? 'Asistido' : 'Estudiante',
          style: TextStyle(
            fontSize: 11 * escala,
            fontWeight: seleccionado
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // Tarjeta visual que dibuja cada nota o recordatorio en la lista.
  Widget _tarjetaElemento(ElementoFlow item, double escala) {
    final recordatorio = item.tipo == 'Recordatorio';

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: EdgeInsets.all(12 * escala),
        child: Row(
          children: [
            Icon(
              recordatorio
                  ? Icons.alarm_rounded
                  : Icons.description_outlined,
              color: recordatorio
                  ? Colors.amber.shade800
                  : _colorAcento,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.texto,
                    style: TextStyle(
                      fontSize: 14 * escala,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (recordatorio &&
                      item.fechaRecordatorio != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(
                        '⏰ ${_formatearFecha(item.fechaRecordatorio!)}',
                        style: TextStyle(
                          fontSize: 11 * escala,
                          color: _colorAcento,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Escuchar',
              onPressed: () => _reproducirVoz(item.texto),
              icon: const Icon(Icons.volume_up_outlined),
            ),
            IconButton(
              tooltip: 'Eliminar',
              onPressed: () => _eliminarElemento(item),
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ),
      ),
    );
  }

  // Aquí armamos toda la estructura visual de la pantalla principal.
  @override
  Widget build(BuildContext context) {
    final escala = _esAdultoMayor ? 1.2 : 1.0; // Agrandamos letras si está en modo adulto mayor.

    final filtrados = _elementos.where((item) {
      return item.perfil == _perfilActivo &&
          item.tipo == _tipoActual;
    }).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Barra de arriba: botón para regresar, título y selector de perfil.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new),
                  ),
                  Expanded(
                    child: Text(
                      'LifeFlow',
                      style: TextStyle(
                        fontSize: 22 * escala,
                        fontWeight: FontWeight.w800,
                        color: _colorPrincipal,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        _selectorPerfil('Estudiante', escala),
                        _selectorPerfil('Adulto Mayor', escala),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Si es adulto mayor, mostramos botones especiales de ayuda y llamadas.
            if (_esAdultoMayor)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _botonRapido(
                            '💊 Tomar Medicamento',
                            () {
                              setState(() {
                                _tipoActual = 'Recordatorio';
                              });
                              _reproducirVoz(
                                'Dicta el medicamento y la hora',
                              );
                            },
                            escala,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _botonRapido(
                            '🏥 Cita Médica',
                            () {
                              setState(() {
                                _tipoActual = 'Recordatorio';
                              });
                              _reproducirVoz(
                                'Dicta la fecha y hora de tu cita',
                              );
                            },
                            escala,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _botonRapido(
                      '🚨 Llamar a Contacto de Emergencia',
                      _hacerLlamadaEmergencia,
                      escala,
                      sos: true,
                    ),
                    TextButton.icon(
                      onPressed: _configurarNumeroEmergencia,
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Configurar contacto'),
                    ),
                  ],
                ),
              ),
            // Pestañas para cambiar entre Notas y Recordatorios.
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Row(
                children: [
                  _pestana(
                    'Nota',
                    Icons.description_outlined,
                    escala,
                  ),
                  const SizedBox(width: 10),
                  _pestana(
                    'Recordatorio',
                    Icons.alarm_rounded,
                    escala,
                  ),
                ],
              ),
            ),
            // Cuadro donde se va mostrando lo que vamos dictando con la voz.
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
              padding: EdgeInsets.all(16 * escala),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _estaEscuchando
                        ? (_textoDictado.isEmpty
                            ? 'Escuchando tu voz...'
                            : _textoDictado)
                        : (_textoDictado.isNotEmpty
                            ? _textoDictado
                            : 'Presiona para dictar tu ${_tipoActual.toLowerCase()}...'),
                    style: TextStyle(
                      fontSize: 14 * escala,
                      color: _estaEscuchando
                          ? _colorAcento
                          : Colors.grey.shade700,
                    ),
                  ),
                  if (_tipoActual == 'Recordatorio') ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final seleccion = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );

                        if (seleccion == null || !mounted) return;

                        final ahora = DateTime.now();

                        setState(() {
                          _horaSeleccionada = DateTime(
                            ahora.year,
                            ahora.month,
                            ahora.day,
                            seleccion.hour,
                            seleccion.minute,
                          );
                        });
                      },
                      icon: const Icon(Icons.access_time),
                      label: Text(
                        _horaSeleccionada == null
                            ? 'Hora automática o seleccionar'
                            : 'Hora: ${_horaSeleccionada!.hour.toString().padLeft(2, '0')}:${_horaSeleccionada!.minute.toString().padLeft(2, '0')}',
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Lista con las notas guardadas o un aviso si está vacía.
            Expanded(
              child: _cargando
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : filtrados.isEmpty
                      ? Center(
                          child: Text(
                            'Sin ${_tipoActual.toLowerCase()}s guardadas',
                            style: TextStyle(
                              fontSize: 14 * escala,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                          ),
                          itemCount: filtrados.length,
                          itemBuilder: (_, indice) {
                            return _tarjetaElemento(
                              filtrados[indice],
                              escala,
                            );
                          },
                        ),
            ),
            const SizedBox(height: 82),
          ],
        ),
      ),
      // Botón flotante del micrófono abajo en el centro para dictar.
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerFloat,
      floatingActionButton: ElevatedButton.icon(
        onPressed: _cargando || _finalizando
            ? null
            : _toggleEscuchaVoz,
        style: ElevatedButton.styleFrom(
          backgroundColor: _estaEscuchando
              ? const Color(0xFFEF4444)
              : _colorPrincipal,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: 28 * escala,
            vertical: 16,
          ),
        ),
        icon: Icon(
          _estaEscuchando
              ? Icons.stop_rounded
              : Icons.mic_rounded,
        ),
        label: Text(
          _estaEscuchando
              ? 'Detener'
              : 'Presiona para Dictar',
        ),
      ),
    );
  }
}