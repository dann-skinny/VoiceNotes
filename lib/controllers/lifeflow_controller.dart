import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart'
    show MissingPluginException, PlatformException;

import '../models/elemento_flow.dart';
import '../services/almacenamiento_service.dart';
import '../services/interprete_fechas.dart';
import '../services/notificaciones_service.dart';
import '../services/recordatorios_service.dart';
import '../services/telefono_service.dart';
import '../services/voz_service.dart';

/// Función con la que el controlador le hace una pregunta con opciones a la persona. La
/// pantalla muestra el diálogo y devuelve la opción elegida (o null si cancela).
typedef SolicitarAclaracion = Future<String?> Function({
  required String pregunta,
  required List<String> opciones,
});

/// Cerebro de LifeFlow: guarda el estado de la app (notas, recordatorios, perfil, dictado) y
/// decide qué hacer en cada caso.
///
/// No dibuja nada: la pantalla lo escucha y se redibuja cuando algo cambia. Para pedirle cosas
/// a la pantalla (mensajes, alertas, preguntas) usa los tres avisos que están más abajo.
class LifeFlowController extends ChangeNotifier {
  LifeFlowController({required String perfilInicial})
      : perfilActivo = perfilInicial;

  // Servicios que usa el controlador (el "backend").
  final AlmacenamientoService _almacenamiento = AlmacenamientoService();
  final VozService _voz = VozService();
  final RecordatoriosService _recordatorios = RecordatoriosService();
  final TelefonoService _telefono = TelefonoService();

  // Avisos que la pantalla conecta al controlador:
  // - alMostrarMensaje: muestra un mensaje corto.
  // - alLanzarAlerta: abre la alerta cuando llega la hora de un recordatorio.
  // - alSolicitarAclaracion: le pregunta algo con opciones a la persona.
  void Function(String mensaje)? alMostrarMensaje;
  void Function(ElementoFlow item)? alLanzarAlerta;
  SolicitarAclaracion? alSolicitarAclaracion;

  /// Perfil elegido: 'Estudiante' o 'Adulto Mayor'.
  String perfilActivo;

  /// Pestaña seleccionada: 'Nota' o 'Recordatorio'.
  String tipoActual = 'Nota';

  /// Texto que el micrófono ha reconocido en el dictado actual.
  String _textoDictado = '';

  /// Número del contacto de emergencia (vacío si no hay ninguno).
  String _numeroEmergencia = '';

  /// Es true mientras el micrófono está escuchando.
  bool _estaEscuchando = false;

  /// Es true mientras se termina un dictado (evita que se dispare dos veces).
  bool _finalizando = false;

  /// Es true mientras se leen los datos guardados al abrir la app.
  bool _cargando = true;

  /// Es true cuando la pantalla ya se cerró; después de eso no se avisa a nadie.
  bool _disposed = false;

  /// Hora elegida a mano en el selector (se usa si no dijo una hora al dictar).
  DateTime? horaSeleccionada;

  /// Todas las notas y recordatorios de todos los perfiles, los más nuevos primero.
  List<ElementoFlow> _elementos = [];

  /// Último recordatorio creado o modificado: es el que cambia cuando la persona dicta una
  /// modificación.
  int? _ultimoRecordatorioId;

  /// Elemento seleccionado desde el botón Editar (null: dictado normal).
  int? _edicionSeleccionadaId;

  /// Destino elegido en el diálogo de edición.
  String? _destinoEdicion;

  // Lectura del estado para la pantalla.
  List<ElementoFlow> get elementos => _elementos;
  String get textoDictado => _textoDictado;
  String get numeroEmergencia => _numeroEmergencia;
  bool get estaEscuchando => _estaEscuchando;
  bool get finalizando => _finalizando;
  bool get cargando => _cargando;
  bool get editandoPorVoz => _edicionSeleccionadaId != null;
  String? get destinoEdicion => _destinoEdicion;

  /// Cancela el modo de edición sin modificar el elemento.
  void cancelarEdicionPorVoz() {
    _actualizar(() {
      _edicionSeleccionadaId = null;
      _destinoEdicion = null;
      _textoDictado = '';
      horaSeleccionada = null;
    });
    if (_estaEscuchando) {
      _estaEscuchando = false;
      _voz.detenerEscucha();
    }
  }

  // Estos tres valores los cambia la pantalla directamente (ella ya se redibuja después).
  // String get perfilActivo => _perfilActivo;
  // set perfilActivo(String valor) => _perfilActivo = valor;

  // String get tipoActual => _tipoActual;
  // set tipoActual(String valor) => _tipoActual = valor;

  // DateTime? get horaSeleccionada => _horaSeleccionada;
  // set horaSeleccionada(DateTime? valor) => _horaSeleccionada = valor;

  /// Indica si el controlador sigue vivo. Funciona como `mounted` en una pantalla: si es false,
  /// hay que dejar de hacer cosas.
  bool get mounted => !_disposed;

