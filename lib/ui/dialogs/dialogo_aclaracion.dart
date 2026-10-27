
import 'package:flutter/material.dart';

import '../themes/colores_perfil.dart';

/// Diálogo con opciones para aclarar lo que quiso decir la persona
/// (por ejemplo, "¿aviso, evento o ambas?" o "¿mañana o noche?").
///
/// [pregunta] es el texto de la pregunta y [opciones] son los botones
/// que se muestran. Devuelve la opción elegida, o null si cancela.
/// [colores] adapta los colores y tamaños al perfil activo.
Future<String?> mostrarDialogoAclaracion(
  BuildContext context, {
  required String pregunta,
  required List<String> opciones,
  required ColoresPerfil colores,
}) {
  // Identifica el tipo de pregunta para mostrar el título y el ícono.
  final esHorario =
      opciones.contains('Mañana') && opciones.contains('Noche');

  final esFecha =
      opciones.contains('Aviso') && opciones.contains('Evento');

  // Título del diálogo según el tipo de pregunta.
  final titulo = esHorario
      ? 'Aclarar horario'
      : esFecha
          ? 'Modificar recordatorio'
          : 'VoiceNotes necesita una aclaración';

  // Ícono grande del encabezado.
  final iconoPrincipal = esHorario
      ? Icons.access_time_rounded
      : esFecha
          ? Icons.event_note_rounded
          : Icons.help_outline_rounded;

  // Ícono de cada opción.
  IconData iconoOpcion(String opcion) {
    switch (opcion) {
      case 'Nombre':
        return Icons.edit_rounded;
      case 'Aviso':
        return Icons.notifications_active_outlined;
      case 'Evento':
        return Icons.calendar_month_rounded;
      case 'Ambas':
        return Icons.date_range_rounded;
      case 'Mañana':
        return Icons.wb_sunny_outlined;
      case 'Noche':
        return Icons.nightlight_round;
      default:
        return Icons.check_circle_outline_rounded;
    }
  }

  // Texto pequeño que explica cada opción.
  String descripcionOpcion(String opcion) {
    switch (opcion) {
      case 'Nombre':
        return 'Cambiar el nombre del recordatorio';
      case 'Aviso':
        return 'Cuándo recibirás la notificación';
      case 'Evento':
        return 'Cuándo ocurrirá la actividad';
      case 'Ambas':
        return 'Mover el evento y el aviso juntos';
      default:
        return '';
    }
  }

  // Texto que se muestra en cada botón.
  String tituloOpcion(String opcion) {
    if (!esFecha) return opcion;

    switch (opcion) {
      case 'Nombre':
        return 'Nombre del recordatorio';
      case 'Evento':
        return 'Fecha del evento';
      case 'Aviso':
        return 'Fecha del aviso';
      case 'Ambas':
        return 'Ambas fechas';
      default:
        return opcion;
    }
  }

  // Muestra el diálogo.
  // Al tocar una opción, se cierra y devuelve la opción seleccionada.
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),

      // Encabezado, pregunta y lista de opciones.
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Encabezado.
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colores.principal.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    iconoPrincipal,
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
                      Text(
                        'Selecciona una opción',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            // Pregunta principal.
            Text(
              pregunta,
              style: TextStyle(
                fontSize: colores.esAdultoMayor ? 16 : 14,
                fontWeight: FontWeight.w500,
                color: colores.texto,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 18),

            // Opciones disponibles.
            for (final opcion in opciones)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: colores.principal.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      Navigator.pop(dialogContext, opcion);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 15,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: colores.principal.withValues(
                            alpha: 0.15,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: colores.principal.withValues(
                                alpha: 0.10,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              iconoOpcion(opcion),
                              color: colores.principal,
                              size: 22,
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                // Nombre correcto de la opción.
                                Text(
                                  tituloOpcion(opcion),
                                  style: TextStyle(
                                    fontSize:
                                        colores.esAdultoMayor ? 15 : 14,
                                    fontWeight: FontWeight.w600,
                                    color: colores.texto,
                                  ),
                                ),

                                // Descripción, cuando corresponda.
                                if (descripcionOpcion(opcion)
                                    .isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    descripcionOpcion(opcion),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          Icon(
                            Icons.chevron_right_rounded,
                            color: colores.principal,
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),

      // Cancelar sin seleccionar ninguna opción.
      actions: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: colores.texto,
              backgroundColor: const Color(0xFFF5F5F7),
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
      ],
    ),
  );
}
