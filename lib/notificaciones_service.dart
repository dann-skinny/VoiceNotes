import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificacionesService {
  NotificacionesService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _inicializado = false;

  static Future<void> inicializar() async {
    if (_inicializado) return;

    tz.initializeTimeZones();

    final zona = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(zona.identifier));

    const android = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const configuracion = InitializationSettings(
      android: android,
    );

    await _plugin.initialize(settings: configuracion);

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();

    _inicializado = true;
  }

  static Future<void> programar({
    required int id,
    required String titulo,
    required String mensaje,
    required DateTime fecha,
  }) async {
    await inicializar();

    if (!fecha.isAfter(DateTime.now())) return;

    const detallesAndroid = AndroidNotificationDetails(
      'lifeflow_recordatorios',
      'Recordatorios LifeFlow',
      channelDescription: 'Avisos de actividades y recordatorios',
      importance: Importance.max,
      priority: Priority.high,
    );

    const detalles = NotificationDetails(
      android: detallesAndroid,
    );

    await _plugin.zonedSchedule(
      id: _idNotificacion(id),
      title: titulo,
      body: mensaje,
      scheduledDate: tz.TZDateTime.from(fecha, tz.local),
      notificationDetails: detalles,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  static Future<void> cancelar(int id) async {
    await inicializar();
    await _plugin.cancel(
      id: _idNotificacion(id),
    );
  }

  static int _idNotificacion(int id) {
    return id % 2147483647;
  }
}