  /// Se llama una sola vez al abrir la pantalla: configura la voz y carga lo guardado.
  void iniciar() {
    _voz.configurar();
    _cargarDatos();
  }

  // Al cerrar la pantalla se cancelan los temporizadores y se apaga la voz.
  @override
  void dispose() {
    _disposed = true;
    _recordatorios.cancelarTodos();
    _voz.liberar();
    super.dispose();
  }

  /// Cambia el estado y avisa a la pantalla para que se redibuje.
  void _actualizar(VoidCallback cambio) {
    cambio();
    if (!_disposed) notifyListeners();
  }

  /// Pide a la pantalla que muestre un mensaje corto (solo si sigue abierta).
  void _mostrarMensaje(String mensaje) {
    if (!mounted) return;
    alMostrarMensaje?.call(mensaje);
  }

  // Atajos para que la pantalla use la voz.
  Future<void> hablar(String mensaje) => _voz.hablar(mensaje);
  Future<void> detenerHabla() => _voz.detenerHabla();

  /// Le hace una pregunta a la persona a través de la pantalla. Devuelve la opción elegida, o
  /// null si no hay pantalla conectada o si cancela.
  Future<String?> _solicitarAclaracion({
    required String pregunta,
    required List<String> opciones,
  }) async {
    final aclarar = alSolicitarAclaracion;
    if (aclarar == null) return null;
    return aclarar(pregunta: pregunta, opciones: opciones);
  }

  /// Busca el recordatorio más reciente del perfil activo y lo marca como el "último".
  void _recuperarUltimoRecordatorio() {
    final recordatorios = _elementos
        .where(
          (elemento) =>
              elemento.tipo == 'Recordatorio' &&
              elemento.perfil == perfilActivo,
        )
        .toList();

    if (recordatorios.isEmpty) {
      _ultimoRecordatorioId = null;
      return;
    }

    // Se ordenan del más nuevo al más viejo.
    recordatorios.sort(
      (a, b) => b.fechaCreacion.compareTo(a.fechaCreacion),
    );

    _ultimoRecordatorioId = recordatorios.first.id;
  }

  /// Devuelve el último recordatorio marcado, siempre que siga existiendo y sea del perfil
  /// activo.
  ElementoFlow? _obtenerUltimoRecordatorio() {
    if (_ultimoRecordatorioId == null) {
      return null;
    }

    for (final elemento in _elementos) {
      if (elemento.id == _ultimoRecordatorioId &&
          elemento.tipo == 'Recordatorio' &&
          elemento.perfil == perfilActivo) {
        return elemento;
      }
    }

    return null;
  }

