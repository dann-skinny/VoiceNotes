import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Todo lo relacionado con la voz: hablar (texto a voz) y escuchar (dictado).
class VozService {
  /// Reconoce lo que la persona dice por el micrófono.
  final stt.SpeechToText _speech = stt.SpeechToText();

  /// Lee textos en voz alta.
  final FlutterTts _tts = FlutterTts();

  /// Indica si el micrófono está escuchando en este momento.
  bool get estaEscuchando => _speech.isListening;

  /// Configura la voz del celular: español de México, volumen máximo, velocidad media y tono
  /// normal.
  Future<void> configurar() async {
    await _tts.setLanguage('es-MX');
    await _tts.setVolume(1);
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1);
  }

  /// Lee [mensaje] en voz alta. Si ya estaba hablando, corta lo anterior primero.
  Future<void> hablar(String mensaje) async {
    try {
      await _tts.stop();
      await _tts.speak(mensaje);
    } catch (e) {
      debugPrint('Error de voz: $e');
    }
  }

  /// Calla la voz inmediatamente.
  Future<void> detenerHabla() async {
    await _tts.stop();
  }

  /// Prepara el micrófono. Devuelve false si no está disponible. [alCambiarEstado] avisa cuando
  /// el micrófono empieza o deja de escuchar; [alOcurrirError] avisa si el reconocimiento
  /// falla.
  Future<bool> inicializarEscucha({
    required void Function(String estado) alCambiarEstado,
    required void Function(String error) alOcurrirError,
  }) async {
    return _speech.initialize(
      onStatus: alCambiarEstado,
      onError: (error) => alOcurrirError(error.toString()),
    );
  }

  /// Empieza a escuchar y va entregando el texto reconocido en [alRecibirTexto].
  Future<void> escuchar({
    required void Function(String palabras) alRecibirTexto,
  }) async {
    await _speech.listen(
      localeId: 'es_MX',
      onResult: (resultado) => alRecibirTexto(resultado.recognizedWords),
    );
  }

  /// Deja de escuchar (si estaba escuchando).
  Future<void> detenerEscucha() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
  }

  /// Apaga micrófono y voz al salir de la pantalla.
  void liberar() {
    _speech.cancel();
    _tts.stop();
  }
}
