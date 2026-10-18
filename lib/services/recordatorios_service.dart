import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/elemento_flow.dart';
import 'notificaciones_service.dart';

/// Se encarga de avisar a tiempo: programa las notificaciones de Android y los temporizadores
/// que funcionan mientras la app está abierta.
class RecordatoriosService {
  /// Un temporizador por recordatorio, guardado por su id para poder cancelarlo.
  final Map<int, Timer> _temporizadores = {};

  /// Programa la notificación de Android para la fecha del recordatorio.
  Future<void> programarNotificacion(ElementoFlow item) async {
    // Las notas no llevan aviso.
    if (item.tipo != 'Recordatorio') return;

    final fecha = item.fechaRecordatorio;

    // Si no hay fecha, o ya pasó, no hay nada que programar.
    if (fecha == null || !fecha.isAfter(DateTime.now())) {
      return;
    }

    await NotificacionesService.programar(
      id: item.id,
      titulo: 'Recordatorio VoiceNotes',
      mensaje: item.texto,
      fecha: fecha,
    );
  }

  /// Cambia la notificación de un recordatorio: cancela la anterior y programa una nueva con
  /// los datos actuales.
  Future<void> actualizarNotificacion(ElementoFlow item) async {
    try {
      // Primero se quita la notificación vieja...
      await NotificacionesService.cancelar(item.id);

      // ...y luego se crea la nueva.
      await programarNotificacion(item);

      debugPrint(
        'NOTIFICACION: actualizada correctamente',
      );

    // Si algo falla solo se registra en consola; la app sigue funcionando.
    } catch (e, stackTrace) {
      debugPrint('ERROR AL ACTUALIZAR NOTIFICACION: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  /// Cancela la notificación de Android de un recordatorio.
  Future<void> cancelarNotificacion(int id) async {
    await NotificacionesService.cancelar(id);
  }

  /// Programa un temporizador que ejecuta [alDisparar] justo a la hora del recordatorio. Sirve
  /// mientras la app está abierta.
  void programarTemporizador(
    ElementoFlow item,
    void Function(ElementoFlow item) alDisparar,
  ) {
    final fecha = item.fechaRecordatorio;
    if (fecha == null) return;

    // Cuánto falta para la hora del aviso.
    final diferencia = fecha.difference(DateTime.now());

    // Si la hora ya pasó, no se programa nada.
    if (diferencia <= Duration.zero) return;

    // Si ya había un temporizador para este recordatorio, se reemplaza por el nuevo.
    _temporizadores[item.id]?.cancel();

    _temporizadores[item.id] = Timer(
      diferencia,
      () {
        _temporizadores.remove(item.id);
        alDisparar(item);
      },
    );
  }

  /// Cancela el temporizador de un recordatorio.
  void cancelarTemporizador(int id) {
    _temporizadores[id]?.cancel();
    _temporizadores.remove(id);
  }

  /// Cancela todos los temporizadores (se usa al cerrar la pantalla).
  void cancelarTodos() {
    for (final timer in _temporizadores.values) {
      timer.cancel();
    }
    _temporizadores.clear();
  }
}
