
/// Una nota o un recordatorio guardado en LifeFlow.
///
/// No se modifica directamente: para cambiarlo se crea una copia con [copyWith].
class ElementoFlow {
  /// Identificador único.
  final int id;

  /// Texto dictado por el usuario.
  final String texto;

  /// 'Estudiante' o 'Adulto Mayor'.
  final String perfil;

  /// 'Nota' o 'Recordatorio'.
  final String tipo;

  /// Fecha de creación.
  final DateTime fechaCreacion;

  /// Fecha y hora del aviso.
  final DateTime? fechaRecordatorio;

  /// Fecha del evento asociado.
  final DateTime? fechaEvento;

  /// Días de anticipación respecto al evento.
  final int? diasAnticipacion;

  /// Indica si el aviso se calcula respecto al evento.
  final bool avisoRelativo;

  // ============================================================
  // RECORDATORIOS RECURRENTES
  // ============================================================

  /// Indica si el recordatorio tiene una regla de repetición.
  final bool esRecurrente;

  /// Unidad de repetición: horas, dias, semanas, meses o anios.
  ///
  /// También admite 'dias_semana' para días concretos.
  final String? tipoRecurrencia;

  /// Intervalo de repetición.
  ///
  /// Ejemplo: cada 8 horas -> 8.
  /// Ejemplo: cada 2 días -> 2.
  final int intervaloRecurrencia;

  /// Fecha y hora límite de la recurrencia.
  ///
  /// null significa que se repite indefinidamente.
  final DateTime? fechaFinRecurrencia;

  /// Próxima fecha y hora en la que debe notificarse.
  final DateTime? fechaProximaRepeticion;

  /// Permite pausar o reanudar recordatorios recurrentes.
  final bool recurrenciaActiva;

  /// Días concretos de la semana, usando DateTime.monday (1)
  /// hasta DateTime.sunday (7).
  ///
  /// Ejemplo: [1, 3, 5] -> lunes, miércoles y viernes.
  final List<int> diasSemanaRecurrencia;

  ElementoFlow({
    required this.id,
    required this.texto,
    required this.perfil,
    required this.tipo,
    required this.fechaCreacion,
    this.fechaRecordatorio,
    this.fechaEvento,
    this.diasAnticipacion,
    this.avisoRelativo = false,
    this.esRecurrente = false,
    this.tipoRecurrencia,
    this.intervaloRecurrencia = 1,
    this.fechaFinRecurrencia,
    this.fechaProximaRepeticion,
    this.recurrenciaActiva = true,
    this.diasSemanaRecurrencia = const [],
  });

  /// Convierte el elemento a un mapa para almacenarlo.
  Map<String, dynamic> toMap() => {
        'id': id,
        'texto': texto,
        'perfil': perfil,
        'tipo': tipo,
        'fechaCreacion': fechaCreacion.toIso8601String(),
        'fechaRecordatorio': fechaRecordatorio?.toIso8601String(),
        'fechaEvento': fechaEvento?.toIso8601String(),
        'diasAnticipacion': diasAnticipacion,
        'avisoRelativo': avisoRelativo,
        'esRecurrente': esRecurrente,
        'tipoRecurrencia': tipoRecurrencia,
        'intervaloRecurrencia': intervaloRecurrencia,
        'fechaFinRecurrencia': fechaFinRecurrencia?.toIso8601String(),
        'fechaProximaRepeticion':
            fechaProximaRepeticion?.toIso8601String(),
        'recurrenciaActiva': recurrenciaActiva,
        'diasSemanaRecurrencia': diasSemanaRecurrencia,
      };

