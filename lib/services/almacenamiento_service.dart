import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/elemento_flow.dart';

/// Lo que se lee de la memoria del celular al abrir la app.
class DatosGuardados {
  /// Todas las notas y recordatorios guardados.
  final List<ElementoFlow> elementos;

  /// Número del contacto de emergencia (vacío si no hay ninguno).
  final String numeroEmergencia;

  const DatosGuardados({
    required this.elementos,
    required this.numeroEmergencia,
  });
}

/// Guarda y lee los datos en la memoria del celular (SharedPreferences). Aquí no hay nada de
/// pantallas ni de lógica: solo leer y escribir.
class AlmacenamientoService {
  /// Nombres con los que se guardan los datos en la memoria.
  static const String _claveElementos = 'lifeflow_items';
  static const String _claveNumeroEmergencia = 'lifeflow_numero_emergencia';

  /// Lee todo lo guardado. Si no se puede leer, lanza un error que maneja el controlador.
  Future<DatosGuardados> cargar() async {
    final prefs = await SharedPreferences.getInstance();
    final datos = prefs.getString(_claveElementos);
    final numero = prefs.getString(_claveNumeroEmergencia) ?? '';

    // Aquí se van juntando los elementos leídos.
    final List<ElementoFlow> cargados = [];

    if (datos != null && datos.isNotEmpty) {
      // Los elementos se guardan como texto JSON; aquí se convierten de nuevo en una lista.
      final decoded = jsonDecode(datos);

      if (decoded is List) {
        for (final item in decoded) {
          // Si un registro está dañado se ignora, para que no impida cargar los demás.
          try {
            cargados.add(
              ElementoFlow.fromMap(
                Map<String, dynamic>.from(item as Map),
              ),
            );
          } catch (e) {
            debugPrint('Registro no válido: $e');
          }
        }
      }
    }

    return DatosGuardados(elementos: cargados, numeroEmergencia: numero);
  }

  /// Guarda la lista completa de elementos. Devuelve false si el sistema no pudo guardar.
  Future<bool> guardarElementos(List<ElementoFlow> elementos) async {
    final prefs = await SharedPreferences.getInstance();

    // Cada elemento se convierte a mapa y toda la lista se guarda como texto JSON.
    final datos = jsonEncode(elementos.map((e) => e.toMap()).toList());
    return prefs.setString(_claveElementos, datos);
  }

  /// Guarda el número de emergencia. Devuelve false si el sistema no pudo guardar.
  Future<bool> guardarNumeroEmergencia(String numero) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(_claveNumeroEmergencia, numero);
  }
}
