/// Una nota o un recordatorio guardado en LifeFlow. No se modifica directamente: para cambiarlo
/// se crea una copia con [copyWith].
class ElementoFlow {
  /// Identificador único (también lo usan la notificación y el temporizador).
  final int id;

  /// Lo que dijo la persona.
  final String texto;

  /// Perfil al que pertenece: 'Estudiante' o 'Adulto Mayor'.
  final String perfil;

  /// 'Nota' o 'Recordatorio'.
  final String tipo;

  /// Cuándo se creó.
  final DateTime fechaCreacion;

  /// Fecha y hora exacta en que debe sonar el aviso (solo recordatorios).
  final DateTime? fechaRecordatorio;

  /// Fecha del evento al que se refiere el recordatorio (por ejemplo, una cita).
  final DateTime? fechaEvento;

  /// Si el aviso es relativo, cuántos días antes del evento debe sonar.
  final int? diasAnticipacion;

  /// Es true cuando el aviso se calculó como "X días antes" del evento.
  final bool avisoRelativo;

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
  });

  /// Convierte el elemento a un mapa simple para guardarlo en la memoria del celular.
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
      };

  /// Reconstruye un elemento a partir de lo guardado. Si falta algún dato, usa un valor por
  /// defecto para que la app no falle.
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
      fechaEvento: DateTime.tryParse(
        map['fechaEvento']?.toString() ?? '',
      ),
      diasAnticipacion:
          (map['diasAnticipacion'] as num?)?.toInt(),
      avisoRelativo: map['avisoRelativo'] == true,
    );
  }

  /// Devuelve una copia cambiando solo los datos indicados. El id, el perfil y el tipo nunca
  /// cambian.
  ElementoFlow copyWith({
    String? texto,
    DateTime? fechaEvento,
    DateTime? fechaRecordatorio,
    int? diasAnticipacion,
    bool? avisoRelativo,
  }) {
    // Si el aviso deja de ser relativo, también se descarta la anticipación.
    final relativoFinal = avisoRelativo ?? this.avisoRelativo;

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
