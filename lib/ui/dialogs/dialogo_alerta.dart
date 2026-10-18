import 'package:flutter/material.dart';

import '../themes/colores_perfil.dart';

/// Aviso que sale en pantalla cuando llega la hora de un recordatorio.
/// [titulo] y [mensaje] son lo que se muestra; [colores] adapta los colores y el tamaño de
/// letra al perfil activo; [alEntendido] se ejecuta al tocar "Entendido" (la pantalla lo usa
/// para callar la voz).
Future<void> mostrarDialogoAlerta(
  BuildContext context, {
  required String titulo,
  required String mensaje,
  required ColoresPerfil colores,
  required VoidCallback alEntendido,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),

      // Contenido: encabezado y tarjeta con el texto del recordatorio.
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado: ícono de campana, título y subtítulo.
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colores.principal.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.notifications_active_rounded,
                    color: colores.principal,
                    size: 26,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colores.texto,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Es hora de tu recordatorio',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF78716C),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            // Tarjeta con el texto del recordatorio, en grande para que se lea bien.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 18,
              ),
              decoration: BoxDecoration(
                color: colores.principal.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Text(
                    'Tu recordatorio',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colores.principal,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    mensaje,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: colores.esAdultoMayor ? 20 : 17,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                      color: colores.texto,
                    ),
                  ),
                ],
              ),
            ),
          ],
        )
      ),

      // Botón para cerrar el aviso. Primero se avisa (para callar la voz) y luego se cierra.
      actions: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () {
              alEntendido();
              Navigator.pop(dialogContext);
            },
            style: FilledButton.styleFrom(
              backgroundColor: colores.principal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                vertical: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(
              Icons.check_circle_outline_rounded,
              size: 18,
            ),
            label: const Text('Entendido'),
          ),
        ),
      ],
    ),
  );
}
