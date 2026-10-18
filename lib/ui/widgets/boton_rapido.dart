import 'package:flutter/material.dart';

import '../themes/colores_perfil.dart';

/// Botón rápido genérico: ícono, título y descripción.
/// - Normal: tarjeta vertical (ícono arriba, texto abajo).
/// - horizontal: ícono a la izquierda, texto en medio y una flechita a la derecha.
/// - emergencia: usa los colores rojos de alerta.
class BotonRapido extends StatelessWidget {
  /// Ícono del botón.
  final IconData icono;

  /// Texto principal.
  final String titulo;

  /// Texto pequeño que explica qué hace.
  final String descripcion;

  /// Se llama al tocar el botón.
  final VoidCallback accion;

  /// Factor de tamaño de letras e íconos (más grande en modo asistido).
  final double escala;

  /// Colores del perfil activo.
  final ColoresPerfil colores;

  /// Si es true se dibuja en fila (ícono, texto y flechita); si es false, como tarjeta
  /// vertical.
  final bool horizontal;

  /// Si es true usa los colores rojos de alerta.
  final bool emergencia;

  /// Ícono de la derecha (solo se usa en la versión horizontal).
  final IconData iconoFinal;

  const BotonRapido({
    super.key,
    required this.icono,
    required this.titulo,
    required this.descripcion,
    required this.accion,
    required this.escala,
    required this.colores,
    this.horizontal = false,
    this.emergencia = false,
    this.iconoFinal = Icons.chevron_right_rounded,
  });

  @override
  Widget build(BuildContext context) {
    // Colores: rojos en emergencia y los del perfil en los demás casos.
    final colorIcono = emergencia
        ? const Color(0xFFB91C1C)
        : colores.principal;

    final fondoIcono = emergencia
        ? const Color(0xFFFFE0E3)
        : colores.principal.withValues(alpha: 0.10);

    final colorTitulo = emergencia
        ? const Color(0xFFB91C1C)
        : colores.texto;

    final colorDescripcion = emergencia
        ? const Color(0xFFB45353)
        : Colors.grey.shade600;

    // Caja tocable con bordes redondeados.
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: emergencia
            ? const Color(0xFFFFF1F2)
            : Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: accion,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: EdgeInsets.all(14 * escala),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: emergencia
                    ? const Color(0xFFFAD4D8)
                    : colores.principal.withValues(alpha: 0.10),
              ),
            ),
            // Versión horizontal (una fila) o versión vertical (una tarjeta).
            child: horizontal
                ? Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          color: fondoIcono,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          icono,
                          color: colorIcono,
                          size: 23 * escala,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              titulo,
                              style: TextStyle(
                                fontSize: 13 * escala,
                                fontWeight: FontWeight.w700,
                                color: colorTitulo,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              descripcion,
                              style: TextStyle(
                                fontSize: 10 * escala,
                                color: colorDescripcion,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        iconoFinal,
                        color: colorIcono,
                        size: 22,
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: fondoIcono,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          icono,
                          color: colorIcono,
                          size: 25 * escala,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        titulo,
                        style: TextStyle(
                          fontSize: 12 * escala,
                          fontWeight: FontWeight.w700,
                          color: colorTitulo,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        descripcion,
                        style: TextStyle(
                          fontSize: 10 * escala,
                          color: colorDescripcion,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
