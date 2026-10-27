import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/elemento_flow.dart';
import 'notificaciones_service.dart';

/// Calcula los avisos y administra los temporizadores de LifeFlow.
class RecordatoriosService {
  final Map<int, Timer> _temporizadores = {};

  /// Devuelve el siguiente aviso estrictamente posterior a [desde].
  DateTime? proximoAviso(ElementoFlow item, {DateTime? desde}) {
    if (item.tipo != 'Recordatorio') return null;
    final ahora = desde ?? DateTime.now();
    if (!item.esRecurrente) {
      final fecha = item.fechaRecordatorio;
      return fecha != null && fecha.isAfter(ahora) ? fecha : null;
    }
    if (!item.recurrenciaActiva) return null;

    final inicio = item.fechaRecordatorio;
    if (inicio == null) return null;
    final fin = item.fechaFinRecurrencia;
    if (fin != null && inicio.isAfter(fin)) return null;

    final tipo = item.tipoRecurrencia;
    final intervalo = item.intervaloRecurrencia;
    if (intervalo <= 0) return null;

    DateTime? candidato;
    if (inicio.isAfter(ahora)) {
      candidato = inicio;
    } else if (tipo == 'minutos' || tipo == 'horas') {
      final paso = tipo == 'minutos'
          ? Duration(minutes: intervalo)
          : Duration(hours: intervalo);
      final ms = paso.inMilliseconds;
      final saltos = ahora.difference(inicio).inMilliseconds ~/ ms + 1;
      candidato = inicio.add(Duration(milliseconds: saltos * ms));
    } else if (tipo == 'dias') {
      final dias = _diasCalendario(inicio, ahora);
      final saltos = dias ~/ intervalo;
      candidato = _sumarDias(inicio, saltos * intervalo);
      if (!candidato.isAfter(ahora)) {
        candidato = _sumarDias(candidato, intervalo);
      }
    } else if (tipo == 'semanas') {
      final dias = _diasCalendario(inicio, ahora);
      final paso = 7 * intervalo;
      final saltos = dias ~/ paso;
      candidato = _sumarDias(inicio, saltos * paso);
      if (!candidato.isAfter(ahora)) {
        candidato = _sumarDias(candidato, paso);
      }
    } else if (tipo == 'meses' || tipo == 'anios') {
      final mesesPaso = tipo == 'meses' ? intervalo : 12 * intervalo;
      final mesesTranscurridos =
          (ahora.year - inicio.year) * 12 + ahora.month - inicio.month;
      var saltos = mesesTranscurridos <= 0 ? 0 : mesesTranscurridos ~/ mesesPaso;
      var fechaMensual = _sumarMesesAnclado(inicio, saltos * mesesPaso);
      while (!fechaMensual.isAfter(ahora)) {
        saltos++;
        fechaMensual = _sumarMesesAnclado(inicio, saltos * mesesPaso);
      }
      candidato = fechaMensual;
    } else if (tipo == 'dias_semana') {
      final dias = item.diasSemanaRecurrencia.toSet();
      if (dias.isEmpty) return null;
      final base = DateTime(ahora.year, ahora.month, ahora.day);
      for (var i = 0; i <= 7; i++) {
        final dia = DateTime(base.year, base.month, base.day + i,
            inicio.hour, inicio.minute, inicio.second);
        if (dias.contains(dia.weekday) &&
            !dia.isBefore(inicio) && dia.isAfter(ahora)) {
          candidato = dia;
          break;
        }
      }
    } else {
      return null;
    }

    if (candidato == null || (fin != null && candidato.isAfter(fin))) {
      return null;
    }
    return candidato;
  }

  int _diasCalendario(DateTime a, DateTime b) {
    final aa = DateTime.utc(a.year, a.month, a.day);
    final bb = DateTime.utc(b.year, b.month, b.day);
    return bb.difference(aa).inDays;
  }

  DateTime _sumarDias(DateTime fecha, int dias) => DateTime(
        fecha.year, fecha.month, fecha.day + dias,
        fecha.hour, fecha.minute, fecha.second, fecha.millisecond,
      );

  DateTime _sumarMesesAnclado(DateTime fecha, int meses) {
    final primerDia = DateTime(fecha.year, fecha.month + meses, 1);
    final ultimoDia = DateTime(primerDia.year, primerDia.month + 1, 0).day;
    final dia = fecha.day <= ultimoDia ? fecha.day : ultimoDia;
    return DateTime(primerDia.year, primerDia.month, dia,
        fecha.hour, fecha.minute, fecha.second, fecha.millisecond);
  }

  Future<void> programarNotificacion(ElementoFlow item) async {
    final fecha = proximoAviso(item);
    if (fecha == null) return;
    await NotificacionesService.programar(
      id: item.id,
      titulo: 'Recordatorio LifeFlow',
      mensaje: item.texto,
      fecha: fecha,
    );
  }

  Future<void> actualizarNotificacion(ElementoFlow item) async {
    try {
      await NotificacionesService.cancelar(item.id);
      await programarNotificacion(item);
      debugPrint('NOTIFICACION: actualizada correctamente');
    } catch (e, stackTrace) {
      debugPrint('ERROR AL ACTUALIZAR NOTIFICACION: $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> cancelarNotificacion(int id) async {
    cancelarTemporizador(id);
    await NotificacionesService.cancelar(id);
  }

  void programarTemporizador(
    ElementoFlow item,
    void Function(ElementoFlow item) alDisparar,
  ) {
    cancelarTemporizador(item.id);
    final fecha = proximoAviso(item);
    if (fecha == null) return;
    final diferencia = fecha.difference(DateTime.now());
    if (diferencia <= Duration.zero) return;

    _temporizadores[item.id] = Timer(diferencia, () {
      _temporizadores.remove(item.id);
      alDisparar(item);
      if (item.esRecurrente && item.recurrenciaActiva) {
        programarTemporizador(item, alDisparar);
      }
    });
  }

  void cancelarTemporizador(int id) {
    _temporizadores[id]?.cancel();
    _temporizadores.remove(id);
  }

  void cancelarTodos() {
    for (final timer in _temporizadores.values) {
      timer.cancel();
    }
    _temporizadores.clear();
  }
}
