import 'package:flutter/material.dart';

/// Pide confirmar antes de llamar al contacto de emergencia, para evitar llamadas por
/// accidente. Muestra el [numero] registrado y devuelve true si la persona toca "Llamar" (false
/// o null si cancela).
Future<bool?> mostrarDialogoConfirmarLlamada(
  BuildContext context, {
  required String numero,
}) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),

      // Contenido: encabezado, pregunta y el número registrado.
      content: SingleChildScrollView(
        child: Column (
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado: ícono de teléfono, título y subtítulo.
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE0E3),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.phone_in_talk_rounded,
                    color: Color(0xFFB91C1C),
                    size: 26,
                  ),
                ),

                const SizedBox(width: 12),

                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Confirmar llamada',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF292524),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Contacto de emergencia',
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

            // Pregunta de confirmación.
            const Text(
              '¿Quieres llamar ahora alnúmero?',
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: Color(0xFF57534E),
              ),
            ),

            const SizedBox(height: 16),

            // Tarjeta roja con el número registrado, en grande para que se lea bien.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 18,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  const Text(
                    'Número registrado',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF9F1239),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    numero,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF991B1B),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        )
      ),

      // Botones: "Cancelar" devuelve false y "Llamar" devuelve true.
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(dialogContext, false);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF57534E),
                  backgroundColor: const Color(0xFFF5F5F4),
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Cancelar'),
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(dialogContext, true);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFB91C1C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(
                  Icons.phone_rounded,
                  size: 18,
                ),
                label: const Text('Llamar'),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
