import 'package:flutter/material.dart';

import '../themes/colores_perfil.dart';

/// Mensaje que se muestra cuando todavía no hay notas o recordatorios para el perfil y la
/// pestaña actuales.
class EstadoVacio extends StatelessWidget {
  /// 'Nota' o 'Recordatorio'; decide los textos y el ícono.
  final String tipoActual;

  /// Factor de tamaño de letras e íconos (más grande en modo asistido).
  final double escala;

  /// Colores del perfil activo.
  final ColoresPerfil colores;

  const EstadoVacio({
    super.key,
    required this.tipoActual,
    required this.escala,
    required this.colores,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 8,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 32 * escala,
      ),
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
        children: [
          // Ícono grande y redondo.
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: colores.principal.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              tipoActual == 'Nota'
                  ? Icons.edit_note_rounded
                  : Icons.notifications_none_rounded,
              color: colores.principal,
              size: 36 * escala,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            tipoActual == 'Nota'
                ? 'Aún no tienes notas'
                : 'Aún no tienes recordatorios',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16 * escala,
              fontWeight: FontWeight.w700,
              color: colores.texto,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tipoActual == 'Nota'
                ? 'Tus ideas y apuntes aparecerán aquí.'
                : 'Tus próximos avisos aparecerán aquí.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12 * escala,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          // Invitación a usar el micrófono para empezar.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.mic_none_rounded,
                color: colores.principal,
                size: 18 * escala,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  'Usa el micrófono para comenzar',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12 * escala,
                    fontWeight: FontWeight.w600,
                    color: colores.principal,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
