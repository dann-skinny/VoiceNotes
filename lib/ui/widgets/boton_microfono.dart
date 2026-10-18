import 'package:flutter/material.dart';

import '../themes/colores_perfil.dart';

/// Botón del micrófono, fijo en la parte inferior de la pantalla. Mientras escucha se pone rojo
/// y muestra el ícono de detener.
class BotonMicrofono extends StatelessWidget {
  /// Si el micrófono está escuchando ahora.
  final bool estaEscuchando;

  /// Si está bloqueado (por ejemplo, mientras se cargan los datos o se termina un dictado).
  final bool deshabilitado;

  /// Colores del perfil activo.
  final ColoresPerfil colores;

  /// Se llama al tocarlo: empieza o termina el dictado.
  final VoidCallback alPresionar;

  const BotonMicrofono({
    super.key,
    required this.estaEscuchando,
    required this.deshabilitado,
    required this.colores,
    required this.alPresionar,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Botón circular con un halo suave alrededor.
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: estaEscuchando
                ? const Color(0xFFFEE2E2)
                : colores.principal.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Material(
            color: estaEscuchando
                ? const Color(0xFFEF4444)
                : colores.principal,
            shape: const CircleBorder(),
            elevation: 6,
            shadowColor: colores.principal.withValues(alpha: 0.25),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: deshabilitado ? null : alPresionar,
              child: SizedBox(
                width: 62,
                height: 62,
                child: Icon(
                  estaEscuchando
                      ? Icons.stop_rounded
                      : Icons.mic_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Texto de ayuda debajo del botón.
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            estaEscuchando
                ? 'Detener dictado'
                : 'Presiona para dictar',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colores.texto,
            ),
          ),
        ),
      ],
    );
  }
}
