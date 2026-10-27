import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Dictado activado por el usuario, con recuperación limitada de sesiones.
class VozService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _inicializado = false;
  bool _escuchaSolicitada = false;
  bool _reiniciando = false;
  bool _liberado = false;
  bool _errorPermanente = false;
  int _reiniciosConsecutivos = 0;
  int _generacion = 0;
  static const int _maxReiniciosConsecutivos = 3;

  String _textoConfirmado = '';
  String _textoSesion = '';
  bool _sesionConfirmada = false;

  void Function(String)? _alRecibirTexto;
  void Function(String)? _alCambiarEstado;
  void Function(String)? _alOcurrirError;

  bool get estaEscuchando => _speech.isListening;

  Future<void> configurar() async {
    await _tts.setLanguage('es-MX');
    await _tts.setVolume(1);
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1);
  }

  Future<void> hablar(String mensaje) async {
    try {
      await _tts.stop();
      await _tts.speak(mensaje);
    } catch (e) {
      debugPrint('Error de voz: $e');
    }
  }

  Future<void> detenerHabla() => _tts.stop();

  Future<bool> inicializarEscucha({
    required void Function(String estado) alCambiarEstado,
    required void Function(String error) alOcurrirError,
  }) async {
    _alCambiarEstado = alCambiarEstado;
    _alOcurrirError = alOcurrirError;
    _liberado = false;
    if (_inicializado) return true;

    try {
      _inicializado = await _speech.initialize(
        onStatus: _manejarEstado,
        onError: (error) {
          debugPrint('Error de reconocimiento: $error');
          if (_liberado || !_escuchaSolicitada) return;
          if (error.permanent) {
            _errorPermanente = true;
            _escuchaSolicitada = false;
            _generacion++;
            _confirmarSesion();
            _alOcurrirError?.call(error.toString());
          } else {
            // El estado done/notListening puede permitir una recuperación.
            debugPrint('Error temporal de reconocimiento: $error');
          }
        },
      );
      return _inicializado;
    } catch (e) {
      _alOcurrirError?.call(e.toString());
      return false;
    }
  }

  void _emitirTexto() {
    final partes = [_textoConfirmado.trim(), _textoSesion.trim()]
        .where((parte) => parte.isNotEmpty);
    _alRecibirTexto?.call(partes.join(' '));
  }

  void _confirmarSesion() {
    if (_sesionConfirmada || _textoSesion.trim().isEmpty) return;
    _textoConfirmado = [
      _textoConfirmado.trim(),
      _textoSesion.trim(),
    ].where((parte) => parte.isNotEmpty).join(' ');
    _textoSesion = '';
    _sesionConfirmada = true;
    _emitirTexto();
  }

  void _manejarEstado(String estado) {
    _alCambiarEstado?.call(estado);
    if (_liberado || !_escuchaSolicitada || _errorPermanente) return;
    if (estado == 'done' || estado == 'notListening') {
      _confirmarSesion();
      _intentarReiniciar();
    }
  }

  Future<void> _intentarReiniciar() async {
    if (_reiniciando || !_escuchaSolicitada || _liberado || _errorPermanente) {
      return;
    }
    if (_reiniciosConsecutivos >= _maxReiniciosConsecutivos) {
      _escuchaSolicitada = false;
      _generacion++;
      _alOcurrirError?.call(
        'No se pudo mantener la escucha. Detén y vuelve a iniciar el dictado.',
      );
      return;
    }

    _reiniciando = true;
    final generacion = _generacion;
    try {
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (!_escuchaSolicitada || _liberado || _errorPermanente ||
          generacion != _generacion) return;
      if (!_speech.isListening) {
        _reiniciosConsecutivos++;
        await _iniciarSesion();
      }
    } catch (e) {
      if (generacion == _generacion && _escuchaSolicitada) {
        _escuchaSolicitada = false;
        _generacion++;
        _alOcurrirError?.call(e.toString());
      }
    } finally {
      _reiniciando = false;
    }
  }

  Future<void> _iniciarSesion() async {
    _textoSesion = '';
    _sesionConfirmada = false;
    await _speech.listen(
      localeId: 'es_MX',
      listenFor: const Duration(minutes: 5),
      pauseFor: const Duration(seconds: 10),
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        cancelOnError: false,
        listenMode: stt.ListenMode.dictation,
      ),
      onResult: (resultado) {
        if (_liberado || !_escuchaSolicitada ||
            _errorPermanente || _sesionConfirmada) return;
        _textoSesion = resultado.recognizedWords;
        if (_textoSesion.trim().isNotEmpty) _reiniciosConsecutivos = 0;
        _emitirTexto();
        if (resultado.finalResult) _confirmarSesion();
      },
    );
  }

  Future<void> escuchar({
    required void Function(String palabras) alRecibirTexto,
  }) async {
    if (!_inicializado || _liberado) {
      throw StateError('El reconocimiento no está inicializado.');
    }
    _alRecibirTexto = alRecibirTexto;
    _textoConfirmado = '';
    _textoSesion = '';
    _sesionConfirmada = false;
    _reiniciosConsecutivos = 0;
    _errorPermanente = false;
    _generacion++;
    _escuchaSolicitada = true;
    if (_speech.isListening) return;
    try {
      await _iniciarSesion();
    } catch (_) {
      _escuchaSolicitada = false;
      _generacion++;
      rethrow;
    }
  }

  Future<void> detenerEscucha() async {
    _escuchaSolicitada = false;
    _generacion++;
    if (_speech.isListening) await _speech.stop();
    _confirmarSesion();
  }

  void liberar() {
    _liberado = true;
    _escuchaSolicitada = false;
    _generacion++;
    unawaited(_speech.cancel());
    unawaited(_tts.stop());
  }
}