  /// Lee de la memoria las notas, los recordatorios y el número de emergencia al abrir la app.
  Future<void> _cargarDatos() async {
    try {
      final datos = await _almacenamiento.cargar();
      final cargados = datos.elementos;

      if (!mounted) return;

      _actualizar(() {
        _elementos = cargados;
        _numeroEmergencia = datos.numeroEmergencia;
        _cargando = false;
      });

      // Se marca cuál es el último recordatorio del perfil activo.
      _recuperarUltimoRecordatorio();

      // Se vuelven a programar los avisos de los recordatorios que seguían pendientes.
      for (final item in cargados) {
        if (item.tipo == 'Recordatorio') {
          _programarTimerInterno(item);
          try {
            await _programarNotificacionesInterno(item);
          } catch (e) {
            debugPrint('Error restaurando notificaciones: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error cargando datos: $e');

      if (!mounted) return;

      _actualizar(() {
        _cargando = false;
      });

      _mostrarMensaje('No se pudieron cargar los datos guardados.');
    }
  }

  /// Guarda en la memoria la lista completa de notas y recordatorios. Si falla, avisa con un
  /// mensaje.
  Future<void> _guardarDatos() async {
    try {
      final correcto = await _almacenamiento.guardarElementos(_elementos);

      if (!correcto) {
        _mostrarMensaje('No se pudieron guardar los datos.');
      }
    } catch (e) {
      debugPrint('Error guardando datos: $e');
      _mostrarMensaje('Error al guardar la información.');
    }
  }

  /// Programa un aviso normal o un lote de ocurrencias recurrentes en Android.
  Future<void> _programarNotificacionesInterno(ElementoFlow item) async {
    if (item.tipo != 'Recordatorio') return;
    if (!item.esRecurrente) {
      await _recordatorios.actualizarNotificacion(item);
      return;
    }
    final fechas = <DateTime>[];
    var desde = DateTime.now();
    for (var i = 0; i < 32; i++) {
      final siguiente = _recordatorios.proximoAviso(item, desde: desde);
      if (siguiente == null || !siguiente.isAfter(desde)) break;
      fechas.add(siguiente);
      desde = siguiente;
    }
    await NotificacionesService.programarSerie(
      id: item.id,
      titulo: 'Recordatorio VoiceNotes',
      mensaje: item.texto,
      fechas: fechas,
    );
  }

  /// Programa el temporizador de un recordatorio; cuando llegue la hora se lanza la alerta.
  void _programarTimerInterno(ElementoFlow item) {
    _recordatorios.programarTemporizador(item, _dispararAlerta);
  }

  /// Llegó la hora de un recordatorio: se le pide a la pantalla que muestre la alerta.
  void _dispararAlerta(ElementoFlow item) {
    if (mounted) alLanzarAlerta?.call(item);
  }

  /// Inicia un dictado. El servicio de voz gestiona los reinicios de sesión.
  Future<void> _iniciarDictado() async {
    if (_finalizando || _cargando || _estaEscuchando) return;

    try {
      final disponible = await _voz.inicializarEscucha(
        alCambiarEstado: (estado) {
          debugPrint('Micrófono: $estado');
          // No guardar en done/notListening: pueden ser pausas entre sesiones.
        },
        alOcurrirError: (error) {
          debugPrint('Reconocimiento: $error');
          if (mounted) {
            _mostrarMensaje('Problema con el reconocimiento de voz: $error');
          }
          // No finalizar aquí: VozService decide si puede recuperarse.
        },
      );

      if (!mounted) return;
      if (!disponible) {
        _mostrarMensaje('No se pudo activar el micrófono.');
        return;
      }

      _actualizar(() {
        _textoDictado = '';
        _estaEscuchando = true;
      });

      await _voz.escuchar(
        alRecibirTexto: (palabras) {
          if (!mounted || !_estaEscuchando || _finalizando) return;
          _actualizar(() => _textoDictado = palabras);
        },
      );
    } catch (e) {
      debugPrint('Error al iniciar micrófono: $e');
      if (!mounted) return;
      _actualizar(() => _estaEscuchando = false);
      _mostrarMensaje('No se pudo iniciar el dictado.');
    }
  }

  /// Detiene la escucha y guarda una sola vez el texto acumulado.
  Future<void> _finalizarDictado() async {
    if (_finalizando || !_estaEscuchando) return;

    _finalizando = true;
    try {
      await _voz.detenerEscucha();
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;

      _actualizar(() => _estaEscuchando = false);
      if (_textoDictado.trim().isNotEmpty) {
        await _guardarRegistro();
      } else {
        _mostrarMensaje(_edicionSeleccionadaId != null
            ? 'No escuché el cambio. Pulsa el micrófono para intentarlo de nuevo.'
            : 'No se reconoció texto. Inténtalo nuevamente.');
      }
    } catch (e) {
      debugPrint('Error al finalizar dictado: $e');
      if (mounted) _mostrarMensaje('No se pudo finalizar el dictado.');
    } finally {
      _finalizando = false;
      if (mounted) notifyListeners();
    }
  }

  /// El primer toque inicia el dictado; el segundo lo detiene y guarda.
  Future<void> toggleEscuchaVoz() async {
    if (_finalizando || _cargando) return;
    if (_estaEscuchando) {
      await _finalizarDictado();
    } else {
      await _iniciarDictado();
    }
  }

  /// Activa el modo de edición de una tarjeta y pide la instrucción por voz.
  Future<void> iniciarEdicionPorVoz(ElementoFlow item, {String? destino}) async {
    if (!mounted || _cargando || _finalizando || _estaEscuchando) {
      _mostrarMensaje('Termina el dictado actual antes de editar.');
      return;
    }
    if (!_elementos.any((e) => e.id == item.id && e.perfil == perfilActivo)) {
      _mostrarMensaje('No se encontró el elemento seleccionado.');
      return;
    }
    _actualizar(() {
      _edicionSeleccionadaId = item.id;
      _destinoEdicion = item.tipo == 'Recordatorio' ? destino : 'Nota';
      _textoDictado = '';
      horaSeleccionada = null;
      if (item.tipo == 'Recordatorio') {
        _ultimoRecordatorioId = item.id;
      }
    });
    await _voz.hablar(item.tipo == 'Recordatorio'
        ? 'Dicta el cambio para ${destino ?? 'el recordatorio'} de ${item.texto}.'
        : '¿Cómo quieres que quede la nota? Dicta su nuevo contenido.');
    if (mounted && _edicionSeleccionadaId == item.id) {
      _mostrarMensaje('Pulsa el micrófono para dictar el cambio.');
    }
  }

  /// Evita que una orden de edición se convierta en una nota por una variación
  /// del reconocimiento de voz (por ejemplo, 'cámbiale el nombre').
  bool _pareceOrdenDeEdicion(String texto) {
    return RegExp(
      r'^(?:por favor\s+)?(?:c[aá]mbiale|c[aá]mbialo|cambia|cambiar|'
      r'modifica|modificar|edita|editar|renombra|renombrar|'
      r'ponle|corrige|actualiza|mueve|mu[eé]velo|posp[oó]n|'
      r'adelanta|retrasa)\b',
      caseSensitive: false,
    ).hasMatch(texto.trim());
  }

  /// Detecta si lo dictado es una orden para cambiar el último recordatorio en lugar de crear
  /// uno nuevo.
  bool _esInstruccionModificacion(String texto) {
    return InterpreteFechas.esInstruccionModificacion(
      texto,
      hayRecordatorioPrevio: _obtenerUltimoRecordatorio() != null,
    );
  }

  /// Cambia la fecha del aviso, la del evento o ambas del último recordatorio, según lo que
  /// dijo la persona. Si algo no queda claro, se lo pregunta con un diálogo.
  Future<void> _modificarRecordatorio(String instruccion) async {
    // Se parte del último recordatorio; si no hay ninguno, no hay nada que modificar.
    final anterior = _obtenerUltimoRecordatorio();

    if (anterior == null) {
      _mostrarMensaje(
        'No hay un recordatorio reciente para modificar.',
      );
      return;
    }

    // Renombrar no cambia la fecha ni la hora del recordatorio.
    final nuevoNombre = _destinoEdicion == 'Nombre'
        ? (InterpreteFechas.interpretarNombreModificacion(instruccion) ??
            instruccion.trim())
        : InterpreteFechas.interpretarNombreModificacion(instruccion);
    if (nuevoNombre != null && (_destinoEdicion == null || _destinoEdicion == 'Nombre')) {
      final indice = _elementos.indexWhere(
        (elemento) => elemento.id == anterior.id,
      );
      if (indice == -1 || !mounted) {
        _mostrarMensaje('No se encontró el recordatorio.');
        return;
      }

      final actualizado = anterior.copyWith(texto: nuevoNombre);
      _actualizar(() {
        _elementos[indice] = actualizado;
        _ultimoRecordatorioId = actualizado.id;
        _textoDictado = '';
        horaSeleccionada = null;
      });

      await _guardarDatos();
      // Reprograma la notificación para que muestre el texto actualizado.
      await _programarNotificacionesInterno(actualizado);
      if (!mounted) return;

      _mostrarMensaje('Nombre del recordatorio actualizado.');
      await _voz.hablar('El nombre del recordatorio se actualizó correctamente.');
      return;
    }

    final texto = instruccion.toLowerCase();

    // Hora nueva que dijo la persona (puede no haber dicho ninguna).
    final horaInterpretada =
        InterpreteFechas.interpretarHoraModificacion(instruccion);

    // Busca frases como "2 días antes" para cambiar la anticipación del aviso.
    final anticipacionRegex = RegExp(
      r'\b(\d+|un|uno|una|dos|tres|cuatro|cinco|'
      r'seis|siete|ocho|nueve|diez)\s+d[ií]as?\s+antes\b',
      caseSensitive: false,
    );

    final anticipacionMatch = anticipacionRegex.firstMatch(texto);

    // Números escritos con letras y su valor.
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

    // Días de anticipación pedidos (si los hay).
    int? nuevaAnticipacion;

    // Convierte "dos" o "2" en el número 2.
    if (anticipacionMatch != null) {
      final palabra = anticipacionMatch.group(1)!;
      nuevaAnticipacion =
          int.tryParse(palabra) ?? numeros[palabra];
    }

    // Valores nuevos: empiezan igual que los del recordatorio actual y se van cambiando.
    DateTime? nuevaFechaEvento = anterior.fechaEvento;
    DateTime? nuevaFechaAviso = anterior.fechaRecordatorio;

    int? diasAnticipacion = anterior.diasAnticipacion;
    bool avisoRelativo = anterior.avisoRelativo;

    // Sin fecha de aviso no hay nada que mover.
    if (nuevaFechaAviso == null) {
      _mostrarMensaje('El recordatorio no tiene fecha de aviso.');
      return;
    }

    // CASO 1: pidió cambiar la anticipación (por ejemplo "un día antes"). Se recalcula el aviso
    // a partir de la fecha del evento.
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
      // CASO 2: pidió cambiar una fecha u hora. Primero se averigua qué fecha quiere mover: el
      // aviso, el evento o ambas.
      String? destino = _destinoEdicion;

      // Si lo dijo con palabras claras se usa eso; si no, se le pregunta.
      if (destino == null && (texto.contains('aviso') ||
          texto.contains('notificación') ||
          texto.contains('notificacion') ||
          texto.contains('avísame') ||
          texto.contains('avisame'))) {
        destino = 'Aviso';
      } else if (destino == null && (texto.contains('evento') ||
          texto.contains('entrega') ||
          texto.contains('actividad'))) {
        destino = 'Evento';
      } else if (destino == null) {
        destino = await _solicitarAclaracion(
          pregunta:
              '¿Quieres modificar la fecha del aviso o del evento o ambas?',
          opciones: ['Aviso', 'Evento', 'Ambas'],
        );
      }

      // Si cancela el diálogo, no se cambia nada.
      if (destino == null || !mounted) return;

      // Fecha de partida para entender frases como "el lunes" o "mañana".
      final fechaBase = destino == 'Evento' || destino == 'Ambas'
          ? nuevaFechaEvento
          : nuevaFechaAviso;

      if (fechaBase == null) {
        _mostrarMensaje(
          'No hay una fecha disponible para modificar.',
        );
        return;
      }

      // Nueva fecha que dijo la persona (es null si solo dijo una hora).
      // Evita interpretar "de la mañana" (periodo horario) como "mañana" (día).
      final textoParaFecha = instruccion.replaceAll(
        RegExp(r'\b(?:de\s+la\s+mañana|por\s+la\s+mañana)\b',
            caseSensitive: false),
        '',
      );
      final fechaInterpretada = InterpreteFechas.interpretarFechaModificacion(
        textoParaFecha, fechaBase,
      );

      // No dijo ninguna fecha ni hora que se pueda entender.
      if (fechaInterpretada == null && horaInterpretada == null) {
        _mostrarMensaje(
          'No pude identificar una fecha ni una hora nueva.',
        );
        return;
      }

      // Fecha resultante; si solo cambió la hora, se queda el mismo día.
      DateTime fechaActualizada =
          fechaInterpretada ?? fechaBase;

      // Si dijo una hora nueva, se aplica a esa fecha.
      if (horaInterpretada != null) {
        int hora = horaInterpretada['hora']!;
        final minuto = horaInterpretada['minuto']!;

        // No dijo "de la mañana" ni "de la noche" y la hora es de 12 o menos: se le pregunta.
        if (horaInterpretada['periodoExplicito'] == 0 &&
            hora <= 12) {
          final periodo = await _solicitarAclaracion(
            pregunta: '¿De la mañana o de la noche?',
            opciones: ['Mañana', 'Noche'],
          );

          if (periodo == null || !mounted) return;

          // Se pasa a formato de 24 horas: las 12 de la mañana son las 0 y las horas de la
          // noche suman 12.
          if (periodo == 'Mañana') {
            if (hora == 12) hora = 0;
          } else {
            if (hora < 12) hora += 12;
          }
        }

        // Se junta la fecha con la hora nueva.
        fechaActualizada = DateTime(
          fechaActualizada.year,
          fechaActualizada.month,
          fechaActualizada.day,
          hora,
          minuto,
        );
      }

      // Ambas: el evento se mueve a la nueva fecha y el aviso se mueve la misma cantidad de
      // tiempo.
      if (destino == 'Ambas') {
        if (nuevaFechaEvento == null) {
          _mostrarMensaje(
            'No se puede modificar ambas fechas '
            'porque el recordatorio no tiene fecha de evento.',
          );
          return;
        }

        // Cambiar solo la hora conserva ambos días; cambiar solo
        // la fecha conserva ambas horas. La separación se mantiene.
        if (fechaInterpretada != null) {
          final dias = DateTime(
            fechaActualizada.year, fechaActualizada.month,
            fechaActualizada.day,
          ).difference(DateTime(
            nuevaFechaEvento.year, nuevaFechaEvento.month,
            nuevaFechaEvento.day,
          )).inDays;
          nuevaFechaEvento = DateTime(
            nuevaFechaEvento.year, nuevaFechaEvento.month,
            nuevaFechaEvento.day + dias,
            nuevaFechaEvento.hour, nuevaFechaEvento.minute,
          );
          nuevaFechaAviso = DateTime(
            nuevaFechaAviso.year, nuevaFechaAviso.month,
            nuevaFechaAviso.day + dias,
            nuevaFechaAviso.hour, nuevaFechaAviso.minute,
          );
        }
        if (horaInterpretada != null) {
          // La hora dictada se asigna a ambos; no se suma un desplazamiento.
          nuevaFechaEvento = DateTime(
            nuevaFechaEvento.year, nuevaFechaEvento.month,
            nuevaFechaEvento.day, fechaActualizada.hour, fechaActualizada.minute,
          );
          nuevaFechaAviso = DateTime(
            nuevaFechaAviso.year, nuevaFechaAviso.month,
            nuevaFechaAviso.day, fechaActualizada.hour, fechaActualizada.minute,
          );
        }


      // Solo el evento: si el aviso era "X días antes", se recalcula para conservar esa
      // anticipación.
      } else if (destino == 'Evento') {
        final fechaEventoAnterior = nuevaFechaEvento;

        nuevaFechaEvento = fechaActualizada;

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

      // Solo el aviso: si se movió a una fecha concreta, deja de ser "X días antes".
      } else if (destino == 'Aviso') {
        nuevaFechaAviso = fechaActualizada;

        if (fechaInterpretada != null) {
          avisoRelativo = false;
          diasAnticipacion = null;
        }
      }
    }

    if (nuevaFechaEvento != null && nuevaFechaAviso.isAfter(nuevaFechaEvento)) {
      _mostrarMensaje('El aviso no puede quedar después del evento.');
      return;
    }

    // No se permite dejar el aviso en el pasado.
    if (!nuevaFechaAviso.isAfter(DateTime.now())) {
      _mostrarMensaje(
        'El aviso quedaría en el pasado. '
        'No se realizó el cambio.',
      );
      return;
    }

    // Se crea una copia del recordatorio con los datos nuevos.
    final actualizado = anterior.copyWith(
      fechaEvento: nuevaFechaEvento,
      fechaRecordatorio: nuevaFechaAviso,
      diasAnticipacion: diasAnticipacion,
      avisoRelativo: avisoRelativo,
      fechaProximaRepeticion: anterior.esRecurrente ? nuevaFechaAviso : null,
    );

    // Se busca su posición en la lista para reemplazarlo.
    final indice = _elementos.indexWhere(
      (elemento) => elemento.id == anterior.id,
    );

    if (indice == -1 || !mounted) {
      _mostrarMensaje('No se encontró el recordatorio.');
      return;
    }

    // Se reemplaza en la lista, se marca como último recordatorio y se limpia el dictado.
    _actualizar(() {
      _elementos[indice] = actualizado;
      _ultimoRecordatorioId = actualizado.id;
      _textoDictado = '';
      horaSeleccionada = null;
    });

    // Se quita el temporizador viejo, se guarda, y se reprograman la notificación y el
    // temporizador con la fecha nueva.
    _recordatorios.cancelarTemporizador(actualizado.id);

    await _guardarDatos();
    await _programarNotificacionesInterno(actualizado);

    if (!mounted) return;

    _programarTimerInterno(actualizado);

    _mostrarMensaje('Recordatorio actualizado.');

    await _voz.hablar(
      'El recordatorio se actualizó correctamente.',
    );
  }

  /// Convierte lo dictado en una nota o recordatorio nuevo (o en un cambio al último
  /// recordatorio) y lo guarda.
  Future<void> _guardarRegistro() async {
    if (_cargando) return;

    final dictado = _textoDictado.trim();
    if (dictado.isEmpty) return;

    // Si se pulsó Editar, el dictado modifica exclusivamente esa tarjeta.
    if (_edicionSeleccionadaId != null) {
      final id = _edicionSeleccionadaId!;
      final indice = _elementos.indexWhere(
        (e) => e.id == id && e.perfil == perfilActivo,
      );
      if (indice < 0) {
        _edicionSeleccionadaId = null;
        _mostrarMensaje('Ya no existe el elemento seleccionado.');
        return;
      }
      final seleccionado = _elementos[indice];
      if (seleccionado.tipo == 'Recordatorio') {
        _ultimoRecordatorioId = id;
        await _modificarRecordatorio(dictado);
      } else {
        final textoNuevo = dictado.replaceFirst(
          RegExp(r'^(?:cambia|c[aá]mbiale|modifica|edita|pon|ponle|escribe)\s+'
              r'(?:(?:el|la)\s+)?(?:texto|contenido|nota)\s+'
              r'(?:a|por|como)\s+', caseSensitive: false),
          '',
        ).trim();
        if (textoNuevo.isNotEmpty) {
          await editarElemento(seleccionado, texto: textoNuevo);
          if (mounted) await _voz.hablar('Nota actualizada.');
        }
      }
      if (mounted) {
        final exito = seleccionado.tipo != 'Recordatorio' ||
            _textoDictado.trim().isEmpty;
        _actualizar(() {
          if (exito) {
            _edicionSeleccionadaId = null;
            _destinoEdicion = null;
          }
          _textoDictado = '';
          horaSeleccionada = null;
        });
      }
      return;
    }

    // Una instrucción de edición jamás debe guardarse como nota nueva.
    // También funciona cuando la persona dicta la orden sin pulsar Editar.
    if (_esInstruccionModificacion(dictado) ||
        _pareceOrdenDeEdicion(dictado)) {
      if (_obtenerUltimoRecordatorio() == null) {
        _mostrarMensaje('No hay un recordatorio seleccionado para modificar.');
      } else {
        await _modificarRecordatorio(dictado);
      }

      if (mounted) {
        _actualizar(() {
          _textoDictado = '';
          horaSeleccionada = null;
        });
      }

      return;
    }

    // Datos del elemento nuevo; en una nota se quedan vacíos.
    DateTime? fechaRecordatorio;
    DateTime? fechaEvento;
    int? diasAnticipacion;
    bool avisoRelativo = false;
    String textoFinal = dictado;
    bool esRecurrente = false;
    String? tipoRecurrencia;
    int intervaloRecurrencia = 1;
    DateTime? fechaFinRecurrencia;
    DateTime? fechaProximaRepeticion;
    List<int> diasSemanaRecurrencia = const [];


    // En un recordatorio se interpretan las fechas y horas que dijo la persona.
    if (tipoActual == 'Recordatorio') {
      final recurrencia = InterpreteFechas.interpretarRecurrencia(dictado);
      esRecurrente = recurrencia['esRecurrente'] == true;
      // El intérprete necesita el dictado completo para reconocer tanto
      // la recurrencia como la fecha de su primera ocurrencia.
      // No eliminar "cada 8 horas" ni "todos los lunes" antes de llamarlo.
      // El modelo aún no almacena un día fijo del mes.
      if (esRecurrente && recurrencia['diaMesRecurrencia'] != null) {
        _mostrarMensaje('La repetición por día del mes aún no está disponible.');
        return;
      }
      final resultado = InterpreteFechas.procesarDictadoRecordatorio(
        dictado,
        horaSeleccionada: horaSeleccionada,
      );

      final anticipacion =
          resultado['diasAnticipacion'] as int? ?? 0;

      diasAnticipacion = anticipacion;

      // El aviso es relativo si dijo algo como "2 días antes".
      avisoRelativo = RegExp(
        r'\b(?:un|uno|una|dos|tres|cuatro|cinco|'
        r'seis|siete|\d+)\s+días?\s+antes\b',
        caseSensitive: false,
      ).hasMatch(dictado);

      fechaRecordatorio = resultado['fechaRecordatorio'] as DateTime;
      fechaEvento = resultado['fechaEvento'] as DateTime;
      textoFinal = resultado['texto'] as String;
      if (esRecurrente) {
        tipoRecurrencia = recurrencia['tipoRecurrencia'] as String?;
        intervaloRecurrencia = recurrencia['intervaloRecurrencia'] as int? ?? 1;
        diasSemanaRecurrencia = List<int>.from(
          recurrencia['diasSemanaRecurrencia'] as List? ?? const [],
        );
        // El intérprete calcula el primer aviso y la fecha de finalización.
        // Sin hora explícita, el ciclo comienza al dictar la instrucción.
        fechaFinRecurrencia = resultado['fechaFinRecurrencia'] as DateTime?;
        if (fechaFinRecurrencia != null &&
            fechaFinRecurrencia.isBefore(fechaRecordatorio)) {
          _mostrarMensaje('La repetición terminaría antes del primer aviso.');
          return;
        }
        // Para intervalos automáticos, la primera ocurrencia visible debe
        // coincidir con el primer aviso, no con el instante del dictado.
        final horaExplicita = RegExp(
          r'\b(?:a\s+las?|las?)\s+(?:\d{1,2}|una|uno|dos|tres|cuatro|cinco|seis|siete|ocho|nueve|diez|once|doce)\b',
          caseSensitive: false,
        ).hasMatch(recurrencia['textoSinRecurrencia'] as String? ?? dictado);
        if (!horaExplicita && horaSeleccionada == null &&
            tipoRecurrencia != 'dias_semana' &&
            !RegExp(r'\b(?:mañana|hoy|pasado mañana|\d{1,2}\s+de\s+(?:enero|febrero|marzo|abril|mayo|junio|julio|agosto|septiembre|octubre|noviembre|diciembre))\b', caseSensitive: false)
                .hasMatch(recurrencia['textoSinRecurrencia'] as String? ?? '')) {
          fechaEvento = fechaRecordatorio;
        }
        fechaProximaRepeticion = fechaRecordatorio;
      }
    }

    // No se crean avisos con fecha pasada.
    if (fechaRecordatorio != null && !fechaRecordatorio.isAfter(DateTime.now())) {
      _mostrarMensaje(
        'La fecha del aviso ya pasó. '
        'Indica otra fecha u hora.',
      );
      return;
    }

    // Se crea el elemento nuevo con un id único basado en la hora actual.
    final nuevo = ElementoFlow(
      id: DateTime.now().microsecondsSinceEpoch,
      texto: textoFinal,
      perfil: perfilActivo,
      tipo: tipoActual,
      fechaCreacion: DateTime.now(),
      fechaRecordatorio: fechaRecordatorio,
      fechaEvento: fechaEvento,
      diasAnticipacion: avisoRelativo
          ? diasAnticipacion
          : null,
      avisoRelativo: avisoRelativo,
      esRecurrente: esRecurrente,
      tipoRecurrencia: tipoRecurrencia,
      intervaloRecurrencia: intervaloRecurrencia,
      fechaFinRecurrencia: fechaFinRecurrencia,
      fechaProximaRepeticion: fechaProximaRepeticion,
      diasSemanaRecurrencia: diasSemanaRecurrencia,
    );

    if (!mounted) return;

    // Se agrega al inicio de la lista y se limpia el dictado.
    _actualizar(() {
      _elementos.insert(0, nuevo);

      if (nuevo.tipo == 'Recordatorio') {
        _ultimoRecordatorioId = nuevo.id;
      }

      _textoDictado = '';
      horaSeleccionada = null;
    });

    // Se guarda en la memoria y se programa la notificación de Android.
    await _guardarDatos();
    try {
      await _programarNotificacionesInterno(nuevo);
      debugPrint('NOTIFICACION: programada correctamente');
    } catch (e, stackTrace) {
      debugPrint('ERROR AL PROGRAMAR NOTIFICACION: $e');
      debugPrintStack(stackTrace: stackTrace);
    }

    // Temporizador interno para avisar mientras la app está abierta.
    if (fechaRecordatorio != null) {
      _programarTimerInterno(nuevo);
    }

    // Se confirma en voz alta lo que se guardó.
    await _voz.hablar(
      nuevo.tipo == 'Recordatorio'
          ? 'Recordatorio guardado'
          : 'Nota guardada',
    );
  }

  /// Guarda los cambios realizados desde el botón Editar de una tarjeta.
  Future<void> editarElemento(
    ElementoFlow item, {
    required String texto,
    DateTime? fechaEvento,
    DateTime? fechaRecordatorio,
  }) async {
    if (!mounted || _cargando) return;
    final nombre = texto.trim();
    if (nombre.isEmpty) {
      _mostrarMensaje('El texto no puede estar vacío.');
      return;
    }

    final indice = _elementos.indexWhere((e) => e.id == item.id);
    if (indice < 0) {
      _mostrarMensaje('No se encontró el elemento.');
      return;
    }
    final anterior = _elementos[indice];
    final esRecordatorio = anterior.tipo == 'Recordatorio';
    final evento = fechaEvento ?? anterior.fechaEvento;
    final aviso = fechaRecordatorio ?? anterior.fechaRecordatorio;

    if (esRecordatorio && evento != null && aviso != null && aviso.isAfter(evento)) {
      _mostrarMensaje('El aviso no puede ser posterior al evento.');
      return;
    }
    if (esRecordatorio && aviso != null && !aviso.isAfter(DateTime.now())) {
      _mostrarMensaje('El aviso debe estar en el futuro.');
      return;
    }

    // Si se modificó la fecha o la hora del aviso, deja de ser relativo.
    final cambioAviso = aviso != anterior.fechaRecordatorio;
    final relativo = esRecordatorio && anterior.avisoRelativo && !cambioAviso;
    final actualizado = anterior.copyWith(
      texto: nombre,
      fechaEvento: evento,
      fechaRecordatorio: aviso,
      avisoRelativo: relativo,
      diasAnticipacion: relativo ? anterior.diasAnticipacion : null,
    );

    _actualizar(() {
      _elementos[indice] = actualizado;
      if (esRecordatorio) _ultimoRecordatorioId = actualizado.id;
    });
    await _guardarDatos();
    if (!mounted) return;

    if (esRecordatorio) {
      _recordatorios.cancelarTemporizador(actualizado.id);
      try {
        await _programarNotificacionesInterno(actualizado);
      } catch (e) {
        debugPrint('Error actualizando notificación: $e');
        _mostrarMensaje('Se guardó el cambio, pero no se pudo actualizar la notificación.');
      }
      if (!mounted) return;
      _programarTimerInterno(actualizado);
    }
    _mostrarMensaje(esRecordatorio ? 'Recordatorio actualizado.' : 'Nota actualizada.');
  }

  /// Borra una nota o un recordatorio. Primero cancela su aviso; si eso falla, no lo borra.
  Future<void> eliminarElemento(ElementoFlow item) async {
    // Se detiene el temporizador interno.
    _recordatorios.cancelarTemporizador(item.id);

    try {
      await _recordatorios.cancelarNotificacion(item.id);

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

    _actualizar(() {
      _elementos.removeWhere((e) => e.id == item.id);

      if (_ultimoRecordatorioId == item.id) {
        _ultimoRecordatorioId = null;
      }
    });

    await _guardarDatos();
  }

  /// Valida y guarda el número de emergencia que escribió la persona.
  Future<void> guardarNumeroEmergencia(String numero) async {
    // Se quitan espacios, paréntesis y guiones.
    final limpio = numero.replaceAll(RegExp(r'[\s()-]'), '');

    // Debe tener de 7 a 15 dígitos, con un + opcional al inicio.
    if (!RegExp(r'^\+?[0-9]{7,15}$').hasMatch(limpio)) {
      _mostrarMensaje('Introduce un número telefónico válido.');
      return;
    }

    final guardado = await _almacenamiento.guardarNumeroEmergencia(limpio);

    if (!mounted) return;

    if (guardado) {
      _actualizar(() {
        _numeroEmergencia = limpio;
      });

      _mostrarMensaje('Contacto guardado.');
    } else {
      _mostrarMensaje('No se pudo guardar el contacto.');
    }
  }

  /// Llama al contacto de emergencia. Si falla, muestra el motivo.
  Future<void> llamarEmergencia() async {
    try {
      await _telefono.llamar(_numeroEmergencia);
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
}
