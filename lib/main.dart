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
import 'notificaciones_service.dart';

// Aquí arranca todo: le decimos a Flutter que se prepare y lanzamos nuestra app.
Future<void> main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await NotificacionesService.inicializar(); 
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
  final DateTime? fechaEvento; // Agregado.

  // Agregado.
  // Cantidad de días antes del evento.
  // null significa que no se configuró anticipación.
  final int? diasAnticipacion;

  // true: el aviso depende de la fecha del evento.
  // false: el aviso tiene una fecha independiente.
  final bool avisoRelativo;

  ElementoFlow({
    required this.id,
    required this.texto,
    required this.perfil,
    required this.tipo,
    required this.fechaCreacion,
    this.fechaRecordatorio,
    this.fechaEvento, // Agregado.
    this.diasAnticipacion, // Agregado.
    this.avisoRelativo = false, // Agregado.
  });

  // Pasamos nuestro objeto a formato mapa (JSON) para poder guardarlo en el celu.
  Map<String, dynamic> toMap() => {
        'id': id,
        'texto': texto,
        'perfil': perfil,
        'tipo': tipo,
        'fechaCreacion': fechaCreacion.toIso8601String(),
        'fechaRecordatorio': fechaRecordatorio?.toIso8601String(),
        'fechaEvento': fechaEvento?.toIso8601String(), // Agregado.
        'diasAnticipacion': diasAnticipacion, // Agregado.
        'avisoRelativo': avisoRelativo, // Agregado.
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
      // Agregado.
      fechaEvento: DateTime.tryParse(
        map['fechaEvento']?.toString() ?? '',
      ),
      diasAnticipacion:
          (map['diasAnticipacion'] as num?)?.toInt(),
      avisoRelativo: map['avisoRelativo'] == true,
    );
  }

  // Agregado. Creamos una versión modificada del registro.
  ElementoFlow copyWith({
    String? texto,
    DateTime? fechaEvento,
    DateTime? fechaRecordatorio,
    int? diasAnticipacion, // Agregado.
    bool? avisoRelativo, // Agregado.
  }) {
    final relativoFinal = avisoRelativo ?? this.avisoRelativo; // Agregado.

    return ElementoFlow(
      id: id,
      texto: texto ?? this.texto,
      perfil: perfil,
      tipo: tipo,
      fechaCreacion: fechaCreacion,
      fechaEvento: fechaEvento ?? this.fechaEvento,
      fechaRecordatorio:
          fechaRecordatorio ?? this.fechaRecordatorio,
      diasAnticipacion: relativoFinal
          ? (diasAnticipacion ?? this.diasAnticipacion)
          : null,
      avisoRelativo: relativoFinal,
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
      backgroundColor: const Color(0xFFF8F9FC),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logotipo y nombre de LifeFlow.
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7659E8),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    const Text(
                      'LifeFlow',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF24243A),
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      'Tu asistente personal',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF77788D),
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Encabezado de selección.
                    const Text(
                      'Elige tu perfil',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF24243A),
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      'Selecciona cómo quieres utilizar la aplicación.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF77788D),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Perfil Estudiante.
                    _tarjeta(
                      context,
                      'Estudiante',
                      'Organiza tus notas, tareas y recordatorios.',
                      Icons.school_rounded,
                      const Color(0xFF7659E8),
                      'Estudiante',
                    ),

                    const SizedBox(height: 14),

                    // Perfil Adulto Mayor / Asistido.
                    _tarjeta(
                      context,
                      'Adulto Mayor / Asistido',
                      'Recordatorios, medicamentos y asistencia por voz.',
                      Icons.volunteer_activism_rounded,
                      const Color(0xFFC2410C),
                      'Adulto Mayor',
                    ),

                    const SizedBox(height: 38),

                    // Mensaje inferior.
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.mic_none_rounded,
                          color: Color(0xFF77788D),
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Organiza tu día con tu voz',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF77788D),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Tarjeta de selección de perfil.
  Widget _tarjeta(
    BuildContext context,
    String titulo,
    String subtitulo,
    IconData icono,
    Color color,
    String perfil,
  ) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PantallaPrincipal(
                perfilInicial: perfil,
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withValues(alpha: 0.18),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.025),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icono,
                  size: 28,
                  color: color,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF24243A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitulo,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF77788D),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 6),

              Icon(
                Icons.chevron_right_rounded,
                color: color,
                size: 24,
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
  int? _ultimoRecordatorioId; // Agregado. Identificador del último recordatorio utilizado.

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

  Future<void> _programarNotificacion(ElementoFlow item) async {
    if (item.tipo != 'Recordatorio') return;

    final fecha = item.fechaRecordatorio;

    if (fecha == null || !fecha.isAfter(DateTime.now())) {
      return;
    }

    await NotificacionesService.programar(
      id: item.id,
      titulo: 'Recordatorio LifeFlow',
      mensaje: item.texto,
      fecha: fecha,
    );
  }

  Future<void> _actualizarNotificacion(ElementoFlow item) async {
    try {
      await NotificacionesService.cancelar(item.id);

      await _programarNotificacion(item);

      debugPrint(
        'NOTIFICACION: actualizada correctamente',
      );
    } catch (e, stackTrace) {
      debugPrint('ERROR AL ACTUALIZAR NOTIFICACION: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _recuperarUltimoRecordatorio() {
    final recordatorios = _elementos
        .where(
          (elemento) =>
              elemento.tipo == 'Recordatorio' &&
              elemento.perfil == _perfilActivo,
        )
        .toList();

    if (recordatorios.isEmpty) {
      _ultimoRecordatorioId = null;
      return;
    }

    recordatorios.sort(
      (a, b) => b.fechaCreacion.compareTo(a.fechaCreacion),
    );

    _ultimoRecordatorioId = recordatorios.first.id;
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

      // Recuperar el último recordatorio del perfil activo.
      _recuperarUltimoRecordatorio();

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
    int diasAnticipacion = 0; // Agregado.

    // Reconocer fechas especificas.
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
    } 
    // else {
    //   final mananaRegex = RegExp(
    //     r'\b(mañana|día siguiente)\b',
    //     caseSensitive: false,
    //   );

    //   if (mananaRegex.hasMatch(texto)) {
    //     fechaBase = DateTime(
    //       ahora.year,
    //       ahora.month,
    //       ahora.day + 1,
    //     );
    //     fechaExplicita = true;
    //     texto = texto.replaceFirst(mananaRegex, '').trim();
    //   }
    // }

    // Reconocer días de la semana.
    if (!fechaExplicita) {
      final diasSemana = <String, int>{
        'lunes': DateTime.monday,
        'martes': DateTime.tuesday,
        'miércoles': DateTime.wednesday,
        'miercoles': DateTime.wednesday,
        'jueves': DateTime.thursday,
        'viernes': DateTime.friday,
        'sábado': DateTime.saturday,
        'sabado': DateTime.saturday,
        'domingo': DateTime.sunday,
      };

      final diaRegex = RegExp(
        r'\b(?:(el|este|próximo|proximo)\s+)?'
        r'(lunes|martes|miércoles|miercoles|jueves|'
        r'viernes|sábado|sabado|domingo)\b',
        caseSensitive: false,
      );

      final coincidenciaDia = diaRegex.firstMatch(texto);

      if (coincidenciaDia != null) {
        final nombreDia =
            coincidenciaDia.group(2)!.toLowerCase();

        final diaObjetivo = diasSemana[nombreDia]!;

        int diferencia =
            (diaObjetivo - ahora.weekday + 7) % 7;

        // "Próximo lunes" se interpreta como
        // el lunes de la siguiente semana.
        final modificador =
            coincidenciaDia.group(1)?.toLowerCase() ?? '';

        if (modificador == 'próximo' ||
            modificador == 'proximo') {
          diferencia = diferencia == 0
              ? 7
              : diferencia + 7;
        }

        fechaBase = DateTime(
          ahora.year,
          ahora.month,
          ahora.day + diferencia,
        );

        fechaExplicita = true;

        texto = texto.replaceFirst(diaRegex, '').trim();
      }
    }

    // Reconocer "mañana".
    if (!fechaExplicita) {
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

    // Reconocer anticipación.
    final anticipacionRegex = RegExp(
      r'\b(?:avísame|avisame|recuérdame|recuerdame)?'
      r'\s*(?:con\s+)?'
      r'(un|uno|una|dos|tres|cuatro|cinco|'
      r'seis|siete|\d+)\s+días?\s+antes\b',
      caseSensitive: false,
    );

    final coincidenciaAnticipacion =
        anticipacionRegex.firstMatch(texto);

    if (coincidenciaAnticipacion != null) {
      final cantidad =
          coincidenciaAnticipacion.group(1)!.toLowerCase();

      final numeros = <String, int>{
        'un': 1,
        'uno': 1,
        'una': 1,
        'dos': 2,
        'tres': 3,
        'cuatro': 4,
        'cinco': 5,
        'seis': 6,
        'siete': 7,
      };

      diasAnticipacion =
          numeros[cantidad] ?? int.tryParse(cantidad) ?? 0;

      texto = texto
          .replaceFirst(anticipacionRegex, '')
          .trim();
    }

    // Reconocer hora.
    int hora = 9;
    int minuto = 0;

    final horaRegex = RegExp(
      r'\b(?:a\s+las?\s+|las\s+)'
      r'(\d{1,2}|una|uno|dos|tres|cuatro|cinco|'
      r'seis|siete|ocho|nueve|diez|once|doce)'
      r'(?::(\d{2})|\s+y\s+(media|cuarto))?'
      r'\s*(am|pm|a\.m\.|p\.m\.|'
      r'de la mañana|de la tarde|de la noche|'
      r'del mediodía|de la madrugada)?',
      caseSensitive: false,
    );

    final coincidenciaHora = horaRegex.firstMatch(texto);

    if (coincidenciaHora != null) {
      const numeros = <String, int>{
        'una': 1,
        'uno': 1,
        'dos': 2,
        'tres': 3,
        'cuatro': 4,
        'cinco': 5,
        'seis': 6,
        'siete': 7,
        'ocho': 8,
        'nueve': 9,
        'diez': 10,
        'once': 11,
        'doce': 12,
      };

      final valorHora = coincidenciaHora.group(1)!.toLowerCase();

      int? h = int.tryParse(valorHora) ?? numeros[valorHora];
      int m = int.tryParse(coincidenciaHora.group(2) ?? '') ?? 0;

      final fraccion = coincidenciaHora.group(3)?.toLowerCase();
      final periodo = (coincidenciaHora.group(4) ?? '').toLowerCase();

      if (fraccion == 'media') {
        m = 30;
      } else if (fraccion == 'cuarto') {
        m = 15;
      }

      if (h != null && h >= 1 && h <= 23 && m <= 59) {
        bool valida = true;

        if (periodo.contains('pm') ||
            periodo.contains('p.m.') ||
            periodo.contains('tarde') ||
            periodo.contains('noche')) {
          if (h > 12) {
            valida = false;
          } else if (h < 12) {
            h += 12;
          }
        } else if (periodo.contains('am') ||
            periodo.contains('a.m.') ||
            periodo.contains('mañana') ||
            periodo.contains('madrugada')) {
          if (h > 12) {
            valida = false;
          } else if (h == 12) {
            h = 0;
          }
        } else if (periodo.contains('mediodía')) {
          if (h != 12) valida = false;
        } else if (h < 7) {
          // Conservamos el comportamiento anterior de LifeFlow.
          h += 12;
        }

        if (valida) {
          hora = h;
          minuto = m;
          horaExplicita = true;
          texto = texto.replaceFirst(horaRegex, '').trim();
        }
      }
    }

    // Calcular fecha del evento.
    final horaFinal =
      _horaSeleccionada != null && !horaExplicita
          ? _horaSeleccionada!.hour
          : hora;

    final minutoFinal =
      _horaSeleccionada != null && !horaExplicita
          ? _horaSeleccionada!.minute
          : minuto;

    DateTime fechaEvento = DateTime(
      fechaBase.year,
      fechaBase.month,
      fechaBase.day,
      horaFinal,
      minutoFinal,
    );

    if (!fechaExplicita && fechaEvento.isBefore(ahora)) {
      fechaEvento = DateTime(
        fechaBase.year,
        fechaBase.month,
        fechaBase.day + 1,
        horaFinal,
        minutoFinal,
      );
    }

    // Calcular fecha de aviso
    final fechaRecordatorio = DateTime(
      fechaEvento.year,
      fechaEvento.month,
      fechaEvento.day - diasAnticipacion,
      fechaEvento.hour,
      fechaEvento.minute,
    );

    // Limpiar texto
    texto = texto
      .replaceAll(
        RegExp(
          r'\b(para el|a las|a la|pero|avísame|avisame|'
          r'recuérdame|recuerdame)\b',
          caseSensitive: false,
        ),
        '',
      )
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

    if (texto.isEmpty) {
      texto = textoOriginal.trim();
    }

    return {
      'fechaEvento': fechaEvento,
      'fechaRecordatorio': fechaRecordatorio,
      'texto': texto,
      'diasAnticipacion': diasAnticipacion,
    };

    // DateTime fechaFinal;

    // if (_horaSeleccionada != null && !horaExplicita) {
    //   fechaFinal = DateTime(
    //     fechaBase.year,
    //     fechaBase.month,
    //     fechaBase.day,
    //     _horaSeleccionada!.hour,
    //     _horaSeleccionada!.minute,
    //   );
    // } else {
    //   fechaFinal = DateTime(
    //     fechaBase.year,
    //     fechaBase.month,
    //     fechaBase.day,
    //     hora,
    //     minuto,
    //   );
    // }

    // if (!fechaExplicita && fechaFinal.isBefore(ahora)) {
    //   fechaFinal = fechaFinal.add(const Duration(days: 1));
    // }

    // texto = texto
    //     .replaceAll(
    //       RegExp(r'\b(para el|a las|a la)\b', caseSensitive: false),
    //       '',
    //     )
    //     .replaceAll(RegExp(r'\s+'), ' ')
    //     .trim();

    // if (texto.isEmpty) {
    //   texto = textoOriginal.trim();
    // }

    // return {
    //   'fecha': fechaFinal,
    //   'texto': texto,
    // };
  }

  // Agregado. Detecta si el usuario quiere modificar un recordatorio.
  bool _esInstruccionModificacion(String texto) {
    final instruccion = texto.toLowerCase().trim();

    // Detectar instrucciones explícitas de modificación.
    final modificacionRegex = RegExp(
      r'\b('
      r'cámbialo|cambialo|cámbiala|cambiala|'
      r'cambia|cambiar|'
      r'modifica|modifícalo|modificalo|'
      r'actualiza|corrige|'
      r'muévelo|muevelo|muévela|muevela|'
      r'posponlo|pospónlo|posponla|'
      r'adelántalo|adelantalo|adelanta|'
      r'retrásalo|retrasalo'
      r')\b',
      caseSensitive: false,
    );

    if (modificacionRegex.hasMatch(instruccion)) {
      return true;
    }

    // Detectar correcciones de una instrucción anterior.
    final correccionRegex = RegExp(
      r'^(mejor|más bien|mas bien|en realidad)\b',
      caseSensitive: false,
    );

    if (correccionRegex.hasMatch(instruccion)) {
      return _obtenerUltimoRecordatorio() != null;
    }

    // Detectar cambios de anticipación sobre un recordatorio existente.
    // Solo se interpreta como modificación cuando la instrucción
    // comienza directamente con "avísame N días antes".
    final anticipacionRegex = RegExp(
      r'^(avísame|avisame)\s+'
      r'(un|uno|una|dos|tres|cuatro|cinco|'
      r'seis|siete|ocho|nueve|diez|\d+)'
      r'\s+d[ií]as?\s+antes\b',
      caseSensitive: false,
    );

    if (anticipacionRegex.hasMatch(instruccion)) {
      return _obtenerUltimoRecordatorio() != null;
    }

    return false;
  }

    // Agregado. Busca el último recordatorio utilizado.
    ElementoFlow? _obtenerUltimoRecordatorio() {
      if (_ultimoRecordatorioId == null) {
        return null;
      }

      for (final elemento in _elementos) {
        if (elemento.id == _ultimoRecordatorioId &&
            elemento.tipo == 'Recordatorio' &&
            elemento.perfil == _perfilActivo) {
          return elemento;
        }
      }

      return null;
    }

  // Agregado. Modificar hora recordatorio.
  Future<void> _modificarRecordatorio(String instruccion) async {
    final anterior = _obtenerUltimoRecordatorio();

    if (anterior == null) {
      _mostrarMensaje(
        'No hay un recordatorio reciente para modificar.',
      );
      return;
    }

    final texto = instruccion.toLowerCase();

    final horaInterpretada =
        _interpretarHoraModificacion(instruccion);

    // Detectar cambios relativos de anticipación.
    final anticipacionRegex = RegExp(
      r'\b(\d+|un|uno|una|dos|tres|cuatro|cinco|'
      r'seis|siete|ocho|nueve|diez)\s+d[ií]as?\s+antes\b',
      caseSensitive: false,
    );

    final anticipacionMatch = anticipacionRegex.firstMatch(texto);

    const numeros = <String, int>{
      'un': 1,
      'uno': 1,
      'una': 1,
      'dos': 2,
      'tres': 3,
      'cuatro': 4,
      'cinco': 5,
      'seis': 6,
      'siete': 7,
      'ocho': 8,
      'nueve': 9,
      'diez': 10,
    };

    int? nuevaAnticipacion;

    if (anticipacionMatch != null) {
      final palabra = anticipacionMatch.group(1)!;
      nuevaAnticipacion =
          int.tryParse(palabra) ?? numeros[palabra];
    }

    DateTime? nuevaFechaEvento = anterior.fechaEvento;
    DateTime? nuevaFechaAviso = anterior.fechaRecordatorio;

    int? diasAnticipacion = anterior.diasAnticipacion;
    bool avisoRelativo = anterior.avisoRelativo;

    if (nuevaFechaAviso == null) {
      _mostrarMensaje('El recordatorio no tiene fecha de aviso.');
      return;
    }

    // 1. Cambio explícito de anticipación.
    if (nuevaAnticipacion != null) {
      if (nuevaFechaEvento == null) {
        _mostrarMensaje(
          'No se puede calcular la anticipación sin fecha de evento.',
        );
        return;
      }

      diasAnticipacion = nuevaAnticipacion;
      avisoRelativo = true;

      nuevaFechaAviso = DateTime(
        nuevaFechaEvento.year,
        nuevaFechaEvento.month,
        nuevaFechaEvento.day - nuevaAnticipacion,
        nuevaFechaAviso.hour,
        nuevaFechaAviso.minute,
      );
    } else {
      // 2. Determinar si se modifica el evento o el aviso.
      String? destino;

      if (texto.contains('aviso') ||
          texto.contains('notificación') ||
          texto.contains('notificacion') ||
          texto.contains('avísame') ||
          texto.contains('avisame')) {
        destino = 'Aviso';
      } else if (texto.contains('evento') ||
          texto.contains('entrega') ||
          texto.contains('actividad')) {
        destino = 'Evento';
      } else {
        destino = await _solicitarAclaracion(
          pregunta:
              '¿Quieres modificar la fecha del aviso o del evento o ambas?',
          opciones: ['Aviso', 'Evento', 'Ambas'],
        );
      }

      if (destino == null || !mounted) return;

      final fechaBase = destino == 'Evento' || destino == 'Ambas'
          ? nuevaFechaEvento
          : nuevaFechaAviso;

      if (fechaBase == null) {
        _mostrarMensaje(
          'No hay una fecha disponible para modificar.',
        );
        return;
      }

      final fechaInterpretada =
          _interpretarFechaModificacion(instruccion, fechaBase);

      if (fechaInterpretada == null && horaInterpretada == null) {
        _mostrarMensaje(
          'No pude identificar una fecha ni una hora nueva.',
        );
        return;
      }

      DateTime fechaActualizada =
          fechaInterpretada ?? fechaBase;

      // 3. Si también mencionó una hora, modificarla.
      if (horaInterpretada != null) {
        int hora = horaInterpretada['hora']!;
        final minuto = horaInterpretada['minuto']!;

        if (horaInterpretada['periodoExplicito'] == 0 &&
            hora <= 12) {
          final periodo = await _solicitarAclaracion(
            pregunta: '¿De la mañana o de la noche?',
            opciones: ['Mañana', 'Noche'],
          );

          if (periodo == null || !mounted) return;

          if (periodo == 'Mañana') {
            if (hora == 12) hora = 0;
          } else {
            if (hora < 12) hora += 12;
          }
        }

        fechaActualizada = DateTime(
          fechaActualizada.year,
          fechaActualizada.month,
          fechaActualizada.day,
          hora,
          minuto,
        );
      }

      // 4. Aplicar el cambio.
      if (destino == 'Ambas') {
        if (nuevaFechaEvento == null) {
          _mostrarMensaje(
            'No se puede modificar ambas fechas '
            'porque el recordatorio no tiene fecha de evento.',
          );
          return;
        }

        // Calcular cuánto se desplaza el evento.
        final diferencia = fechaActualizada.difference(
          nuevaFechaEvento,
        );

        // Desplazar el evento y el aviso por igual.
        nuevaFechaEvento = fechaActualizada;

        nuevaFechaAviso = nuevaFechaAviso.add(
          diferencia,
        );

        // Conservar la relación original entre las fechas.
        // No modificamos diasAnticipacion ni avisoRelativo.

      } else if (destino == 'Evento') {
        final fechaEventoAnterior = nuevaFechaEvento;

        nuevaFechaEvento = fechaActualizada;

        // Conservar anticipación cuando cambia el día.
        if (avisoRelativo &&
            diasAnticipacion != null &&
            fechaEventoAnterior != null &&
            fechaInterpretada != null) {
          nuevaFechaAviso = DateTime(
            nuevaFechaEvento.year,
            nuevaFechaEvento.month,
            nuevaFechaEvento.day - diasAnticipacion,
            nuevaFechaAviso.hour,
            nuevaFechaAviso.minute,
          );
        }

      } else if (destino == 'Aviso') {
        nuevaFechaAviso = fechaActualizada;

        // Si se establece directamente la fecha del aviso,
        // deja de depender automáticamente del evento.
        if (fechaInterpretada != null) {
          avisoRelativo = false;
          diasAnticipacion = null;
        }
      }
    }

    // 5. Evitar avisos en el pasado.
    if (!nuevaFechaAviso.isAfter(DateTime.now())) {
      _mostrarMensaje(
        'El aviso quedaría en el pasado. '
        'No se realizó el cambio.',
      );
      return;
    }

    final actualizado = anterior.copyWith(
      fechaEvento: nuevaFechaEvento,
      fechaRecordatorio: nuevaFechaAviso,
      diasAnticipacion: diasAnticipacion,
      avisoRelativo: avisoRelativo,
    );

    final indice = _elementos.indexWhere(
      (elemento) => elemento.id == anterior.id,
    );

    if (indice == -1 || !mounted) {
      _mostrarMensaje('No se encontró el recordatorio.');
      return;
    }

    // 6. Actualizar el registro.
    setState(() {
      _elementos[indice] = actualizado;
      _ultimoRecordatorioId = actualizado.id;
      _textoDictado = '';
      _horaSeleccionada = null;
    });

    // 7. Cancelar el temporizador anterior.
    _temporizadores[actualizado.id]?.cancel();
    _temporizadores.remove(actualizado.id);

    // 8. Guardar y reprogramar.
    await _guardarDatos();
    await _actualizarNotificacion(actualizado);

    if (!mounted) return;

    _programarTimerInterno(actualizado);

    _mostrarMensaje('Recordatorio actualizado.');

    await _reproducirVoz(
      'El recordatorio se actualizó correctamente.',
    );
  }

  // Agregado. Interpretar hora de modificación.
  Map<String, int>? _interpretarHoraModificacion(String texto) {
    final numeros = <String, int>{
      'una': 1,
      'uno': 1,
      'dos': 2,
      'tres': 3,
      'cuatro': 4,
      'cinco': 5,
      'seis': 6,
      'siete': 7,
      'ocho': 8,
      'nueve': 9,
      'diez': 10,
      'once': 11,
      'doce': 12,
    };

    final regex = RegExp(
      r'\b(?:a\s+las?\s+|las\s+)'
      r'(\d{1,2}|una|uno|dos|tres|cuatro|cinco|'
      r'seis|siete|ocho|nueve|diez|once|doce)'
      r'(?::(\d{2})|\s+y\s+(media|cuarto))?'
      r'\s*(am|pm|a\.m\.|p\.m\.|'
      r'de la mañana|de la tarde|de la noche|'
      r'del mediodía|de la madrugada)?',
      caseSensitive: false,
    );

    final coincidencia = regex.firstMatch(texto);

    if (coincidencia == null) return null;

    final valorHora = coincidencia.group(1)!.toLowerCase();

    int? hora = int.tryParse(valorHora) ?? numeros[valorHora];

    if (hora == null) return null;

    int minuto = int.tryParse(coincidencia.group(2) ?? '') ?? 0;

    final fraccion = coincidencia.group(3)?.toLowerCase();

    if (fraccion == 'media') {
      minuto = 30;
    } else if (fraccion == 'cuarto') {
      minuto = 15;
    }

    final periodo = (coincidencia.group(4) ?? '').toLowerCase();

    if (hora < 1 || hora > 23 || minuto > 59) {
      return null;
    }

    bool periodoExplicito = periodo.isNotEmpty;

    if (periodo.contains('pm') ||
        periodo.contains('p.m.') ||
        periodo.contains('tarde') ||
        periodo.contains('noche')) {
      if (hora > 12) return null;
      if (hora < 12) hora += 12;
    } else if (periodo.contains('am') ||
        periodo.contains('a.m.') ||
        periodo.contains('mañana') ||
        periodo.contains('madrugada')) {
      if (hora > 12) return null;
      if (hora == 12) hora = 0;
    } else if (periodo.contains('mediodía')) {
      if (hora != 12) return null;
    }

    return {
      'hora': hora,
      'minuto': minuto,
      'periodoExplicito': periodoExplicito ? 1 : 0,
    };
  }

  // Agregado.
  DateTime? _interpretarFechaModificacion(
    String textoOriginal,
    DateTime fechaActual,
  ) {
    final texto = textoOriginal.toLowerCase().trim();
    final hoy = DateTime.now();

    const numeros = <String, int>{
      'un': 1,
      'uno': 1,
      'una': 1,
      'dos': 2,
      'tres': 3,
      'cuatro': 4,
      'cinco': 5,
      'seis': 6,
      'siete': 7,
      'ocho': 8,
      'nueve': 9,
      'diez': 10,
    };

    const meses = <String, int>{
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

    const diasSemana = <String, int>{
      'lunes': DateTime.monday,
      'martes': DateTime.tuesday,
      'miércoles': DateTime.wednesday,
      'miercoles': DateTime.wednesday,
      'jueves': DateTime.thursday,
      'viernes': DateTime.friday,
      'sábado': DateTime.saturday,
      'sabado': DateTime.saturday,
      'domingo': DateTime.sunday,
    };

    DateTime conservarHora(DateTime fecha) {
      return DateTime(
        fecha.year,
        fecha.month,
        fecha.day,
        fechaActual.hour,
        fechaActual.minute,
      );
    }

    // 1. Posponer o adelantar cierta cantidad de días.
    final desplazamiento = RegExp(
      r'\b(posp[oó]n(?:lo|la)?|retr[aá]salo|'
      r'adel[aá]ntalo|adelanta|mu[eé]velo)\s+'
      r'(\d+|un|uno|una|dos|tres|cuatro|cinco|'
      r'seis|siete|ocho|nueve|diez)\s+d[ií]as?\b',
      caseSensitive: false,
    ).firstMatch(texto);

    if (desplazamiento != null) {
      final palabra = desplazamiento.group(2)!;
      final cantidad = int.tryParse(palabra) ?? numeros[palabra];

      if (cantidad == null) return null;

      final accion = desplazamiento.group(1)!;
      final signo = accion.startsWith('adelant') ||
              accion.startsWith('adelánt')
          ? -1
          : 1;

      return DateTime(
        fechaActual.year,
        fechaActual.month,
        fechaActual.day + signo * cantidad,
        fechaActual.hour,
        fechaActual.minute,
      );
    }

    // 2. Fechas con día y mes.
    final fechaExplicita = RegExp(
      r'\b(\d{1,2})\s+de\s+'
      r'(enero|febrero|marzo|abril|mayo|junio|julio|'
      r'agosto|septiembre|setiembre|octubre|noviembre|diciembre)'
      r'(?:\s+(?:de|del)\s+(\d{4}))?\b',
      caseSensitive: false,
    ).firstMatch(texto);

    if (fechaExplicita != null) {
      final dia = int.parse(fechaExplicita.group(1)!);
      final mes = meses[fechaExplicita.group(2)!]!;
      final anioExplicito = fechaExplicita.group(3);

      int anio = anioExplicito == null
          ? hoy.year
          : int.parse(anioExplicito);

      DateTime fecha = DateTime(anio, mes, dia);

      // Evitar que Dart normalice fechas inexistentes.
      if (fecha.month != mes || fecha.day != dia) {
        return null;
      }

      if (anioExplicito == null) {
        final hoySinHora = DateTime(hoy.year, hoy.month, hoy.day);

        if (fecha.isBefore(hoySinHora)) {
          anio++;
          fecha = DateTime(anio, mes, dia);
        }
      }

      return conservarHora(fecha);
    }

    // 3. Días relativos.
    if (RegExp(r'\bpasado\s+mañana\b').hasMatch(texto)) {
      return conservarHora(
        DateTime(hoy.year, hoy.month, hoy.day + 2),
      );
    }

    if (RegExp(r'\bmañana\b').hasMatch(texto)) {
      return conservarHora(
        DateTime(hoy.year, hoy.month, hoy.day + 1),
      );
    }

    if (RegExp(r'\bhoy\b').hasMatch(texto)) {
      return conservarHora(hoy);
    }

    // 4. Días de la semana.
    for (final entrada in diasSemana.entries) {
      final expresion = RegExp(
        '\\b${entrada.key}\\b',
        caseSensitive: false,
      );

      if (!expresion.hasMatch(texto)) continue;

      final proximo = RegExp(
        '\\b(pr[oó]ximo|siguiente)\\s+${entrada.key}\\b',
        caseSensitive: false,
      ).hasMatch(texto);

      // Interpretamos "próximo" como la próxima semana
      // calendario, de lunes a domingo.
      final diferencia = proximo
          ? (8 - hoy.weekday) + (entrada.value - 1)
          : (entrada.value - hoy.weekday + 7) % 7;

      final dias = !proximo && diferencia == 0
          ? 7
          : diferencia;

      return conservarHora(
        DateTime(hoy.year, hoy.month, hoy.day + dias),
      );
    }

    return null;
  }

  // Agregado. Solicitar aclaración.
  Future<String?> _solicitarAclaracion({
    required String pregunta,
    required List<String> opciones,
  }) async {
    if (!mounted) return null;

    await _reproducirVoz(pregunta);
    if (!mounted) return null;

    final esHorario = opciones.contains('Mañana') &&
        opciones.contains('Noche');

    final esFecha = opciones.contains('Aviso') &&
        opciones.contains('Evento');

    final titulo = esHorario
        ? 'Aclarar horario'
        : esFecha
            ? 'Modificar recordatorio'
            : 'LifeFlow necesita una aclaración';

    final iconoPrincipal = esHorario
        ? Icons.access_time_rounded
        : esFecha
            ? Icons.event_note_rounded
            : Icons.help_outline_rounded;

    IconData iconoOpcion(String opcion) {
      switch (opcion) {
        case 'Aviso':
          return Icons.notifications_active_outlined;
        case 'Evento':
          return Icons.calendar_month_rounded;
        case 'Ambas':
          return Icons.date_range_rounded;
        case 'Mañana':
          return Icons.wb_sunny_outlined;
        case 'Noche':
          return Icons.nightlight_round;
        default:
          return Icons.check_circle_outline_rounded;
      }
    }

    String descripcionOpcion(String opcion) {
      switch (opcion) {
        case 'Aviso':
          return 'Cuándo recibirás la notificación';
        case 'Evento':
          return 'Cuándo ocurrirá la actividad';
        case 'Ambas':
          return 'Mover el evento y el aviso juntos';
        default:
          return '';
      }
    }

    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),

        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Encabezado.
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _colorPrincipal.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      iconoPrincipal,
                      color: _colorPrincipal,
                      size: 26,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titulo,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _colorTexto,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Selecciona una opción',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // Pregunta original.
              Text(
                pregunta,
                style: TextStyle(
                  fontSize: _esAdultoMayor ? 16 : 14,
                  fontWeight: FontWeight.w500,
                  color: _colorTexto,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 18),

              // Opciones disponibles.
              for (final opcion in opciones)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: _colorPrincipal.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        Navigator.pop(dialogContext, opcion);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 15,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _colorPrincipal.withValues(
                              alpha: 0.15,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                color: _colorPrincipal.withValues(
                                  alpha: 0.10,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                iconoOpcion(opcion),
                                color: _colorPrincipal,
                                size: 22,
                              ),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    esFecha
                                        ? opcion == 'Ambas'
                                            ? 'Ambas fechas'
                                            : 'Fecha del ${opcion.toLowerCase()}'
                                        : opcion,
                                    style: TextStyle(
                                      fontSize: _esAdultoMayor ? 15 : 14,
                                      fontWeight: FontWeight.w600,
                                      color: _colorTexto,
                                    ),
                                  ),

                                  if (descripcionOpcion(opcion).isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      descripcionOpcion(opcion),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            Icon(
                              Icons.chevron_right_rounded,
                              color: _colorPrincipal,
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Botón Cancelar.
        actions: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: _colorTexto,
                backgroundColor: const Color(0xFFF5F5F7),
                side: BorderSide.none,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Cancelar'),
            ),
          ),
        ],
      ),
    );
  }

  // Creamos el objeto final, lo metemos a la lista, lo guardamos y confirmamos con voz.
  Future<void> _guardarRegistro() async {
    if (_cargando) return;

    final dictado = _textoDictado.trim();
    if (dictado.isEmpty) return;

    // Agregado.
    // Si el usuario quiere modificar un recordatorio,
    // procesamos el cambio sin crear un registro nuevo.
    if (_esInstruccionModificacion(dictado)) {
      await _modificarRecordatorio(dictado);

      if (mounted) {
        setState(() {
          _textoDictado = '';
          _horaSeleccionada = null;
        });
      }

      return;
    }

    // DateTime? fecha;
    DateTime? fechaRecordatorio;
    DateTime? fechaEvento;  
    int? diasAnticipacion; // Agregado.
    bool avisoRelativo = false; // Agregado. 
    String textoFinal = dictado;

    if (_tipoActual == 'Recordatorio') {
      final resultado = _procesarDictadoRecordatorio(dictado);

      // Agregado.
      final anticipacion =
          resultado['diasAnticipacion'] as int? ?? 0;

      diasAnticipacion = anticipacion;

      // Agregado. 
      // Detectamos si se solicitó anticipación explícita.
      avisoRelativo = RegExp(
        r'\b(?:un|uno|una|dos|tres|cuatro|cinco|'
        r'seis|siete|\d+)\s+días?\s+antes\b',
        caseSensitive: false,
      ).hasMatch(dictado);

      // fecha = resultado['fecha'] as DateTime;
      fechaRecordatorio = resultado['fechaRecordatorio'] as DateTime;
      fechaEvento = resultado['fechaEvento'] as DateTime;
      textoFinal = resultado['texto'] as String;
    }

    // No programamos recordatorios en el pasado.
    if (fechaRecordatorio != null && !fechaRecordatorio.isAfter(DateTime.now())) {
      _mostrarMensaje(
        'La fecha del aviso ya pasó. '
        'Indica otra fecha u hora.',
      );
      return;
    }

    final nuevo = ElementoFlow(
      id: DateTime.now().microsecondsSinceEpoch,
      texto: textoFinal,
      perfil: _perfilActivo,
      tipo: _tipoActual,
      fechaCreacion: DateTime.now(),
      // fechaRecordatorio: fecha,
      fechaRecordatorio: fechaRecordatorio,
      fechaEvento: fechaEvento,
      diasAnticipacion: avisoRelativo
          ? diasAnticipacion
          : null,
      avisoRelativo: avisoRelativo,
    );

    if (!mounted) return;

    setState(() {
      _elementos.insert(0, nuevo);

      // Agregado.
      if (nuevo.tipo == 'Recordatorio') {
        _ultimoRecordatorioId = nuevo.id;
      }

      _textoDictado = '';
      _horaSeleccionada = null;
    });

    await _guardarDatos();
    // await _programarNotificacion(nuevo);
    try {
      await _programarNotificacion(nuevo);
      debugPrint('NOTIFICACION: programada correctamente');
    } catch (e, stackTrace) {
      debugPrint('ERROR AL PROGRAMAR NOTIFICACION: $e');
      debugPrintStack(stackTrace: stackTrace);
    }

    // if (fecha != null) {
    //   _programarTimerInterno(nuevo);
    // }
    if (fechaRecordatorio != null) {
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
    // 1. Cancelar el temporizador de voz.
    _temporizadores[item.id]?.cancel();
    _temporizadores.remove(item.id);

    // 2. Cancelar la notificación programada de Android.
    try {
      await NotificacionesService.cancelar(item.id);

      debugPrint('NOTIFICACION: cancelada al eliminar recordatorio');
    } catch (e) {
      debugPrint('ERROR AL CANCELAR NOTIFICACION: $e');

      if (mounted) {
        _mostrarMensaje(
          'No se pudo cancelar la notificación de Android.',
        );
      }
      return;
    }

    if (!mounted) return;

    // 3. Eliminar el elemento de LifeFlow.
    setState(() {
      _elementos.removeWhere((e) => e.id == item.id);

      // Evitar modificar un recordatorio eliminado.
      if (_ultimoRecordatorioId == item.id) {
        _ultimoRecordatorioId = null;
      }
    });

    // 4. Guardar los cambios.
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
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),

        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado.
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0E5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.contact_phone_rounded,
                      color: Color(0xFFC2410C),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Contacto de emergencia',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF292524),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Configura tu contacto de confianza',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF78716C),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // Mensaje informativo.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Color(0xFFC2410C),
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Utiliza un número real autorizado para '
                        'realizar llamadas de prueba. No ingreses '
                        'números de servicios de emergencia.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: Color(0xFF9A3412),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              const Text(
                'Número telefónico',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF292524),
                ),
              ),

              const SizedBox(height: 10),

              // Campo de teléfono.
              TextField(
                controller: controlador,
                keyboardType: TextInputType.phone,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF292524),
                ),
                decoration: InputDecoration(
                  hintText: 'Ingresa tu número',
                  hintStyle: const TextStyle(
                    color: Color(0xFFA8A29E),
                  ),
                  prefixIcon: const Icon(
                    Icons.phone_outlined,
                    color: Color(0xFFC2410C),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFFAFAF9),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 16,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Color(0xFFE7E5E4),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Color(0xFFC2410C),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Botones inferiores.
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF57534E),
                    backgroundColor: const Color(0xFFF5F5F4),
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                      controlador.text.trim(),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFC2410C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(
                    Icons.check_rounded,
                    size: 18,
                  ),
                  label: const Text('Guardar'),
                ),
              ),
            ],
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
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),

        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado.
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE0E3),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.phone_in_talk_rounded,
                    color: Color(0xFFB91C1C),
                    size: 26,
                  ),
                ),

                const SizedBox(width: 12),

                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Confirmar llamada',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF292524),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Contacto de emergencia',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF78716C),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            const Text(
              '¿Quieres llamar ahora alnúmero?',
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: Color(0xFF57534E),
              ),
            ),

            const SizedBox(height: 16),

            // Número registrado.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 18,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  const Text(
                    'Número registrado',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF9F1239),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    _numeroEmergencia,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF991B1B),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Botones inferiores.
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, false);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF57534E),
                    backgroundColor: const Color(0xFFF5F5F4),
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Cancelar'),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(dialogContext, true);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFB91C1C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(
                    Icons.phone_rounded,
                    size: 18,
                  ),
                  label: const Text('Llamar'),
                ),
              ),
            ],
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
    : const Color(0xFF7659E8);

  // Color get _colorAcento => _esAdultoMayor
  //     ? const Color(0xFFEA580C)
  //     : const Color(0xFF927BF3);

  Color get _colorFondo => _esAdultoMayor
      ? const Color(0xFFFFF9F5)
      : const Color(0xFFF8F9FC);

  Color get _colorTexto => _esAdultoMayor
      ? const Color(0xFF292524)
      : const Color(0xFF24243A);

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
    final esMedicamento = texto.contains('Medicamento');

    final icono = sos
        ? Icons.phone_in_talk_rounded
        : esMedicamento
            ? Icons.medication_rounded
            : Icons.event_available_rounded;

    final titulo = sos
        ? 'Contacto de emergencia'
        : esMedicamento
            ? 'Tomar medicamento'
            : 'Cita médica';

    final descripcion = sos
        ? 'Llamar al contacto registrado'
        : 'Crear aviso';

    final color = sos
        ? const Color(0xFFB91C1C)
        : _colorPrincipal;

    final fondoIcono = sos
        ? const Color(0xFFFFE0E3)
        : _colorPrincipal.withValues(alpha: 0.10);

    return SizedBox(
      width: double.infinity,
      child: Material(
        color: sos
            ? const Color(0xFFFFF1F2)
            : Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: accion,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: EdgeInsets.all(14 * escala),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: sos
                    ? const Color(0xFFFAD4D8)
                    : _colorPrincipal.withValues(alpha: 0.10),
              ),
            ),
            child: sos
                ? Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          color: fondoIcono,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          icono,
                          color: color,
                          size: 23 * escala,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              titulo,
                              style: TextStyle(
                                fontSize: 13 * escala,
                                fontWeight: FontWeight.w700,
                                color: color,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              descripcion,
                              style: TextStyle(
                                fontSize: 10 * escala,
                                color: const Color(0xFFB45353),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_outward_rounded,
                        color: color,
                        size: 20,
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: fondoIcono,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          icono,
                          color: color,
                          size: 25 * escala,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        titulo,
                        style: TextStyle(
                          fontSize: 12 * escala,
                          fontWeight: FontWeight.w700,
                          color: _colorTexto,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        descripcion,
                        style: TextStyle(
                          fontSize: 10 * escala,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // Pestañas de arriba para cambiar entre ver "Notas" o "Recordatorios".
  Widget _pestana(String tipo, IconData icono, double escala) {
    final seleccionada = _tipoActual == tipo;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            setState(() {
              _tipoActual = tipo;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            padding: EdgeInsets.symmetric(
              vertical: 16 * escala,
              horizontal: 8,
            ),
            decoration: BoxDecoration(
              color: seleccionada
                  ? _colorPrincipal
                  : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: seleccionada
                    ? _colorPrincipal
                    : Colors.black.withValues(alpha: 0.04),
              ),
              boxShadow: [
                BoxShadow(
                  color: seleccionada
                      ? _colorPrincipal.withValues(alpha: 0.18)
                      : Colors.black.withValues(alpha: 0.025),
                  blurRadius: seleccionada ? 14 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icono,
                  size: 19 * escala,
                  color: seleccionada
                      ? Colors.white
                      : _colorPrincipal,
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    tipo == 'Nota' ? 'Notas' : 'Recordatorios',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13 * escala,
                      fontWeight: seleccionada
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: seleccionada
                          ? Colors.white
                          : _colorTexto,
                    ),
                  ),
                ),
              ],
            ),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16 * escala),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado de la tarjeta.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: _colorPrincipal.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  recordatorio
                      ? Icons.notifications_none_rounded
                      : Icons.edit_note_rounded,
                  color: _colorPrincipal,
                  size: 23 * escala,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.texto,
                      softWrap: true,
                      style: TextStyle(
                        fontSize: 14 * escala,
                        fontWeight: FontWeight.w700,
                        color: _colorTexto,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      recordatorio ? 'Recordatorio' : 'Nota',
                      style: TextStyle(
                        fontSize: 11 * escala,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Información exclusiva de recordatorios.
          if (recordatorio &&
              (item.fechaEvento != null ||
                  item.fechaRecordatorio != null ||
                  (item.avisoRelativo &&
                      item.diasAnticipacion != null))) ...[
            const SizedBox(height: 14),
            Divider(
              color: Colors.black.withValues(alpha: 0.06),
            ),
            const SizedBox(height: 10),

            // Fecha del evento.
            if (item.fechaEvento != null)
              _detalleFechaElemento(
                icono: Icons.event_outlined,
                titulo: 'Fecha del evento',
                valor: _formatearFecha(item.fechaEvento!),
                escala: escala,
                color: _colorPrincipal,
              ),

            if (item.fechaEvento != null &&
                item.fechaRecordatorio != null)
              const SizedBox(height: 12),

            // Fecha y hora del aviso.
            if (item.fechaRecordatorio != null)
              _detalleFechaElemento(
                icono: Icons.notifications_active_outlined,
                titulo: 'Fecha y hora del aviso',
                valor: _formatearFecha(
                  item.fechaRecordatorio!,
                ),
                escala: escala,
                color: _colorPrincipal,
              ),

            // Anticipación del aviso.
            if (item.avisoRelativo &&
                item.diasAnticipacion != null) ...[
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: _colorPrincipal.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      color: _colorPrincipal,
                      size: 15 * escala,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        item.diasAnticipacion == 1
                            ? 'Aviso programado 1 día antes'
                            : 'Aviso programado ${item.diasAnticipacion} días antes',
                        style: TextStyle(
                          fontSize: 10 * escala,
                          fontWeight: FontWeight.w600,
                          color: _colorPrincipal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],

          const SizedBox(height: 14),

          Divider(
            color: Colors.black.withValues(alpha: 0.06),
          ),

          const SizedBox(height: 6),

          // Botones de escuchar y eliminar.
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                tooltip: 'Escuchar',
                onPressed: () => _reproducirVoz(item.texto),
                style: IconButton.styleFrom(
                  backgroundColor: _colorFondo,
                  foregroundColor: _colorPrincipal,
                ),
                icon: const Icon(
                  Icons.volume_up_outlined,
                ),
              ),

              const SizedBox(width: 8),

              IconButton(
                tooltip: 'Eliminar',
                onPressed: () => _eliminarElemento(item),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFFFF1F2),
                  foregroundColor: const Color(0xFFE05260),
                ),
                icon: const Icon(
                  Icons.delete_outline_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detalleFechaElemento({
    required IconData icono,
    required String titulo,
    required String valor,
    required double escala,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icono,
          size: 16 * escala,
          color: color,
        ),

        const SizedBox(width: 8),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: TextStyle(
                  fontSize: 10 * escala,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                valor,
                softWrap: true,
                style: TextStyle(
                  fontSize: 12 * escala,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Aquí armamos toda la estructura visual de la pantalla principal.
  @override
  Widget build(BuildContext context) {
    final escala = _esAdultoMayor ? 1.2 : 1.0;

    final filtrados = _elementos.where((item) {
      return item.perfil == _perfilActivo &&
          item.tipo == _tipoActual;
    }).toList();

    return Scaffold(
      backgroundColor: _colorFondo,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Encabezado, perfiles y controles.
            SliverToBoxAdapter(
              child: Column(
                children: [
                  // Encabezado de LifeFlow.
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: IconButton(
                            tooltip: 'Regresar',
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: _colorTexto,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _colorPrincipal,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'LifeFlow',
                                style: TextStyle(
                                  fontSize: 22 * escala,
                                  fontWeight: FontWeight.w800,
                                  color: _colorTexto,
                                ),
                              ),
                              Text(
                                'Tu asistente personal',
                                style: TextStyle(
                                  fontSize: 11 * escala,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Selector de perfiles.
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.035),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PERFIL ACTIVO',
                            style: TextStyle(
                              fontSize: 11 * escala,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _selectorPerfil(
                                  'Estudiante',
                                  escala,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _selectorPerfil(
                                  'Adulto Mayor',
                                  escala,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Accesos especiales del perfil Adulto Mayor.
                  if (_esAdultoMayor)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                          ),
                          const SizedBox(height: 8),
                          _botonRapido(
                            '🚨 Llamar a Contacto de Emergencia',
                            _hacerLlamadaEmergencia,
                            escala,
                            sos: true,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Material(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              child: InkWell(
                                onTap: _configurarNumeroEmergencia,
                                borderRadius: BorderRadius.circular(18),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: _colorPrincipal.withValues(alpha: 0.10),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(11),
                                        decoration: BoxDecoration(
                                          color: _colorPrincipal.withValues(alpha: 0.10),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          Icons.contact_phone_rounded,
                                          color: _colorPrincipal,
                                          size: 23,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Configurar contacto',
                                              style: TextStyle(
                                                fontSize: 13 * escala,
                                                fontWeight: FontWeight.w700,
                                                color: _colorTexto,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Administrar número de emergencia',
                                              style: TextStyle(
                                                fontSize: 10 * escala,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.chevron_right_rounded,
                                        color: _colorPrincipal,
                                        size: 24,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Pestañas de notas y recordatorios.
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                    child: Row(
                      children: [
                        _pestana(
                          'Nota',
                          Icons.edit_note_rounded,
                          escala,
                        ),
                        const SizedBox(width: 10),
                        _pestana(
                          'Recordatorio',
                          Icons.notifications_none_rounded,
                          escala,
                        ),
                      ],
                    ),
                  ),

                  // Área de dictado.
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    padding: EdgeInsets.all(16 * escala),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.025),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Encabezado del asistente de voz.
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _colorPrincipal.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.graphic_eq_rounded,
                                color: _colorPrincipal,
                                size: 23 * escala,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Asistente de voz',
                                    style: TextStyle(
                                      fontSize: 15 * escala,
                                      fontWeight: FontWeight.w700,
                                      color: _colorTexto,
                                    ),
                                  ),
                                  Text(
                                    _estaEscuchando
                                        ? 'Escuchando tu voz...'
                                        : 'Listo para escucharte',
                                    style: TextStyle(
                                      fontSize: 11 * escala,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.circle,
                              size: 9,
                              color: _estaEscuchando
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF22A06B),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _estaEscuchando ? 'Activo' : 'Disponible',
                              style: TextStyle(
                                fontSize: 10 * escala,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Texto reconocido durante el dictado.
                        Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(minHeight: 72),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _colorFondo,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            _estaEscuchando
                                ? (_textoDictado.isEmpty
                                    ? 'Escuchando... Puedes comenzar a hablar.'
                                    : _textoDictado)
                                : (_textoDictado.isNotEmpty
                                    ? _textoDictado
                                    : 'Presiona el micrófono para dictar tu ${_tipoActual.toLowerCase()}...'),
                            style: TextStyle(
                              fontSize: 13 * escala,
                              color: _textoDictado.isNotEmpty
                                  ? _colorTexto
                                  : Colors.grey.shade600,
                              height: 1.5,
                            ),
                          ),
                        ),

                        // Selector de hora para recordatorios.
                        if (_tipoActual == 'Recordatorio') ...[
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
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
                              icon: Icon(
                                Icons.access_time_rounded,
                                color: _colorPrincipal,
                              ),
                              label: Text(
                                _horaSeleccionada == null
                                    ? 'Hora automática o seleccionar'
                                    : 'Hora: ${_horaSeleccionada!.hour.toString().padLeft(2, '0')}:${_horaSeleccionada!.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  fontSize: 12 * escala,
                                  color: _colorPrincipal,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                  horizontal: 12,
                                ),
                                side: BorderSide(
                                  color: _colorPrincipal.withValues(alpha: 0.20),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            ),

            // Encabezado de actividades guardadas.
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _tipoActual == 'Nota'
                                ? 'Mis notas'
                                : 'Mis recordatorios',
                            style: TextStyle(
                              fontSize: 18 * escala,
                              fontWeight: FontWeight.w800,
                              color: _colorTexto,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Organiza tus actividades',
                            style: TextStyle(
                              fontSize: 11 * escala,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _colorPrincipal.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${filtrados.length} guardados',
                        style: TextStyle(
                          fontSize: 11 * escala,
                          fontWeight: FontWeight.w700,
                          color: _colorPrincipal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Lista de notas y recordatorios.
            if (_cargando)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
              else if (filtrados.isEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 32 * escala,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.025),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: _colorPrincipal.withValues(alpha: 0.10),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _tipoActual == 'Nota'
                                ? Icons.edit_note_rounded
                                : Icons.notifications_none_rounded,
                            color: _colorPrincipal,
                            size: 36 * escala,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          _tipoActual == 'Nota'
                              ? 'Aún no tienes notas'
                              : 'Aún no tienes recordatorios',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16 * escala,
                            fontWeight: FontWeight.w700,
                            color: _colorTexto,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _tipoActual == 'Nota'
                              ? 'Tus ideas y apuntes aparecerán aquí.'
                              : 'Tus próximos avisos aparecerán aquí.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12 * escala,
                            color: Colors.grey.shade600,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.mic_none_rounded,
                              color: _colorPrincipal,
                              size: 18 * escala,
                            ),
                            const SizedBox(width: 7),
                            Flexible(
                              child: Text(
                                'Usa el micrófono para comenzar',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12 * escala,
                                  fontWeight: FontWeight.w600,
                                  color: _colorPrincipal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList.builder(
                  itemCount: filtrados.length,
                  itemBuilder: (context, indice) {
                    return _tarjetaElemento(
                      filtrados[indice],
                      escala,
                    );
                  },
                ),
              ),

            // Espacio para evitar que el micrófono tape el contenido.
            const SliverToBoxAdapter(
              child: SizedBox(height: 110),
            ),
          ],
        ),
      ),

      // Micrófono fijo en la parte inferior.
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerFloat,

      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _estaEscuchando
                  ? const Color(0xFFFEE2E2)
                  : _colorPrincipal.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Material(
              color: _estaEscuchando
                  ? const Color(0xFFEF4444)
                  : _colorPrincipal,
              shape: const CircleBorder(),
              elevation: 6,
              shadowColor: _colorPrincipal.withValues(alpha: 0.25),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _cargando || _finalizando
                    ? null
                    : _toggleEscuchaVoz,
                child: SizedBox(
                  width: 62,
                  height: 62,
                  child: Icon(
                    _estaEscuchando
                        ? Icons.stop_rounded
                        : Icons.mic_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _estaEscuchando
                  ? 'Detener dictado'
                  : 'Presiona para dictar',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _colorTexto,
              ),
            ),
          ),
        ],
      ),
    );
  }
}