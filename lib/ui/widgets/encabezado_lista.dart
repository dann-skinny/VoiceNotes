import 'package:flutter/material.dart';

import '../themes/colores_perfil.dart';

/// Encabezado de la lista: título ("Mis notas" o "Mis recordatorios") y cuántos elementos hay
/// guardados.
class EncabezadoLista extends StatelessWidget {
  /// 'Nota' o 'Recordatorio'; decide el título.
  final String tipoActual;

  /// Cuántos elementos se están mostrando.
  final int cantidad;

  /// Factor de tamaño de letras (más grande en modo asistido).
  final double escala;

  /// Colores del perfil activo.
  final ColoresPerfil colores;

  const EncabezadoLista({
    super.key,
    required this.tipoActual,
    required this.cantidad,
    required this.escala,
    required this.colores,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tipoActual == 'Nota'
                      ? 'Mis notas'
                      : 'Mis recordatorios',
                  style: TextStyle(
                    fontSize: 18 * escala,
                    fontWeight: FontWeight.w800,
                    color: colores.texto,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Organiza tus actividades',
                  style: TextStyle(
                    fontSize: 11 * escala,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          // Etiqueta con la cantidad de elementos guardados.
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: colores.principal.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$cantidad guardados',
              style: TextStyle(
                fontSize: 11 * escala,
                fontWeight: FontWeight.w700,
                color: colores.principal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
