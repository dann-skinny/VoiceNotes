import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Programa y cancela notificaciones de Android para LifeFlow.
///
/// Las recurrencias se programan por lotes de fechas futuras. Android conserva
/// ese lote aunque se cierre la aplicacion. El lote debe renovarse al abrir
/// la app y antes de agotarse; este servicio no implementa un proceso de fondo.
class NotificacionesService {
  NotificacionesService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _inicializado = false;

  static const _canalId = 'lifeflow_recordatorios';
  static const _canalNombre = 'Recordatorios LifeFlow';
  static const _maximoPorSerie = 32;

  static const _detalles = NotificationDetails(
    android: AndroidNotificationDetails(
      _canalId,
      _canalNombre,
      channelDescription: 'Avisos de actividades y recordatorios',
      importance: Importance.max,
      priority: Priority.high,
    ),
  );

  static Future<void> inicializar() async {
    if (_inicializado) return;
    tz.initializeTimeZones();
    final zona = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(zona.identifier));

    const configuracion = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _plugin.initialize(settings: configuracion);

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();
    _inicializado = true;
  }

  /// Compatibilidad con los recordatorios normales existentes.
  static Future<void> programar({
    required int id,
    required String titulo,
    required String mensaje,
    required DateTime fecha,
  }) async {
    await inicializar();
    if (!fecha.isAfter(DateTime.now())) return;
    await _programarConId(
      idNotificacion: _idNotificacion(id),
      titulo: titulo,
      mensaje: mensaje,
      fecha: fecha,
      payload: _payload(id),
    );
  }

  /// Programa varias ocurrencias futuras del mismo recordatorio.
  ///
  /// [fechas] debe ser calculada por RecordatoriosService. Solo se guardan
  /// hasta 32 ocurrencias futuras por llamada para no saturar Android.
  /// Antes de reprogramar una serie, se cancelan sus avisos pendientes.
  static Future<void> programarSerie({
    required int id,
    required String titulo,
    required String mensaje,
    required List<DateTime> fechas,
  }) async {
    await inicializar();
    await cancelar(id);

    final ahora = DateTime.now();
    final ordenadas = fechas.where((f) => f.isAfter(ahora)).toList()..sort();
    final unicas = <DateTime>[];
    for (final fecha in ordenadas) {
      if (unicas.isEmpty || fecha != unicas.last) unicas.add(fecha);
      if (unicas.length == _maximoPorSerie) break;
    }

    // Evita reutilizar IDs de notificaciones ajenas que ya esten pendientes.
    final pendientes = await _plugin.pendingNotificationRequests();
    final ocupados = pendientes.map((n) => n.id).toSet();
    final propios = _payload(id);

    final programados = <int>[];
    try {
      for (var i = 0; i < unicas.length; i++) {
        var idAviso = _idSerie(id, i);
        var intentos = 0;
        while (ocupados.contains(idAviso) && intentos < 2147483646) {
          idAviso = (idAviso + 1) % 2147483647;
          intentos++;
        }
        if (ocupados.contains(idAviso)) {
          throw StateError('No se encontro un identificador de notificacion libre');
        }
        await _programarConId(
          idNotificacion: idAviso,
          titulo: titulo,
          mensaje: mensaje,
          fecha: unicas[i],
          payload: propios,
        );
        ocupados.add(idAviso);
        programados.add(idAviso);
      }
    } catch (e) {
      // Si falla una ocurrencia, no dejar una serie parcialmente programada.
      for (final idAviso in programados) {
        try {
          await _plugin.cancel(id: idAviso);
        } catch (cancelError) {
          debugPrint('No se pudo revertir el aviso $idAviso: $cancelError');
        }
      }
      debugPrint('No se pudo completar la serie $id: $e');
      rethrow;
    }
  }

  /// Cancela el aviso normal y todas las ocurrencias pendientes de la serie.
  static Future<void> cancelar(int id) async {
    await inicializar();
    await _plugin.cancel(id: _idNotificacion(id));

    final pendientes = await _plugin.pendingNotificationRequests();
    final identificador = _payload(id);
    for (final aviso in pendientes) {
      if (aviso.payload == identificador) {
        await _plugin.cancel(id: aviso.id);
      }
    }
  }

  static Future<void> _programarConId({
    required int idNotificacion,
    required String titulo,
    required String mensaje,
    required DateTime fecha,
    required String payload,
  }) async {
    try {
      await _plugin.zonedSchedule(
        id: idNotificacion,
        title: titulo,
        body: mensaje,
        scheduledDate: tz.TZDateTime.from(fecha, tz.local),
        notificationDetails: _detalles,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
    } catch (error) {
      debugPrint('No se pudo programar el aviso $idNotificacion: $error');
      rethrow;
    }
  }

  static String _payload(int id) => 'voicenotes_recordatorio:$id';

  static int _idNotificacion(int id) => id % 2147483647;

  /// Mezcla id de recordatorio y posicion para distribuir los IDs en 31 bits.
  /// Las colisiones con avisos pendientes se resuelven en programarSerie.
  static int _idSerie(int id, int posicion) {
    var valor = (id ^ (posicion * 0x9e3779b9)) & 0x7fffffff;
    valor ^= valor >> 16;
    valor = (valor * 0x45d9f3b) & 0x7fffffff;
    valor ^= valor >> 16;
    return valor;
  }
}
