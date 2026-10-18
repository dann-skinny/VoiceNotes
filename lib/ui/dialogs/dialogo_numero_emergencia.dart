import 'package:flutter/material.dart';

/// Ventana para que la persona escriba su número de contacto de emergencia. [numeroActual]
/// aparece ya escrito en el campo. Devuelve el texto que escribió, o null si cancela.
Future<String?> mostrarDialogoNumeroEmergencia(
  BuildContext context, {
  required String numeroActual,
}) async {
  // Controla el texto del campo; empieza con el número que ya estaba guardado.
  final controlador = TextEditingController(
    text: numeroActual,
  );

  // Muestra el diálogo y espera a que se cierre.
  final numero = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),

      // Contenido: encabezado, aviso y campo para escribir el número.
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado: ícono, título y subtítulo.
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0E5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.contact_phone_rounded,
                    color: Color(0xFFC2410C),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Contacto de emergencia',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF292524),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Configura tu contacto de confianza',
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

            // Aviso: usar un número real autorizado y no números de servicios de emergencia.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFFC2410C),
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Utiliza un número real autorizado para '
                      'realizar llamadas de prueba. No ingreses '
                      'números de servicios de emergencia.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: Color(0xFF9A3412),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // Etiqueta del campo.
            const Text(
              'Número telefónico',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF292524),
              ),
            ),

            const SizedBox(height: 10),

            // Campo para escribir el número (muestra el teclado de teléfono).
            TextField(
              controller: controlador,
              keyboardType: TextInputType.phone,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF292524),
              ),
              decoration: InputDecoration(
                hintText: 'Ingresa tu número',
                hintStyle: const TextStyle(
                  color: Color(0xFFA8A29E),
                ),
                prefixIcon: const Icon(
                  Icons.phone_outlined,
                  color: Color(0xFFC2410C),
                ),
                filled: true,
                fillColor: const Color(0xFFFAFAF9),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 16,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: Color(0xFFE7E5E4),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: Color(0xFFC2410C),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // Botones: "Cancelar" cierra sin devolver nada y "Guardar" devuelve el número escrito.
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
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
                  Navigator.pop(
                    dialogContext,
                    controlador.text.trim(),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFC2410C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(
                  Icons.check_rounded,
                  size: 18,
                ),
                label: const Text('Guardar'),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  // Se espera a que termine la animación de cierre antes de liberar el controlador del campo,
  // para evitar errores si el campo todavía se está dibujando.
  await Future.delayed(const Duration(milliseconds: 250));
  controlador.dispose();

  return numero;
}
