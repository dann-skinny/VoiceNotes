import 'package:flutter/material.dart';

import '../themes/colores_perfil.dart';

/// Tarjeta del dictado: muestra si el micrófono está activo, el texto que se va reconociendo y,
/// en los recordatorios, un botón para elegir la hora.
class AreaDictado extends StatelessWidget {
  /// Factor de tamaño de letras e íconos (más grande en modo asistido).
  final double escala;

  /// Colores del perfil activo.
  final ColoresPerfil colores;

  /// Si el micrófono está escuchando ahora.
  final bool estaEscuchando;

  /// Texto reconocido hasta el momento.
  final String textoDictado;

  /// 'Nota' o 'Recordatorio'. El selector de hora solo aparece en recordatorios.
  final String tipoActual;

  /// Hora elegida a mano (es null si la hora es automática).
  final DateTime? horaSeleccionada;

  /// Se llama al tocar el botón para elegir la hora.
  final VoidCallback alElegirHora;

  const AreaDictado({
    super.key,
    required this.escala,
    required this.colores,
    required this.estaEscuchando,
    required this.textoDictado,
    required this.tipoActual,
    required this.horaSeleccionada,
    required this.alElegirHora,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 8,
      ),
      padding: EdgeInsets.all(16 * escala),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado: ícono, "Asistente de voz" y su estado. El punto de la derecha es rojo
          // si está escuchando y verde si está disponible.
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colores.principal.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.graphic_eq_rounded,
                  color: colores.principal,
                  size: 23 * escala,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Asistente de voz',
                      style: TextStyle(
                        fontSize: 15 * escala,
                        fontWeight: FontWeight.w700,
                        color: colores.texto,
                      ),
                    ),
                    Text(
                      estaEscuchando
                          ? 'Escuchando tu voz...'
                          : 'Listo para escucharte',
                      style: TextStyle(
                        fontSize: 11 * escala,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.circle,
                size: 9,
                color: estaEscuchando
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF22A06B),
              ),
              const SizedBox(width: 5),
              Text(
                estaEscuchando ? 'Activo' : 'Disponible',
                style: TextStyle(
                  fontSize: 10 * escala,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Caja con el texto reconocido. Mientras no haya texto, muestra un mensaje de ayuda.
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 72),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colores.fondo,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              estaEscuchando
                  ? (textoDictado.isEmpty
                      ? 'Escuchando... Puedes comenzar a hablar.'
                      : textoDictado)
                  : (textoDictado.isNotEmpty
                      ? textoDictado
                      : 'Presiona el micrófono para dictar tu ${tipoActual.toLowerCase()}...'),
              style: TextStyle(
                fontSize: 13 * escala,
                color: textoDictado.isNotEmpty
                    ? colores.texto
                    : Colors.grey.shade600,
                height: 1.5,
              ),
            ),
          ),

          // Botón para elegir la hora a mano (solo en recordatorios).
          if (tipoActual == 'Recordatorio') ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: alElegirHora,
                icon: Icon(
                  Icons.access_time_rounded,
                  color: colores.principal,
                ),
                label: Text(
                  horaSeleccionada == null
                      ? 'Hora automática o seleccionar'
                      : 'Hora: ${horaSeleccionada!.hour.toString().padLeft(2, '0')}:${horaSeleccionada!.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 12 * escala,
                    color: colores.principal,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 13,
                    horizontal: 12,
                  ),
                  side: BorderSide(
                    color: colores.principal.withValues(alpha: 0.20),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
