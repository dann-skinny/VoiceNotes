import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Maneja las notificaciones de Android: las prepara al abrir la app, programa un aviso para
/// una fecha y hora exactas y lo cancela cuando hace falta. Se usa sin crear objetos: todos sus
/// métodos son estáticos.
class NotificacionesService {
  /// Constructor privado: evita que se creen objetos de esta clase.
  NotificacionesService._();

  /// Plugin que se comunica con las notificaciones del sistema Android.
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Evita preparar las notificaciones más de una vez.
  static bool _inicializado = false;

  /// Prepara las notificaciones: zona horaria, ícono y permisos. Se puede llamar varias veces;
  /// solo se ejecuta la primera.
  static Future<void> inicializar() async {
    // Si ya se preparó antes, no se repite.
    if (_inicializado) return;

    // Se cargan las zonas horarias para que los avisos suenen a la hora local correcta.
    tz.initializeTimeZones();

    // Se detecta la zona horaria del celular y se usa como la zona de los avisos.
    final zona = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(zona.identifier));

    // Ícono que aparece en la notificación (el mismo ícono de la app).
    const android = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const configuracion = InitializationSettings(
      android: android,
    );

    // Se inicia el plugin con esa configuración.
    await _plugin.initialize(settings: configuracion);

    // Funciones propias de Android, necesarias para pedir los permisos.
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    // Permiso para mostrar notificaciones.
    await androidPlugin?.requestNotificationsPermission();

    // Permiso para alarmas exactas: así el aviso suena justo a la hora y no unos minutos
    // después.
    await androidPlugin?.requestExactAlarmsPermission();

    _inicializado = true;
  }

  /// Programa una notificación para [fecha]. [id] identifica el recordatorio; [titulo] y
  /// [mensaje] son lo que se ve en la notificación. Si la fecha ya pasó, no hace nada.
  static Future<void> programar({
    required int id,
    required String titulo,
    required String mensaje,
    required DateTime fecha,
  }) async {
    // Por si todavía no se habían preparado las notificaciones.
    await inicializar();

    // No se programan avisos en el pasado.
    if (!fecha.isAfter(DateTime.now())) return;

    // Cómo se ve y suena la notificación en Android. El canal "Recordatorios LifeFlow" aparece
    // con ese nombre en los ajustes del celular. Con importancia máxima sale como aviso
    // emergente y con sonido.
    const detallesAndroid = AndroidNotificationDetails(
      'lifeflow_recordatorios',
      'Recordatorios VoiceNotes',
      channelDescription: 'Avisos de actividades y recordatorios',
      importance: Importance.max,
      priority: Priority.high,
    );

    const detalles = NotificationDetails(
      android: detallesAndroid,
    );

    // Se deja el aviso programado en Android para esa fecha y hora. "exactAllowWhileIdle" hace
    // que suene a tiempo aunque el celular esté en reposo.
    await _plugin.zonedSchedule(
      id: _idNotificacion(id),
      title: titulo,
      body: mensaje,
      scheduledDate: tz.TZDateTime.from(fecha, tz.local),
      notificationDetails: detalles,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  /// Cancela la notificación programada de un recordatorio (por ejemplo, cuando se borra o se
  /// cambia).
  static Future<void> cancelar(int id) async {
    // Por si todavía no se habían preparado las notificaciones.
    await inicializar();
    await _plugin.cancel(
      id: _idNotificacion(id),
    );
  }

  /// Android solo acepta ids de hasta 32 bits. Los ids de LifeFlow pueden ser más grandes (se
  /// basan en la hora actual), así que se reducen con el resto de una división.
  static int _idNotificacion(int id) {
    return id % 2147483647;
  }
}
