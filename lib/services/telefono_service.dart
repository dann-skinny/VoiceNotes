import 'package:flutter/services.dart';

/// Hace llamadas telefónicas usando un canal nativo de Android.
class TelefonoService {
  /// Nombre del canal: debe ser igual al que está en el código nativo de Android.
  static const MethodChannel _canal = MethodChannel('lifeflow/telefono');

  /// Marca el número indicado. Puede lanzar PlatformException (la llamada falló) o
  /// MissingPluginException (falta configurar Android).
  Future<void> llamar(String numero) async {
    await _canal.invokeMethod<void>('llamar', {'numero': numero});
  }
}