  /// Reconstruye el elemento desde los datos almacenados.
  ///
  /// Los campos nuevos tienen valores predeterminados para
  /// mantener la compatibilidad con notas y recordatorios antiguos.
  factory ElementoFlow.fromMap(Map<String, dynamic> map) {
    final diasGuardados = map['diasSemanaRecurrencia'];

    final diasSemana = diasGuardados is List
        ? diasGuardados
            .map((dia) => int.tryParse(dia.toString()))
            .whereType<int>()
            .where((dia) => dia >= 1 && dia <= 7)
            .toList()
        : <int>[];

    return ElementoFlow(
      id: (map['id'] as num?)?.toInt() ??
          DateTime.now().microsecondsSinceEpoch,
      texto: map['texto']?.toString() ?? '',
      perfil: map['perfil']?.toString() ?? 'Estudiante',
      tipo: map['tipo']?.toString() ?? 'Nota',
      fechaCreacion:
          DateTime.tryParse(map['fechaCreacion']?.toString() ?? '') ??
              DateTime.now(),
      fechaRecordatorio: DateTime.tryParse(
        map['fechaRecordatorio']?.toString() ?? '',
      ),
      fechaEvento: DateTime.tryParse(
        map['fechaEvento']?.toString() ?? '',
      ),
      diasAnticipacion:
          int.tryParse(map['diasAnticipacion']?.toString() ?? ''),
      avisoRelativo: map['avisoRelativo'] == true,
      esRecurrente: map['esRecurrente'] == true,
      tipoRecurrencia: map['tipoRecurrencia']?.toString(),
      intervaloRecurrencia:
          int.tryParse(map['intervaloRecurrencia']?.toString() ?? '') ?? 1,
      fechaFinRecurrencia: DateTime.tryParse(
        map['fechaFinRecurrencia']?.toString() ?? '',
      ),
      fechaProximaRepeticion: DateTime.tryParse(
        map['fechaProximaRepeticion']?.toString() ?? '',
      ),
      recurrenciaActiva: map['recurrenciaActiva'] != false,
      diasSemanaRecurrencia: diasSemana,
    );
  }

  /// Devuelve una copia modificando únicamente los campos indicados.
  ///
  /// El id, el perfil, el tipo y la fecha de creación no cambian.
  ///
  /// Los parámetros clear permiten eliminar fechas opcionales,
  /// ya que pasar null normalmente significa conservar su valor.
  ElementoFlow copyWith({
    String? texto,
    DateTime? fechaEvento,
    DateTime? fechaRecordatorio,
    int? diasAnticipacion,
    bool? avisoRelativo,
    bool? esRecurrente,
    String? tipoRecurrencia,
    int? intervaloRecurrencia,
    DateTime? fechaFinRecurrencia,
    DateTime? fechaProximaRepeticion,
    bool? recurrenciaActiva,
    List<int>? diasSemanaRecurrencia,
    bool limpiarFechaEvento = false,
    bool limpiarFechaRecordatorio = false,
    bool limpiarFechaFinRecurrencia = false,
    bool limpiarFechaProximaRepeticion = false,
    bool limpiarTipoRecurrencia = false,
  }) {
    final relativoFinal = avisoRelativo ?? this.avisoRelativo;

    return ElementoFlow(
      id: id,
      texto: texto ?? this.texto,
      perfil: perfil,
      tipo: tipo,
      fechaCreacion: fechaCreacion,
      fechaEvento: limpiarFechaEvento
          ? null
          : (fechaEvento ?? this.fechaEvento),
      fechaRecordatorio: limpiarFechaRecordatorio
          ? null
          : (fechaRecordatorio ?? this.fechaRecordatorio),
      diasAnticipacion: relativoFinal
          ? (diasAnticipacion ?? this.diasAnticipacion)
          : null,
      avisoRelativo: relativoFinal,
      esRecurrente: esRecurrente ?? this.esRecurrente,
      tipoRecurrencia: limpiarTipoRecurrencia
          ? null
          : (tipoRecurrencia ?? this.tipoRecurrencia),
      intervaloRecurrencia:
          intervaloRecurrencia ?? this.intervaloRecurrencia,
      fechaFinRecurrencia: limpiarFechaFinRecurrencia
          ? null
          : (fechaFinRecurrencia ?? this.fechaFinRecurrencia),
      fechaProximaRepeticion: limpiarFechaProximaRepeticion
          ? null
          : (fechaProximaRepeticion ?? this.fechaProximaRepeticion),
      recurrenciaActiva:
          recurrenciaActiva ?? this.recurrenciaActiva,
      diasSemanaRecurrencia: diasSemanaRecurrencia != null
          ? List<int>.from(diasSemanaRecurrencia)
          : List<int>.from(this.diasSemanaRecurrencia),
    );
  }
}
